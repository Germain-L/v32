package storage

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/gmn/v32-backend/internal/models"
	_ "github.com/mattn/go-sqlite3"
)

type Storage struct {
	db         *sql.DB
	uploadPath string
}

func New(dbPath, uploadPath string) (*Storage, error) {
	// Ensure upload directory exists
	if err := os.MkdirAll(uploadPath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create upload directory: %w", err)
	}

	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Create tables
	if err := createTables(db); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to create tables: %w", err)
	}

	return &Storage{db: db, uploadPath: uploadPath}, nil
}

func createTables(db *sql.DB) error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS meals(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			slot TEXT NOT NULL,
			date INTEGER NOT NULL,
			description TEXT,
			updated_at INTEGER NOT NULL DEFAULT 0,
			deleted_at INTEGER,
			server_id INTEGER UNIQUE
		)`,
		`CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date)`,
		`CREATE TABLE IF NOT EXISTS meal_images(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			meal_id INTEGER NOT NULL,
			filename TEXT NOT NULL,
			created_at INTEGER NOT NULL,
			FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE
		)`,
		`CREATE INDEX IF NOT EXISTS idx_meal_images_meal_id ON meal_images(meal_id)`,
		`CREATE TABLE IF NOT EXISTS day_ratings(
			date INTEGER PRIMARY KEY,
			score INTEGER NOT NULL
		)`,
	}

	for _, q := range queries {
		if _, err := db.Exec(q); err != nil {
			return err
		}
	}

	// Run migrations for existing tables
	if err := runMigrations(db); err != nil {
		return err
	}

	return nil
}

func runMigrations(db *sql.DB) error {
	// Check if updated_at column exists
	row := db.QueryRow(`SELECT COUNT(*) FROM pragma_table_info('meals') WHERE name='updated_at'`)
	var count int
	if err := row.Scan(&count); err == nil && count == 0 {
		// Column doesn't exist, add it
		if _, err := db.Exec(`ALTER TABLE meals ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0`); err != nil {
			return fmt.Errorf("failed to add updated_at column: %w", err)
		}
	}

	// Check if deleted_at column exists
	row = db.QueryRow(`SELECT COUNT(*) FROM pragma_table_info('meals') WHERE name='deleted_at'`)
	if err := row.Scan(&count); err == nil && count == 0 {
		if _, err := db.Exec(`ALTER TABLE meals ADD COLUMN deleted_at INTEGER`); err != nil {
			return fmt.Errorf("failed to add deleted_at column: %w", err)
		}
	}

	// Check if server_id column exists
	row = db.QueryRow(`SELECT COUNT(*) FROM pragma_table_info('meals') WHERE name='server_id'`)
	if err := row.Scan(&count); err == nil && count == 0 {
		// Add column without UNIQUE constraint (SQLite doesn't support adding UNIQUE columns)
		if _, err := db.Exec(`ALTER TABLE meals ADD COLUMN server_id INTEGER`); err != nil {
			return fmt.Errorf("failed to add server_id column: %w", err)
		}
		// Create unique index separately
		if _, err := db.Exec(`CREATE UNIQUE INDEX IF NOT EXISTS idx_meals_server_id ON meals(server_id) WHERE server_id IS NOT NULL`); err != nil {
			return fmt.Errorf("failed to create server_id index: %w", err)
		}
	}

	// Create indexes if they don't exist
	indexes := []string{
		`CREATE INDEX IF NOT EXISTS idx_meals_updated_at ON meals(updated_at)`,
		`CREATE INDEX IF NOT EXISTS idx_meals_deleted_at ON meals(deleted_at)`,
	}
	for _, idx := range indexes {
		if _, err := db.Exec(idx); err != nil {
			return fmt.Errorf("failed to create index: %w", err)
		}
	}

	// Create unique index for slot+date (upsert constraint)
	// This ensures only one active meal per slot per date
	// First, clean up any duplicates (keep the one with highest id)
	if _, err := db.Exec(`
		DELETE FROM meals 
		WHERE id NOT IN (
			SELECT MAX(id) FROM meals WHERE deleted_at IS NULL GROUP BY slot, date
		) AND deleted_at IS NULL
	`); err != nil {
		// Log but don't fail - might not have duplicates
		fmt.Printf("[WARN] Failed to clean duplicates: %v\n", err)
	}
	
	if _, err := db.Exec(`
		CREATE UNIQUE INDEX IF NOT EXISTS idx_meals_slot_date_active 
		ON meals(slot, date) 
		WHERE deleted_at IS NULL
	`); err != nil {
		return fmt.Errorf("failed to create slot_date index: %w", err)
	}

	return nil
}

func (s *Storage) Close() error {
	return s.db.Close()
}

// --- Meals ---

func (s *Storage) SaveMeal(m *models.Meal) error {
	now := time.Now().UnixMilli()

	var result sql.Result
	var err error

	// Use upsert: insert new or update existing meal for this slot+date
	if m.ServerID > 0 {
		result, err = s.db.Exec(`
			INSERT INTO meals (slot, date, description, updated_at, server_id) 
			VALUES (?, ?, ?, ?, ?)
			ON CONFLICT(slot, date) WHERE deleted_at IS NULL
			DO UPDATE SET description = excluded.description, updated_at = excluded.updated_at
		`, m.Slot, m.Date, m.Description, now, m.ServerID)
	} else {
		result, err = s.db.Exec(`
			INSERT INTO meals (slot, date, description, updated_at) 
			VALUES (?, ?, ?, ?)
			ON CONFLICT(slot, date) WHERE deleted_at IS NULL
			DO UPDATE SET description = excluded.description, updated_at = excluded.updated_at
		`, m.Slot, m.Date, m.Description, now)
	}
	if err != nil {
		return err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return err
	}
	m.ID = id
	m.UpdatedAt = now
	return nil
}

func (s *Storage) GetMealsByDate(dateStr string) ([]models.Meal, error) {
	// Parse date and get range
	// dateStr is YYYY-MM-DD

	rows, err := s.db.Query(`
		SELECT m.id, m.slot, m.date, m.description, m.updated_at, m.deleted_at, m.server_id
		FROM meals m
		WHERE date(m.date / 1000, 'unixepoch') = ?
		AND m.deleted_at IS NULL
		ORDER BY m.date ASC
	`, dateStr)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var meals []models.Meal
	for rows.Next() {
		var m models.Meal
		var deletedAt sql.NullInt64
		var serverID sql.NullInt64
		if err := rows.Scan(&m.ID, &m.Slot, &m.Date, &m.Description, &m.UpdatedAt, &deletedAt, &serverID); err != nil {
			return nil, err
		}
		if deletedAt.Valid {
			m.DeletedAt = &deletedAt.Int64
		}
		if serverID.Valid {
			m.ServerID = serverID.Int64
		}
		// Load images for this meal
		m.Images, _ = s.GetImagesByMeal(m.ID)
		meals = append(meals, m)
	}

	if meals == nil {
		meals = []models.Meal{}
	}
	return meals, nil
}

func (s *Storage) GetRecentMeals(days int) ([]models.Meal, error) {
	rows, err := s.db.Query(`
		SELECT m.id, m.slot, m.date, m.description, m.updated_at, m.deleted_at, m.server_id
		FROM meals m
		WHERE m.date >= strftime('%s', 'now', ? || ' days') * 1000
		AND m.deleted_at IS NULL
		ORDER BY m.date DESC
	`, fmt.Sprintf("-%d", days))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var meals []models.Meal
	for rows.Next() {
		var m models.Meal
		var deletedAt sql.NullInt64
		var serverID sql.NullInt64
		if err := rows.Scan(&m.ID, &m.Slot, &m.Date, &m.Description, &m.UpdatedAt, &deletedAt, &serverID); err != nil {
			return nil, err
		}
		if deletedAt.Valid {
			m.DeletedAt = &deletedAt.Int64
		}
		if serverID.Valid {
			m.ServerID = serverID.Int64
		}
		m.Images, _ = s.GetImagesByMeal(m.ID)
		meals = append(meals, m)
	}

	if meals == nil {
		meals = []models.Meal{}
	}
	return meals, nil
}

// --- Sync Operations ---

func (s *Storage) GetMealByID(id int64) (*models.Meal, error) {
	var m models.Meal
	var deletedAt sql.NullInt64
	var serverID sql.NullInt64
	err := s.db.QueryRow(`
		SELECT id, slot, date, description, updated_at, deleted_at, server_id
		FROM meals
		WHERE id = ? AND deleted_at IS NULL
	`, id).Scan(&m.ID, &m.Slot, &m.Date, &m.Description, &m.UpdatedAt, &deletedAt, &serverID)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if deletedAt.Valid {
		m.DeletedAt = &deletedAt.Int64
	}
	if serverID.Valid {
		m.ServerID = serverID.Int64
	}
	m.Images, _ = s.GetImagesByMeal(m.ID)
	return &m, nil
}

func (s *Storage) UpdateMeal(m *models.Meal) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE meals
		SET slot = ?, date = ?, description = ?, updated_at = ?
		WHERE id = ? AND deleted_at IS NULL
	`, m.Slot, m.Date, m.Description, now, m.ID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected == 0 {
		return sql.ErrNoRows
	}

	m.UpdatedAt = now
	return nil
}

func (s *Storage) SoftDeleteMeal(id int64) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE meals SET deleted_at = ?, updated_at = ? WHERE id = ? AND deleted_at IS NULL
	`, now, now, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected == 0 {
		return sql.ErrNoRows
	}

	return nil
}

func (s *Storage) GetMealsSince(timestamp int64) ([]models.Meal, []int64, error) {
	// Get all meals updated after timestamp (including deleted)
	rows, err := s.db.Query(`
		SELECT id, slot, date, description, updated_at, deleted_at, server_id
		FROM meals
		WHERE updated_at > ?
		ORDER BY updated_at ASC
	`, timestamp)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var meals []models.Meal
	var deletedIDs []int64

	for rows.Next() {
		var m models.Meal
		var deletedAt sql.NullInt64
		var serverID sql.NullInt64
		if err := rows.Scan(&m.ID, &m.Slot, &m.Date, &m.Description, &m.UpdatedAt, &deletedAt, &serverID); err != nil {
			return nil, nil, err
		}
		if deletedAt.Valid {
			m.DeletedAt = &deletedAt.Int64
			deletedIDs = append(deletedIDs, m.ID)
		}
		if serverID.Valid {
			m.ServerID = serverID.Int64
		}
		// Only load images for non-deleted meals
		if m.DeletedAt == nil {
			m.Images, _ = s.GetImagesByMeal(m.ID)
		}
		meals = append(meals, m)
	}

	if meals == nil {
		meals = []models.Meal{}
	}
	if deletedIDs == nil {
		deletedIDs = []int64{}
	}

	return meals, deletedIDs, nil
}

func (s *Storage) BulkSaveMeals(meals []models.Meal) ([]models.Meal, error) {
	tx, err := s.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	now := time.Now().UnixMilli()
	results := make([]models.Meal, 0, len(meals))

	for _, m := range meals {
		// Check if meal exists (by server_id if provided, or by ID)
		var existingID int64
		if m.ServerID > 0 {
			err := tx.QueryRow(`SELECT id FROM meals WHERE server_id = ?`, m.ServerID).Scan(&existingID)
			if err != nil && err != sql.ErrNoRows {
				return nil, err
			}
		}

		if existingID > 0 {
			// Update existing meal
			_, err := tx.Exec(`
				UPDATE meals
				SET slot = ?, date = ?, description = ?, updated_at = ?, deleted_at = NULL
				WHERE id = ?
			`, m.Slot, m.Date, m.Description, now, existingID)
			if err != nil {
				return nil, err
			}
			m.ID = existingID
			m.UpdatedAt = now
		} else {
			// Insert new meal
			var result sql.Result
			if m.ServerID > 0 {
				result, err = tx.Exec(`
					INSERT INTO meals (slot, date, description, updated_at, server_id)
					VALUES (?, ?, ?, ?, ?)
				`, m.Slot, m.Date, m.Description, now, m.ServerID)
			} else {
				result, err = tx.Exec(`
					INSERT INTO meals (slot, date, description, updated_at)
					VALUES (?, ?, ?, ?)
				`, m.Slot, m.Date, m.Description, now)
			}
			if err != nil {
				return nil, err
			}
			id, err := result.LastInsertId()
			if err != nil {
				return nil, err
			}
			m.ID = id
			m.UpdatedAt = now
		}

		results = append(results, m)
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return results, nil
}

// --- Images ---

func (s *Storage) SaveImage(mealID int64, filename string) error {
	_, err := s.db.Exec(
		"INSERT INTO meal_images (meal_id, filename, created_at) VALUES (?, ?, strftime('%s', 'now') * 1000)",
		mealID, filename,
	)
	return err
}

func (s *Storage) GetImagesByMeal(mealID int64) ([]models.MealImage, error) {
	rows, err := s.db.Query(
		"SELECT id, meal_id, filename FROM meal_images WHERE meal_id = ? ORDER BY created_at ASC",
		mealID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var images []models.MealImage
	for rows.Next() {
		var img models.MealImage
		if err := rows.Scan(&img.ID, &img.MealID, &img.Filename); err != nil {
			return nil, err
		}
		img.URL = fmt.Sprintf("/images/%d/%s", img.MealID, img.Filename)
		images = append(images, img)
	}

	if images == nil {
		images = []models.MealImage{}
	}
	return images, nil
}

func (s *Storage) GetImagePath(mealID int64, filename string) string {
	return filepath.Join(s.uploadPath, fmt.Sprintf("%d", mealID), filename)
}

func (s *Storage) SaveImageFile(mealID int64, filename string, data []byte) error {
	dir := filepath.Join(s.uploadPath, fmt.Sprintf("%d", mealID))
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(dir, filename), data, 0644)
}

// --- Day Ratings ---

func (s *Storage) SaveDayRating(r *models.DayRating) error {
	_, err := s.db.Exec(
		"INSERT OR REPLACE INTO day_ratings (date, score) VALUES (?, ?)",
		r.Date, r.Score,
	)
	return err
}

func (s *Storage) GetDayRating(date int64) (*models.DayRating, error) {
	var r models.DayRating
	err := s.db.QueryRow("SELECT date, score FROM day_ratings WHERE date = ?", date).Scan(&r.Date, &r.Score)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &r, nil
}

// --- Stats ---

func (s *Storage) GetStats() (*models.Stats, error) {
	stats := &models.Stats{
		MealsBySlot: make(map[string]int),
	}

	// Total meals
	if err := s.db.QueryRow("SELECT COUNT(*) FROM meals").Scan(&stats.TotalMeals); err != nil {
		return nil, err
	}

	// Meals by slot
	rows, err := s.db.Query("SELECT slot, COUNT(*) FROM meals GROUP BY slot")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var slot string
		var count int
		if err := rows.Scan(&slot, &count); err != nil {
			return nil, err
		}
		stats.MealsBySlot[slot] = count
	}

	// Days logged
	if err := s.db.QueryRow("SELECT COUNT(DISTINCT date(date / 1000, 'unixepoch')) FROM meals").Scan(&stats.DaysLogged); err != nil {
		return nil, err
	}

	// Average rating
	var avgRating sql.NullFloat64
	if err := s.db.QueryRow("SELECT AVG(score) FROM day_ratings").Scan(&avgRating); err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	if avgRating.Valid {
		stats.AvgRating = avgRating.Float64
	}

	// Current streak (consecutive days with meals)
	// This is a simplified calculation
	var streak int
	err = s.db.QueryRow(`
		WITH dates AS (
			SELECT DISTINCT date(date / 1000, 'unixepoch') as d FROM meals
		)
		SELECT COUNT(*) FROM dates d
		WHERE d.d >= date('now', '-' || (
			SELECT COUNT(*) FROM dates d2 
			WHERE d2.d <= date('now') 
			AND NOT EXISTS (SELECT 1 FROM dates d3 WHERE d3.d = date(d2.d, '+1 day'))
		) || ' days')
	`).Scan(&streak)
	if err == nil {
		stats.CurrentStreak = streak
	}

	return stats, nil
}
