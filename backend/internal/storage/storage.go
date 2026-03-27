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
			score INTEGER NOT NULL,
			updated_at INTEGER NOT NULL DEFAULT 0,
			deleted_at INTEGER
		)`,
		`CREATE INDEX IF NOT EXISTS idx_day_ratings_updated_at ON day_ratings(updated_at)`,
		`CREATE TABLE IF NOT EXISTS daily_metrics(
			date INTEGER PRIMARY KEY,
			water_liters REAL,
			exercise_done INTEGER,
			exercise_note TEXT,
			updated_at INTEGER NOT NULL,
			deleted_at INTEGER
		)`,
		`CREATE INDEX IF NOT EXISTS idx_daily_metrics_updated_at ON daily_metrics(updated_at)`,
		`CREATE TABLE IF NOT EXISTS body_metrics(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			date INTEGER NOT NULL,
			weight REAL,
			body_fat REAL,
			notes TEXT,
			created_at INTEGER NOT NULL,
			updated_at INTEGER NOT NULL DEFAULT 0,
			deleted_at INTEGER
		)`,
		`CREATE INDEX IF NOT EXISTS idx_body_metrics_date ON body_metrics(date)`,
		`CREATE TABLE IF NOT EXISTS screen_time(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			date INTEGER NOT NULL,
			total_ms INTEGER NOT NULL,
			pickups INTEGER,
			created_at INTEGER NOT NULL,
			updated_at INTEGER NOT NULL DEFAULT 0,
			deleted_at INTEGER
		)`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_screen_time_date ON screen_time(date)`,
		`CREATE TABLE IF NOT EXISTS screen_time_apps(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			screen_time_id INTEGER NOT NULL,
			package_name TEXT NOT NULL,
			app_name TEXT NOT NULL,
			duration_ms INTEGER NOT NULL,
			FOREIGN KEY (screen_time_id) REFERENCES screen_time(id) ON DELETE CASCADE
		)`,
		`CREATE INDEX IF NOT EXISTS idx_screen_time_apps_session ON screen_time_apps(screen_time_id)`,
		`CREATE TABLE IF NOT EXISTS workouts(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			type TEXT NOT NULL,
			date INTEGER NOT NULL,
			duration_seconds INTEGER,
			distance_meters REAL,
			calories INTEGER,
			heart_rate_avg INTEGER,
			heart_rate_max INTEGER,
			notes TEXT,
			source TEXT NOT NULL DEFAULT 'manual',
			source_id TEXT,
			strava_data TEXT,
			created_at INTEGER NOT NULL,
			updated_at INTEGER NOT NULL DEFAULT 0,
			deleted_at INTEGER
		)`,
		`CREATE INDEX IF NOT EXISTS idx_workouts_date ON workouts(date)`,
		`CREATE INDEX IF NOT EXISTS idx_workouts_source_id ON workouts(source_id)`,
		`CREATE TABLE IF NOT EXISTS strava_tokens(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			access_token TEXT NOT NULL,
			refresh_token TEXT NOT NULL,
			expires_at INTEGER NOT NULL,
			athlete_id INTEGER,
			updated_at INTEGER NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS hydration(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			date INTEGER NOT NULL,
			amount_ml INTEGER NOT NULL,
			created_at INTEGER NOT NULL,
			updated_at INTEGER NOT NULL DEFAULT 0,
			deleted_at INTEGER
		)`,
		`CREATE INDEX IF NOT EXISTS idx_hydration_date ON hydration(date)`,
		`CREATE INDEX IF NOT EXISTS idx_hydration_updated_at ON hydration(updated_at)`,
		`CREATE TABLE IF NOT EXISTS daily_checkins(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			date INTEGER NOT NULL,
			mood INTEGER CHECK(mood BETWEEN 1 AND 5),
			energy INTEGER CHECK(energy BETWEEN 1 AND 5),
			focus INTEGER CHECK(focus BETWEEN 1 AND 5),
			stress INTEGER CHECK(stress BETWEEN 1 AND 5),
			sleep_hours REAL,
			sleep_quality INTEGER CHECK(sleep_quality BETWEEN 1 AND 5),
			notes TEXT,
			created_at INTEGER NOT NULL,
			updated_at INTEGER NOT NULL,
			deleted_at INTEGER
		)`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_checkins_date ON daily_checkins(date)`,
		`CREATE INDEX IF NOT EXISTS idx_daily_checkins_updated_at ON daily_checkins(updated_at)`,
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
	if err := ensureColumn(db, "meals", "updated_at", "INTEGER NOT NULL DEFAULT 0"); err != nil {
		return fmt.Errorf("failed to add meals.updated_at column: %w", err)
	}
	if err := ensureColumn(db, "meals", "deleted_at", "INTEGER"); err != nil {
		return fmt.Errorf("failed to add meals.deleted_at column: %w", err)
	}
	if err := ensureColumn(db, "meals", "server_id", "INTEGER"); err != nil {
		return fmt.Errorf("failed to add meals.server_id column: %w", err)
	}
	if _, err := db.Exec(`CREATE UNIQUE INDEX IF NOT EXISTS idx_meals_server_id ON meals(server_id) WHERE server_id IS NOT NULL`); err != nil {
		return fmt.Errorf("failed to create server_id index: %w", err)
	}

	if err := ensureColumn(db, "day_ratings", "updated_at", "INTEGER NOT NULL DEFAULT 0"); err != nil {
		return fmt.Errorf("failed to add day_ratings.updated_at column: %w", err)
	}
	if err := ensureColumn(db, "day_ratings", "deleted_at", "INTEGER"); err != nil {
		return fmt.Errorf("failed to add day_ratings.deleted_at column: %w", err)
	}
	if err := ensureColumn(db, "daily_checkins", "deleted_at", "INTEGER"); err != nil {
		return fmt.Errorf("failed to add daily_checkins.deleted_at column: %w", err)
	}
	if err := ensureColumn(db, "screen_time", "updated_at", "INTEGER NOT NULL DEFAULT 0"); err != nil {
		return fmt.Errorf("failed to add screen_time.updated_at column: %w", err)
	}
	if err := ensureColumn(db, "screen_time", "deleted_at", "INTEGER"); err != nil {
		return fmt.Errorf("failed to add screen_time.deleted_at column: %w", err)
	}
	if err := ensureColumn(db, "hydration", "updated_at", "INTEGER NOT NULL DEFAULT 0"); err != nil {
		return fmt.Errorf("failed to add hydration.updated_at column: %w", err)
	}
	if err := ensureColumn(db, "hydration", "deleted_at", "INTEGER"); err != nil {
		return fmt.Errorf("failed to add hydration.deleted_at column: %w", err)
	}

	// Create indexes if they don't exist
	indexes := []string{
		`CREATE INDEX IF NOT EXISTS idx_meals_updated_at ON meals(updated_at)`,
		`CREATE INDEX IF NOT EXISTS idx_meals_deleted_at ON meals(deleted_at)`,
		`CREATE INDEX IF NOT EXISTS idx_day_ratings_updated_at ON day_ratings(updated_at)`,
		`CREATE INDEX IF NOT EXISTS idx_day_ratings_deleted_at ON day_ratings(deleted_at)`,
		`CREATE INDEX IF NOT EXISTS idx_daily_checkins_updated_at ON daily_checkins(updated_at)`,
		`CREATE INDEX IF NOT EXISTS idx_daily_checkins_deleted_at ON daily_checkins(deleted_at)`,
		`CREATE INDEX IF NOT EXISTS idx_daily_metrics_deleted_at ON daily_metrics(deleted_at)`,
		`CREATE INDEX IF NOT EXISTS idx_screen_time_updated_at ON screen_time(updated_at)`,
		`CREATE INDEX IF NOT EXISTS idx_screen_time_deleted_at ON screen_time(deleted_at)`,
		`CREATE INDEX IF NOT EXISTS idx_hydration_updated_at ON hydration(updated_at)`,
		`CREATE INDEX IF NOT EXISTS idx_hydration_deleted_at ON hydration(deleted_at)`,
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

	if _, err := db.Exec(`
		DELETE FROM body_metrics
		WHERE id NOT IN (
			SELECT MAX(id) FROM body_metrics WHERE deleted_at IS NULL GROUP BY date
		) AND deleted_at IS NULL
	`); err != nil {
		fmt.Printf("[WARN] Failed to clean body metric duplicates: %v\n", err)
	}

	if _, err := db.Exec(`
		CREATE UNIQUE INDEX IF NOT EXISTS idx_body_metrics_date_active
		ON body_metrics(date)
		WHERE deleted_at IS NULL
	`); err != nil {
		return fmt.Errorf("failed to create body_metrics date index: %w", err)
	}

	if _, err := db.Exec(`
		DELETE FROM workouts
		WHERE id NOT IN (
			SELECT MAX(id) FROM workouts WHERE source_id IS NOT NULL GROUP BY source_id
		) AND source_id IS NOT NULL
	`); err != nil {
		fmt.Printf("[WARN] Failed to clean workout duplicates: %v\n", err)
	}

	if _, err := db.Exec(`
		CREATE UNIQUE INDEX IF NOT EXISTS idx_workouts_source_id_unique
		ON workouts(source_id)
		WHERE source_id IS NOT NULL
	`); err != nil {
		return fmt.Errorf("failed to create workouts source_id index: %w", err)
	}

	return nil
}

func ensureColumn(db *sql.DB, table, column, definition string) error {
	row := db.QueryRow(
		fmt.Sprintf(`SELECT COUNT(*) FROM pragma_table_info('%s') WHERE name=?`, table),
		column,
	)

	var count int
	if err := row.Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	_, err := db.Exec(
		fmt.Sprintf(`ALTER TABLE %s ADD COLUMN %s %s`, table, column, definition),
	)
	return err
}

func (s *Storage) Close() error {
	return s.db.Close()
}

func (s *Storage) SaveStravaTokens(accessToken, refreshToken string, expiresAt int64, athleteID int64) error {
	now := time.Now().UnixMilli()

	_, err := s.db.Exec(`
		INSERT INTO strava_tokens (id, access_token, refresh_token, expires_at, athlete_id, updated_at)
		VALUES (1, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			access_token = excluded.access_token,
			refresh_token = excluded.refresh_token,
			expires_at = excluded.expires_at,
			athlete_id = excluded.athlete_id,
			updated_at = excluded.updated_at
	`, accessToken, refreshToken, expiresAt, athleteID, now)
	return err
}

func (s *Storage) GetStravaTokens() (string, string, int64, int64, error) {
	var accessToken string
	var refreshToken string
	var expiresAt int64
	var athleteID sql.NullInt64

	err := s.db.QueryRow(`
		SELECT access_token, refresh_token, expires_at, athlete_id
		FROM strava_tokens
		WHERE id = 1
	`).Scan(&accessToken, &refreshToken, &expiresAt, &athleteID)
	if err != nil {
		return "", "", 0, 0, err
	}

	var athleteValue int64
	if athleteID.Valid {
		athleteValue = athleteID.Int64
	}

	return accessToken, refreshToken, expiresAt, athleteValue, nil
}

func (s *Storage) DeleteStravaTokens() error {
	_, err := s.db.Exec(`DELETE FROM strava_tokens`)
	return err
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
		s.applyMealCompatibilityFields(&m)
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
		s.applyMealCompatibilityFields(&m)
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
	s.applyMealCompatibilityFields(&m)
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
			s.applyMealCompatibilityFields(&m)
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

// --- Body Metrics ---

func (s *Storage) SaveBodyMetric(m *models.BodyMetric) error {
	now := time.Now().UnixMilli()

	result, err := s.db.Exec(`
		INSERT INTO body_metrics (date, weight, body_fat, notes, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?)
		ON CONFLICT(date) WHERE deleted_at IS NULL
		DO UPDATE SET weight = excluded.weight, body_fat = excluded.body_fat, notes = excluded.notes, updated_at = excluded.updated_at
	`, m.Date, m.Weight, m.BodyFat, m.Notes, now, now)
	if err != nil {
		return err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return err
	}
	m.ID = id
	m.CreatedAt = now
	m.UpdatedAt = now
	return nil
}

func (s *Storage) GetBodyMetricByDate(dateStr string) ([]models.BodyMetric, error) {
	rows, err := s.db.Query(`
		SELECT id, date, weight, body_fat, notes, created_at, updated_at, deleted_at
		FROM body_metrics
		WHERE date(date / 1000, 'unixepoch') = ?
		AND deleted_at IS NULL
		ORDER BY date ASC
	`, dateStr)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var metrics []models.BodyMetric
	for rows.Next() {
		var m models.BodyMetric
		var weight sql.NullFloat64
		var bodyFat sql.NullFloat64
		var notes sql.NullString
		var deletedAt sql.NullInt64
		if err := rows.Scan(&m.ID, &m.Date, &weight, &bodyFat, &notes, &m.CreatedAt, &m.UpdatedAt, &deletedAt); err != nil {
			return nil, err
		}
		if weight.Valid {
			m.Weight = &weight.Float64
		}
		if bodyFat.Valid {
			m.BodyFat = &bodyFat.Float64
		}
		if notes.Valid {
			m.Notes = &notes.String
		}
		if deletedAt.Valid {
			m.DeletedAt = &deletedAt.Int64
		}
		metrics = append(metrics, m)
	}

	if metrics == nil {
		metrics = []models.BodyMetric{}
	}
	return metrics, nil
}

func (s *Storage) GetRecentBodyMetrics(days int) ([]models.BodyMetric, error) {
	rows, err := s.db.Query(`
		SELECT id, date, weight, body_fat, notes, created_at, updated_at, deleted_at
		FROM body_metrics
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
		ORDER BY date DESC
	`, fmt.Sprintf("-%d", days))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var metrics []models.BodyMetric
	for rows.Next() {
		var m models.BodyMetric
		var weight sql.NullFloat64
		var bodyFat sql.NullFloat64
		var notes sql.NullString
		var deletedAt sql.NullInt64
		if err := rows.Scan(&m.ID, &m.Date, &weight, &bodyFat, &notes, &m.CreatedAt, &m.UpdatedAt, &deletedAt); err != nil {
			return nil, err
		}
		if weight.Valid {
			m.Weight = &weight.Float64
		}
		if bodyFat.Valid {
			m.BodyFat = &bodyFat.Float64
		}
		if notes.Valid {
			m.Notes = &notes.String
		}
		if deletedAt.Valid {
			m.DeletedAt = &deletedAt.Int64
		}
		metrics = append(metrics, m)
	}

	if metrics == nil {
		metrics = []models.BodyMetric{}
	}
	return metrics, nil
}

func (s *Storage) GetBodyMetricByID(id int64) (*models.BodyMetric, error) {
	var m models.BodyMetric
	var weight sql.NullFloat64
	var bodyFat sql.NullFloat64
	var notes sql.NullString
	var deletedAt sql.NullInt64

	err := s.db.QueryRow(`
		SELECT id, date, weight, body_fat, notes, created_at, updated_at, deleted_at
		FROM body_metrics
		WHERE id = ? AND deleted_at IS NULL
	`, id).Scan(&m.ID, &m.Date, &weight, &bodyFat, &notes, &m.CreatedAt, &m.UpdatedAt, &deletedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	if weight.Valid {
		m.Weight = &weight.Float64
	}
	if bodyFat.Valid {
		m.BodyFat = &bodyFat.Float64
	}
	if notes.Valid {
		m.Notes = &notes.String
	}
	if deletedAt.Valid {
		m.DeletedAt = &deletedAt.Int64
	}

	return &m, nil
}

// --- Daily Checkins ---

func (s *Storage) SaveCheckin(c *models.DailyCheckin) error {
	now := time.Now().UnixMilli()

	var existingCreatedAt int64
	err := s.db.QueryRow(`
		SELECT created_at
		FROM daily_checkins
		WHERE date = ?
	`, c.Date).Scan(&existingCreatedAt)
	if err != nil && err != sql.ErrNoRows {
		return err
	}

	createdAt := now
	if err == nil {
		createdAt = existingCreatedAt
	}

	result, err := s.db.Exec(`
		INSERT OR REPLACE INTO daily_checkins (
			id, date, mood, energy, focus, stress, sleep_hours, sleep_quality, notes, created_at, updated_at, deleted_at
		)
		VALUES (
			(SELECT id FROM daily_checkins WHERE date = ?),
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL
		)
	`, c.Date, c.Date, c.Mood, c.Energy, c.Focus, c.Stress, c.SleepHours, c.SleepQuality, c.Notes, createdAt, now)
	if err != nil {
		return err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return err
	}

	c.ID = id
	c.CreatedAt = createdAt
	c.UpdatedAt = now
	c.DeletedAt = nil
	return nil
}

func (s *Storage) GetCheckinByDate(dateStr string) (*models.DailyCheckin, error) {
	var c models.DailyCheckin
	var mood sql.NullInt64
	var energy sql.NullInt64
	var focus sql.NullInt64
	var stress sql.NullInt64
	var sleepHours sql.NullFloat64
	var sleepQuality sql.NullInt64
	var notes sql.NullString
	var deletedAt sql.NullInt64

	err := s.db.QueryRow(`
		SELECT id, date, mood, energy, focus, stress, sleep_hours, sleep_quality, notes, created_at, updated_at, deleted_at
		FROM daily_checkins
		WHERE date(date / 1000, 'unixepoch') = ?
		AND deleted_at IS NULL
	`, dateStr).Scan(
		&c.ID,
		&c.Date,
		&mood,
		&energy,
		&focus,
		&stress,
		&sleepHours,
		&sleepQuality,
		&notes,
		&c.CreatedAt,
		&c.UpdatedAt,
		&deletedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	if mood.Valid {
		value := int(mood.Int64)
		c.Mood = &value
	}
	if energy.Valid {
		value := int(energy.Int64)
		c.Energy = &value
	}
	if focus.Valid {
		value := int(focus.Int64)
		c.Focus = &value
	}
	if stress.Valid {
		value := int(stress.Int64)
		c.Stress = &value
	}
	if sleepHours.Valid {
		c.SleepHours = &sleepHours.Float64
	}
	if sleepQuality.Valid {
		value := int(sleepQuality.Int64)
		c.SleepQuality = &value
	}
	if notes.Valid {
		c.Notes = &notes.String
	}
	if deletedAt.Valid {
		c.DeletedAt = &deletedAt.Int64
	}

	return &c, nil
}

func (s *Storage) GetRecentCheckins(days int) ([]models.DailyCheckin, error) {
	rows, err := s.db.Query(`
		SELECT id, date, mood, energy, focus, stress, sleep_hours, sleep_quality, notes, created_at, updated_at, deleted_at
		FROM daily_checkins
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
		ORDER BY date DESC
	`, fmt.Sprintf("-%d", days))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var checkins []models.DailyCheckin
	for rows.Next() {
		var c models.DailyCheckin
		var mood sql.NullInt64
		var energy sql.NullInt64
		var focus sql.NullInt64
		var stress sql.NullInt64
		var sleepHours sql.NullFloat64
		var sleepQuality sql.NullInt64
		var notes sql.NullString
		var deletedAt sql.NullInt64
		if err := rows.Scan(
			&c.ID,
			&c.Date,
			&mood,
			&energy,
			&focus,
			&stress,
			&sleepHours,
			&sleepQuality,
			&notes,
			&c.CreatedAt,
			&c.UpdatedAt,
			&deletedAt,
		); err != nil {
			return nil, err
		}
		if mood.Valid {
			value := int(mood.Int64)
			c.Mood = &value
		}
		if energy.Valid {
			value := int(energy.Int64)
			c.Energy = &value
		}
		if focus.Valid {
			value := int(focus.Int64)
			c.Focus = &value
		}
		if stress.Valid {
			value := int(stress.Int64)
			c.Stress = &value
		}
		if sleepHours.Valid {
			c.SleepHours = &sleepHours.Float64
		}
		if sleepQuality.Valid {
			value := int(sleepQuality.Int64)
			c.SleepQuality = &value
		}
		if notes.Valid {
			c.Notes = &notes.String
		}
		if deletedAt.Valid {
			c.DeletedAt = &deletedAt.Int64
		}
		checkins = append(checkins, c)
	}

	if checkins == nil {
		checkins = []models.DailyCheckin{}
	}
	return checkins, nil
}

func (s *Storage) DeleteCheckin(date int64) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE daily_checkins
		SET deleted_at = ?, updated_at = ?
		WHERE date = ? AND deleted_at IS NULL
	`, now, now, date)
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

func (s *Storage) GetCheckinsSince(timestamp int64) ([]models.DailyCheckin, []int64, error) {
	rows, err := s.db.Query(`
		SELECT id, date, mood, energy, focus, stress, sleep_hours, sleep_quality, notes, created_at, updated_at, deleted_at
		FROM daily_checkins
		WHERE updated_at > ?
		ORDER BY updated_at ASC
	`, timestamp)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var checkins []models.DailyCheckin
	var deletedDates []int64

	for rows.Next() {
		var c models.DailyCheckin
		var mood sql.NullInt64
		var energy sql.NullInt64
		var focus sql.NullInt64
		var stress sql.NullInt64
		var sleepHours sql.NullFloat64
		var sleepQuality sql.NullInt64
		var notes sql.NullString
		var deletedAt sql.NullInt64
		if err := rows.Scan(
			&c.ID,
			&c.Date,
			&mood,
			&energy,
			&focus,
			&stress,
			&sleepHours,
			&sleepQuality,
			&notes,
			&c.CreatedAt,
			&c.UpdatedAt,
			&deletedAt,
		); err != nil {
			return nil, nil, err
		}
		if mood.Valid {
			value := int(mood.Int64)
			c.Mood = &value
		}
		if energy.Valid {
			value := int(energy.Int64)
			c.Energy = &value
		}
		if focus.Valid {
			value := int(focus.Int64)
			c.Focus = &value
		}
		if stress.Valid {
			value := int(stress.Int64)
			c.Stress = &value
		}
		if sleepHours.Valid {
			c.SleepHours = &sleepHours.Float64
		}
		if sleepQuality.Valid {
			value := int(sleepQuality.Int64)
			c.SleepQuality = &value
		}
		if notes.Valid {
			c.Notes = &notes.String
		}
		if deletedAt.Valid {
			c.DeletedAt = &deletedAt.Int64
			deletedDates = append(deletedDates, c.Date)
		}
		checkins = append(checkins, c)
	}

	if checkins == nil {
		checkins = []models.DailyCheckin{}
	}
	if deletedDates == nil {
		deletedDates = []int64{}
	}

	return checkins, deletedDates, nil
}

func (s *Storage) GetCheckinStats(days int) (float64, float64, float64, float64, float64, int, error) {
	var avgMood sql.NullFloat64
	var avgEnergy sql.NullFloat64
	var avgFocus sql.NullFloat64
	var avgStress sql.NullFloat64
	var avgSleep sql.NullFloat64
	var count int

	err := s.db.QueryRow(`
		SELECT
			AVG(mood),
			AVG(energy),
			AVG(focus),
			AVG(stress),
			AVG(sleep_hours),
			COUNT(*)
		FROM daily_checkins
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
	`, fmt.Sprintf("-%d", days)).Scan(&avgMood, &avgEnergy, &avgFocus, &avgStress, &avgSleep, &count)
	if err != nil {
		return 0, 0, 0, 0, 0, 0, err
	}

	var mood float64
	var energy float64
	var focus float64
	var stress float64
	var sleep float64
	if avgMood.Valid {
		mood = avgMood.Float64
	}
	if avgEnergy.Valid {
		energy = avgEnergy.Float64
	}
	if avgFocus.Valid {
		focus = avgFocus.Float64
	}
	if avgStress.Valid {
		stress = avgStress.Float64
	}
	if avgSleep.Valid {
		sleep = avgSleep.Float64
	}

	return mood, energy, focus, stress, sleep, count, nil
}

// --- Daily Metrics ---

func (s *Storage) SaveDailyMetrics(m *models.DailyMetrics) error {
	now := time.Now().UnixMilli()
	_, err := s.db.Exec(`
		INSERT INTO daily_metrics (date, water_liters, exercise_done, exercise_note, updated_at, deleted_at)
		VALUES (?, ?, ?, ?, ?, NULL)
		ON CONFLICT(date)
		DO UPDATE SET
			water_liters = excluded.water_liters,
			exercise_done = excluded.exercise_done,
			exercise_note = excluded.exercise_note,
			updated_at = excluded.updated_at,
			deleted_at = NULL
	`, m.Date, m.WaterLiters, nullableBoolToInt(m.ExerciseDone), m.ExerciseNote, now)
	if err != nil {
		return err
	}

	m.UpdatedAt = now
	m.DeletedAt = nil
	return nil
}

func (s *Storage) GetDailyMetricsByDate(dateStr string) (*models.DailyMetrics, error) {
	var m models.DailyMetrics
	var waterLiters sql.NullFloat64
	var exerciseDone sql.NullInt64
	var exerciseNote sql.NullString
	var deletedAt sql.NullInt64

	err := s.db.QueryRow(`
		SELECT date, water_liters, exercise_done, exercise_note, updated_at, deleted_at
		FROM daily_metrics
		WHERE date(date / 1000, 'unixepoch') = ?
		AND deleted_at IS NULL
	`, dateStr).Scan(&m.Date, &waterLiters, &exerciseDone, &exerciseNote, &m.UpdatedAt, &deletedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	if waterLiters.Valid {
		m.WaterLiters = &waterLiters.Float64
	}
	if exerciseDone.Valid {
		value := exerciseDone.Int64 == 1
		m.ExerciseDone = &value
	}
	if exerciseNote.Valid {
		m.ExerciseNote = &exerciseNote.String
	}
	if deletedAt.Valid {
		m.DeletedAt = &deletedAt.Int64
	}

	return &m, nil
}

func (s *Storage) DeleteDailyMetrics(date int64) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE daily_metrics
		SET deleted_at = ?, updated_at = ?
		WHERE date = ? AND deleted_at IS NULL
	`, now, now, date)
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

func (s *Storage) GetDailyMetricsSince(timestamp int64) ([]models.DailyMetrics, []int64, error) {
	rows, err := s.db.Query(`
		SELECT date, water_liters, exercise_done, exercise_note, updated_at, deleted_at
		FROM daily_metrics
		WHERE updated_at > ?
		ORDER BY updated_at ASC
	`, timestamp)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var metrics []models.DailyMetrics
	var deletedDates []int64

	for rows.Next() {
		var m models.DailyMetrics
		var waterLiters sql.NullFloat64
		var exerciseDone sql.NullInt64
		var exerciseNote sql.NullString
		var deletedAt sql.NullInt64

		if err := rows.Scan(&m.Date, &waterLiters, &exerciseDone, &exerciseNote, &m.UpdatedAt, &deletedAt); err != nil {
			return nil, nil, err
		}
		if waterLiters.Valid {
			m.WaterLiters = &waterLiters.Float64
		}
		if exerciseDone.Valid {
			value := exerciseDone.Int64 == 1
			m.ExerciseDone = &value
		}
		if exerciseNote.Valid {
			m.ExerciseNote = &exerciseNote.String
		}
		if deletedAt.Valid {
			m.DeletedAt = &deletedAt.Int64
			deletedDates = append(deletedDates, m.Date)
		}

		metrics = append(metrics, m)
	}

	if metrics == nil {
		metrics = []models.DailyMetrics{}
	}
	if deletedDates == nil {
		deletedDates = []int64{}
	}

	return metrics, deletedDates, nil
}

func (s *Storage) GetBodyMetricsSince(timestamp int64) ([]models.BodyMetric, []int64, error) {
	rows, err := s.db.Query(`
		SELECT id, date, weight, body_fat, notes, created_at, updated_at, deleted_at
		FROM body_metrics
		WHERE updated_at > ?
		ORDER BY updated_at ASC
	`, timestamp)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var metrics []models.BodyMetric
	var deletedIDs []int64

	for rows.Next() {
		var m models.BodyMetric
		var weight sql.NullFloat64
		var bodyFat sql.NullFloat64
		var notes sql.NullString
		var deletedAt sql.NullInt64
		if err := rows.Scan(&m.ID, &m.Date, &weight, &bodyFat, &notes, &m.CreatedAt, &m.UpdatedAt, &deletedAt); err != nil {
			return nil, nil, err
		}
		if weight.Valid {
			m.Weight = &weight.Float64
		}
		if bodyFat.Valid {
			m.BodyFat = &bodyFat.Float64
		}
		if notes.Valid {
			m.Notes = &notes.String
		}
		if deletedAt.Valid {
			m.DeletedAt = &deletedAt.Int64
			deletedIDs = append(deletedIDs, m.ID)
		}
		metrics = append(metrics, m)
	}

	if metrics == nil {
		metrics = []models.BodyMetric{}
	}
	if deletedIDs == nil {
		deletedIDs = []int64{}
	}

	return metrics, deletedIDs, nil
}

func (s *Storage) UpdateBodyMetric(m *models.BodyMetric) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE body_metrics
		SET date = ?, weight = ?, body_fat = ?, notes = ?, updated_at = ?
		WHERE id = ? AND deleted_at IS NULL
	`, m.Date, m.Weight, m.BodyFat, m.Notes, now, m.ID)
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

func (s *Storage) SoftDeleteBodyMetric(id int64) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE body_metrics SET deleted_at = ?, updated_at = ? WHERE id = ? AND deleted_at IS NULL
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

// --- Workouts ---

func (s *Storage) SaveWorkout(m *models.Workout) error {
	now := time.Now().UnixMilli()

	var result sql.Result
	var err error

	if m.SourceID != nil {
		result, err = s.db.Exec(`
			INSERT INTO workouts (type, date, duration_seconds, distance_meters, calories, heart_rate_avg, heart_rate_max, notes, source, source_id, strava_data, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT(source_id) WHERE source_id IS NOT NULL
			DO UPDATE SET type = excluded.type, date = excluded.date, duration_seconds = excluded.duration_seconds, distance_meters = excluded.distance_meters, calories = excluded.calories, heart_rate_avg = excluded.heart_rate_avg, heart_rate_max = excluded.heart_rate_max, notes = excluded.notes, source = excluded.source, strava_data = excluded.strava_data, updated_at = excluded.updated_at, deleted_at = NULL
		`, m.Type, m.Date, m.DurationSeconds, m.DistanceMeters, m.Calories, m.HeartRateAvg, m.HeartRateMax, m.Notes, m.Source, m.SourceID, m.StravaData, now, now)
	} else {
		result, err = s.db.Exec(`
			INSERT INTO workouts (type, date, duration_seconds, distance_meters, calories, heart_rate_avg, heart_rate_max, notes, source, strava_data, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, m.Type, m.Date, m.DurationSeconds, m.DistanceMeters, m.Calories, m.HeartRateAvg, m.HeartRateMax, m.Notes, m.Source, m.StravaData, now, now)
	}
	if err != nil {
		return err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return err
	}
	if m.SourceID != nil {
		if err := s.db.QueryRow(`
			SELECT id, created_at
			FROM workouts
			WHERE source_id = ?
		`, m.SourceID).Scan(&m.ID, &m.CreatedAt); err != nil {
			return err
		}
	} else {
		m.ID = id
		m.CreatedAt = now
	}
	m.UpdatedAt = now
	return nil
}

func (s *Storage) GetWorkoutByID(id int64) (*models.Workout, error) {
	var m models.Workout
	var durationSeconds sql.NullInt64
	var distanceMeters sql.NullFloat64
	var calories sql.NullInt64
	var heartRateAvg sql.NullInt64
	var heartRateMax sql.NullInt64
	var notes sql.NullString
	var sourceID sql.NullString
	var stravaData sql.NullString
	var deletedAt sql.NullInt64
	err := s.db.QueryRow(`
		SELECT id, type, date, duration_seconds, distance_meters, calories, heart_rate_avg, heart_rate_max, notes, source, source_id, strava_data, created_at, updated_at, deleted_at
		FROM workouts
		WHERE id = ? AND deleted_at IS NULL
	`, id).Scan(&m.ID, &m.Type, &m.Date, &durationSeconds, &distanceMeters, &calories, &heartRateAvg, &heartRateMax, &notes, &m.Source, &sourceID, &stravaData, &m.CreatedAt, &m.UpdatedAt, &deletedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if durationSeconds.Valid {
		value := int(durationSeconds.Int64)
		m.DurationSeconds = &value
	}
	if distanceMeters.Valid {
		m.DistanceMeters = &distanceMeters.Float64
	}
	if calories.Valid {
		value := int(calories.Int64)
		m.Calories = &value
	}
	if heartRateAvg.Valid {
		value := int(heartRateAvg.Int64)
		m.HeartRateAvg = &value
	}
	if heartRateMax.Valid {
		value := int(heartRateMax.Int64)
		m.HeartRateMax = &value
	}
	if notes.Valid {
		m.Notes = &notes.String
	}
	if sourceID.Valid {
		m.SourceID = &sourceID.String
	}
	if stravaData.Valid {
		m.StravaData = &stravaData.String
	}
	if deletedAt.Valid {
		m.DeletedAt = &deletedAt.Int64
	}
	return &m, nil
}

func (s *Storage) GetWorkoutsByDate(dateStr string) ([]models.Workout, error) {
	rows, err := s.db.Query(`
		SELECT id, type, date, duration_seconds, distance_meters, calories, heart_rate_avg, heart_rate_max, notes, source, source_id, strava_data, created_at, updated_at, deleted_at
		FROM workouts
		WHERE date(date / 1000, 'unixepoch') = ?
		AND deleted_at IS NULL
		ORDER BY date ASC
	`, dateStr)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var workouts []models.Workout
	for rows.Next() {
		var m models.Workout
		var durationSeconds sql.NullInt64
		var distanceMeters sql.NullFloat64
		var calories sql.NullInt64
		var heartRateAvg sql.NullInt64
		var heartRateMax sql.NullInt64
		var notes sql.NullString
		var sourceID sql.NullString
		var stravaData sql.NullString
		var deletedAt sql.NullInt64
		if err := rows.Scan(&m.ID, &m.Type, &m.Date, &durationSeconds, &distanceMeters, &calories, &heartRateAvg, &heartRateMax, &notes, &m.Source, &sourceID, &stravaData, &m.CreatedAt, &m.UpdatedAt, &deletedAt); err != nil {
			return nil, err
		}
		if durationSeconds.Valid {
			value := int(durationSeconds.Int64)
			m.DurationSeconds = &value
		}
		if distanceMeters.Valid {
			m.DistanceMeters = &distanceMeters.Float64
		}
		if calories.Valid {
			value := int(calories.Int64)
			m.Calories = &value
		}
		if heartRateAvg.Valid {
			value := int(heartRateAvg.Int64)
			m.HeartRateAvg = &value
		}
		if heartRateMax.Valid {
			value := int(heartRateMax.Int64)
			m.HeartRateMax = &value
		}
		if notes.Valid {
			m.Notes = &notes.String
		}
		if sourceID.Valid {
			m.SourceID = &sourceID.String
		}
		if stravaData.Valid {
			m.StravaData = &stravaData.String
		}
		if deletedAt.Valid {
			m.DeletedAt = &deletedAt.Int64
		}
		workouts = append(workouts, m)
	}

	if workouts == nil {
		workouts = []models.Workout{}
	}
	return workouts, nil
}

func (s *Storage) GetRecentWorkouts(days int) ([]models.Workout, error) {
	rows, err := s.db.Query(`
		SELECT id, type, date, duration_seconds, distance_meters, calories, heart_rate_avg, heart_rate_max, notes, source, source_id, strava_data, created_at, updated_at, deleted_at
		FROM workouts
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
		ORDER BY date DESC
	`, fmt.Sprintf("-%d", days))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var workouts []models.Workout
	for rows.Next() {
		var m models.Workout
		var durationSeconds sql.NullInt64
		var distanceMeters sql.NullFloat64
		var calories sql.NullInt64
		var heartRateAvg sql.NullInt64
		var heartRateMax sql.NullInt64
		var notes sql.NullString
		var sourceID sql.NullString
		var stravaData sql.NullString
		var deletedAt sql.NullInt64
		if err := rows.Scan(&m.ID, &m.Type, &m.Date, &durationSeconds, &distanceMeters, &calories, &heartRateAvg, &heartRateMax, &notes, &m.Source, &sourceID, &stravaData, &m.CreatedAt, &m.UpdatedAt, &deletedAt); err != nil {
			return nil, err
		}
		if durationSeconds.Valid {
			value := int(durationSeconds.Int64)
			m.DurationSeconds = &value
		}
		if distanceMeters.Valid {
			m.DistanceMeters = &distanceMeters.Float64
		}
		if calories.Valid {
			value := int(calories.Int64)
			m.Calories = &value
		}
		if heartRateAvg.Valid {
			value := int(heartRateAvg.Int64)
			m.HeartRateAvg = &value
		}
		if heartRateMax.Valid {
			value := int(heartRateMax.Int64)
			m.HeartRateMax = &value
		}
		if notes.Valid {
			m.Notes = &notes.String
		}
		if sourceID.Valid {
			m.SourceID = &sourceID.String
		}
		if stravaData.Valid {
			m.StravaData = &stravaData.String
		}
		if deletedAt.Valid {
			m.DeletedAt = &deletedAt.Int64
		}
		workouts = append(workouts, m)
	}

	if workouts == nil {
		workouts = []models.Workout{}
	}
	return workouts, nil
}

func (s *Storage) GetWorkoutStats(days int) (map[string]interface{}, error) {
	stats := map[string]interface{}{
		"total":         0,
		"byType":        map[string]int{},
		"totalDuration": 0,
		"totalDistance": 0.0,
	}

	var total int
	err := s.db.QueryRow(`
		SELECT COUNT(*)
		FROM workouts
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
	`, fmt.Sprintf("-%d", days)).Scan(&total)
	if err != nil {
		return nil, err
	}
	stats["total"] = total

	rows, err := s.db.Query(`
		SELECT type, COUNT(*)
		FROM workouts
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
		GROUP BY type
	`, fmt.Sprintf("-%d", days))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	byType := make(map[string]int)
	for rows.Next() {
		var workoutType string
		var count int
		if err := rows.Scan(&workoutType, &count); err != nil {
			return nil, err
		}
		byType[workoutType] = count
	}
	stats["byType"] = byType

	var totalDuration sql.NullInt64
	var totalDistance sql.NullFloat64
	err = s.db.QueryRow(`
		SELECT COALESCE(SUM(duration_seconds), 0), COALESCE(SUM(distance_meters), 0)
		FROM workouts
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
	`, fmt.Sprintf("-%d", days)).Scan(&totalDuration, &totalDistance)
	if err != nil {
		return nil, err
	}
	if totalDuration.Valid {
		stats["totalDuration"] = int(totalDuration.Int64)
	}
	if totalDistance.Valid {
		stats["totalDistance"] = totalDistance.Float64
	}

	return stats, nil
}

func (s *Storage) GetWorkoutsSince(timestamp int64) ([]models.Workout, []int64, error) {
	rows, err := s.db.Query(`
		SELECT id, type, date, duration_seconds, distance_meters, calories, heart_rate_avg, heart_rate_max, notes, source, source_id, strava_data, created_at, updated_at, deleted_at
		FROM workouts
		WHERE updated_at > ?
		ORDER BY updated_at ASC
	`, timestamp)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var workouts []models.Workout
	var deletedIDs []int64

	for rows.Next() {
		var m models.Workout
		var durationSeconds sql.NullInt64
		var distanceMeters sql.NullFloat64
		var calories sql.NullInt64
		var heartRateAvg sql.NullInt64
		var heartRateMax sql.NullInt64
		var notes sql.NullString
		var sourceID sql.NullString
		var stravaData sql.NullString
		var deletedAt sql.NullInt64
		if err := rows.Scan(&m.ID, &m.Type, &m.Date, &durationSeconds, &distanceMeters, &calories, &heartRateAvg, &heartRateMax, &notes, &m.Source, &sourceID, &stravaData, &m.CreatedAt, &m.UpdatedAt, &deletedAt); err != nil {
			return nil, nil, err
		}
		if durationSeconds.Valid {
			value := int(durationSeconds.Int64)
			m.DurationSeconds = &value
		}
		if distanceMeters.Valid {
			m.DistanceMeters = &distanceMeters.Float64
		}
		if calories.Valid {
			value := int(calories.Int64)
			m.Calories = &value
		}
		if heartRateAvg.Valid {
			value := int(heartRateAvg.Int64)
			m.HeartRateAvg = &value
		}
		if heartRateMax.Valid {
			value := int(heartRateMax.Int64)
			m.HeartRateMax = &value
		}
		if notes.Valid {
			m.Notes = &notes.String
		}
		if sourceID.Valid {
			m.SourceID = &sourceID.String
		}
		if stravaData.Valid {
			m.StravaData = &stravaData.String
		}
		if deletedAt.Valid {
			m.DeletedAt = &deletedAt.Int64
			deletedIDs = append(deletedIDs, m.ID)
		}
		workouts = append(workouts, m)
	}

	if workouts == nil {
		workouts = []models.Workout{}
	}
	if deletedIDs == nil {
		deletedIDs = []int64{}
	}

	return workouts, deletedIDs, nil
}

func (s *Storage) UpdateWorkout(m *models.Workout) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE workouts
		SET type = ?, date = ?, duration_seconds = ?, distance_meters = ?, calories = ?, heart_rate_avg = ?, heart_rate_max = ?, notes = ?, source = ?, source_id = ?, strava_data = ?, updated_at = ?
		WHERE id = ? AND deleted_at IS NULL
	`, m.Type, m.Date, m.DurationSeconds, m.DistanceMeters, m.Calories, m.HeartRateAvg, m.HeartRateMax, m.Notes, m.Source, m.SourceID, m.StravaData, now, m.ID)
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

func (s *Storage) SoftDeleteWorkout(id int64) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE workouts SET deleted_at = ?, updated_at = ? WHERE id = ? AND deleted_at IS NULL
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

// --- Screen Time ---

func (s *Storage) UpsertScreenTime(st *models.ScreenTime, apps []models.ScreenTimeApp) error {
	now := time.Now().UnixMilli()

	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	if _, err := tx.Exec(`
		INSERT INTO screen_time (date, total_ms, pickups, created_at, updated_at, deleted_at)
		VALUES (?, ?, ?, ?, ?, NULL)
		ON CONFLICT(date)
		DO UPDATE SET total_ms = excluded.total_ms, pickups = excluded.pickups, updated_at = excluded.updated_at, deleted_at = NULL
	`, st.Date, st.TotalMs, st.Pickups, now, now); err != nil {
		return err
	}

	var deletedAt sql.NullInt64
	if err := tx.QueryRow(`
		SELECT id, created_at, updated_at, deleted_at
		FROM screen_time
		WHERE date = ?
	`, st.Date).Scan(&st.ID, &st.CreatedAt, &st.UpdatedAt, &deletedAt); err != nil {
		return err
	}
	if deletedAt.Valid {
		st.DeletedAt = &deletedAt.Int64
	} else {
		st.DeletedAt = nil
	}

	if _, err := tx.Exec(`DELETE FROM screen_time_apps WHERE screen_time_id = ?`, st.ID); err != nil {
		return err
	}

	for i := range apps {
		apps[i].ScreenTimeID = st.ID

		result, err := tx.Exec(`
			INSERT INTO screen_time_apps (screen_time_id, package_name, app_name, duration_ms)
			VALUES (?, ?, ?, ?)
		`, apps[i].ScreenTimeID, apps[i].PackageName, apps[i].AppName, apps[i].DurationMs)
		if err != nil {
			return err
		}

		id, err := result.LastInsertId()
		if err != nil {
			return err
		}
		apps[i].ID = id
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	st.Apps = apps
	return nil
}

func (s *Storage) GetScreenTimeByDate(dateStr string) (*models.ScreenTime, []models.ScreenTimeApp, error) {
	var st models.ScreenTime
	var pickups sql.NullInt64
	var deletedAt sql.NullInt64

	err := s.db.QueryRow(`
		SELECT id, date, total_ms, pickups, created_at, updated_at, deleted_at
		FROM screen_time
		WHERE date(date / 1000, 'unixepoch') = ?
		AND deleted_at IS NULL
	`, dateStr).Scan(&st.ID, &st.Date, &st.TotalMs, &pickups, &st.CreatedAt, &st.UpdatedAt, &deletedAt)
	if err == sql.ErrNoRows {
		return nil, []models.ScreenTimeApp{}, nil
	}
	if err != nil {
		return nil, nil, err
	}
	if pickups.Valid {
		value := int(pickups.Int64)
		st.Pickups = &value
	}
	if deletedAt.Valid {
		st.DeletedAt = &deletedAt.Int64
	}

	rows, err := s.db.Query(`
		SELECT id, screen_time_id, package_name, app_name, duration_ms
		FROM screen_time_apps
		WHERE screen_time_id = ?
		ORDER BY duration_ms DESC, id ASC
	`, st.ID)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var apps []models.ScreenTimeApp
	for rows.Next() {
		var app models.ScreenTimeApp
		if err := rows.Scan(&app.ID, &app.ScreenTimeID, &app.PackageName, &app.AppName, &app.DurationMs); err != nil {
			return nil, nil, err
		}
		apps = append(apps, app)
	}

	if apps == nil {
		apps = []models.ScreenTimeApp{}
	}
	st.Apps = apps
	return &st, apps, nil
}

func (s *Storage) GetRecentScreenTime(days int) ([]models.ScreenTime, error) {
	rows, err := s.db.Query(`
		SELECT id, date, total_ms, pickups, created_at, updated_at, deleted_at
		FROM screen_time
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
		ORDER BY date DESC
	`, fmt.Sprintf("-%d", days))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var entries []models.ScreenTime
	for rows.Next() {
		var st models.ScreenTime
		var pickups sql.NullInt64
		var deletedAt sql.NullInt64
		if err := rows.Scan(&st.ID, &st.Date, &st.TotalMs, &pickups, &st.CreatedAt, &st.UpdatedAt, &deletedAt); err != nil {
			return nil, err
		}
		if pickups.Valid {
			value := int(pickups.Int64)
			st.Pickups = &value
		}
		if deletedAt.Valid {
			st.DeletedAt = &deletedAt.Int64
		}
		entries = append(entries, st)
	}

	if entries == nil {
		entries = []models.ScreenTime{}
	}
	return entries, nil
}

func (s *Storage) DeleteScreenTime(date int64) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE screen_time
		SET deleted_at = ?, updated_at = ?
		WHERE date = ? AND deleted_at IS NULL
	`, now, now, date)
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

func (s *Storage) GetScreenTimeSince(timestamp int64) ([]models.ScreenTime, []int64, error) {
	rows, err := s.db.Query(`
		SELECT id, date, total_ms, pickups, created_at, updated_at, deleted_at
		FROM screen_time
		WHERE updated_at > ?
		ORDER BY updated_at ASC
	`, timestamp)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var entries []models.ScreenTime
	var deletedDates []int64

	for rows.Next() {
		var st models.ScreenTime
		var pickups sql.NullInt64
		var deletedAt sql.NullInt64
		if err := rows.Scan(&st.ID, &st.Date, &st.TotalMs, &pickups, &st.CreatedAt, &st.UpdatedAt, &deletedAt); err != nil {
			return nil, nil, err
		}
		if pickups.Valid {
			value := int(pickups.Int64)
			st.Pickups = &value
		}
		if deletedAt.Valid {
			st.DeletedAt = &deletedAt.Int64
			deletedDates = append(deletedDates, st.Date)
		} else {
			apps, err := s.GetScreenTimeAppsByID(st.ID)
			if err != nil {
				return nil, nil, err
			}
			st.Apps = apps
		}
		entries = append(entries, st)
	}

	if entries == nil {
		entries = []models.ScreenTime{}
	}
	if deletedDates == nil {
		deletedDates = []int64{}
	}

	return entries, deletedDates, nil
}

func (s *Storage) GetScreenTimeAppsByID(screenTimeID int64) ([]models.ScreenTimeApp, error) {
	rows, err := s.db.Query(`
		SELECT id, screen_time_id, package_name, app_name, duration_ms
		FROM screen_time_apps
		WHERE screen_time_id = ?
		ORDER BY duration_ms DESC, id ASC
	`, screenTimeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var apps []models.ScreenTimeApp
	for rows.Next() {
		var app models.ScreenTimeApp
		if err := rows.Scan(&app.ID, &app.ScreenTimeID, &app.PackageName, &app.AppName, &app.DurationMs); err != nil {
			return nil, err
		}
		apps = append(apps, app)
	}

	if apps == nil {
		apps = []models.ScreenTimeApp{}
	}
	return apps, nil
}

func (s *Storage) GetScreenTimeStats(days int) (int64, int, map[string]int64, error) {
	var avgDailyMs sql.NullFloat64
	if err := s.db.QueryRow(`
		SELECT AVG(total_ms)
		FROM screen_time
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
	`, fmt.Sprintf("-%d", days)).Scan(&avgDailyMs); err != nil {
		return 0, 0, nil, err
	}

	var totalPickups sql.NullInt64
	if err := s.db.QueryRow(`
		SELECT COALESCE(SUM(pickups), 0)
		FROM screen_time
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
	`, fmt.Sprintf("-%d", days)).Scan(&totalPickups); err != nil {
		return 0, 0, nil, err
	}

	rows, err := s.db.Query(`
		SELECT sta.app_name, SUM(sta.duration_ms)
		FROM screen_time_apps sta
		INNER JOIN screen_time st ON st.id = sta.screen_time_id
		WHERE st.date >= strftime('%s', 'now', ? || ' days') * 1000
		AND st.deleted_at IS NULL
		GROUP BY sta.app_name
		ORDER BY SUM(sta.duration_ms) DESC, sta.app_name ASC
	`, fmt.Sprintf("-%d", days))
	if err != nil {
		return 0, 0, nil, err
	}
	defer rows.Close()

	topApps := make(map[string]int64)
	for rows.Next() {
		var appName string
		var durationMs int64
		if err := rows.Scan(&appName, &durationMs); err != nil {
			return 0, 0, nil, err
		}
		topApps[appName] = durationMs
	}

	return int64(avgDailyMs.Float64), int(totalPickups.Int64), topApps, nil
}

// --- Hydration ---

func (s *Storage) SaveHydration(h *models.Hydration) error {
	now := time.Now().UnixMilli()

	result, err := s.db.Exec(`
		INSERT INTO hydration (date, amount_ml, created_at, updated_at, deleted_at)
		VALUES (?, ?, ?, ?, NULL)
	`, h.Date, h.AmountMl, now, now)
	if err != nil {
		return err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return err
	}
	h.ID = id
	h.CreatedAt = now
	h.UpdatedAt = now
	h.DeletedAt = nil
	return nil
}

func (s *Storage) GetHydrationByDate(dateStr string) ([]models.Hydration, error) {
	rows, err := s.db.Query(`
		SELECT id, date, amount_ml, created_at, updated_at, deleted_at
		FROM hydration
		WHERE date(date / 1000, 'unixepoch') = ?
		AND deleted_at IS NULL
		ORDER BY created_at ASC
	`, dateStr)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var entries []models.Hydration
	for rows.Next() {
		var h models.Hydration
		var deletedAt sql.NullInt64
		if err := rows.Scan(&h.ID, &h.Date, &h.AmountMl, &h.CreatedAt, &h.UpdatedAt, &deletedAt); err != nil {
			return nil, err
		}
		if deletedAt.Valid {
			h.DeletedAt = &deletedAt.Int64
		}
		entries = append(entries, h)
	}

	if entries == nil {
		entries = []models.Hydration{}
	}
	return entries, nil
}

func (s *Storage) GetRecentHydration(days int) ([]models.Hydration, error) {
	rows, err := s.db.Query(`
		SELECT id, date, amount_ml, created_at, updated_at, deleted_at
		FROM hydration
		WHERE date >= strftime('%s', 'now', ? || ' days') * 1000
		AND deleted_at IS NULL
		ORDER BY date DESC, created_at DESC
	`, fmt.Sprintf("-%d", days))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var entries []models.Hydration
	for rows.Next() {
		var h models.Hydration
		var deletedAt sql.NullInt64
		if err := rows.Scan(&h.ID, &h.Date, &h.AmountMl, &h.CreatedAt, &h.UpdatedAt, &deletedAt); err != nil {
			return nil, err
		}
		if deletedAt.Valid {
			h.DeletedAt = &deletedAt.Int64
		}
		entries = append(entries, h)
	}

	if entries == nil {
		entries = []models.Hydration{}
	}
	return entries, nil
}

func (s *Storage) DeleteHydration(id int64) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE hydration SET deleted_at = ?, updated_at = ? WHERE id = ? AND deleted_at IS NULL
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

func (s *Storage) GetHydrationSince(timestamp int64) ([]models.Hydration, []int64, error) {
	rows, err := s.db.Query(`
		SELECT id, date, amount_ml, created_at, updated_at, deleted_at
		FROM hydration
		WHERE updated_at > ?
		ORDER BY updated_at ASC
	`, timestamp)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var entries []models.Hydration
	var deletedIDs []int64

	for rows.Next() {
		var h models.Hydration
		var deletedAt sql.NullInt64
		if err := rows.Scan(&h.ID, &h.Date, &h.AmountMl, &h.CreatedAt, &h.UpdatedAt, &deletedAt); err != nil {
			return nil, nil, err
		}
		if deletedAt.Valid {
			h.DeletedAt = &deletedAt.Int64
			deletedIDs = append(deletedIDs, h.ID)
		}
		entries = append(entries, h)
	}

	if entries == nil {
		entries = []models.Hydration{}
	}
	if deletedIDs == nil {
		deletedIDs = []int64{}
	}

	return entries, deletedIDs, nil
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

func (s *Storage) DeleteImage(mealID int64, filename string) error {
	result, err := s.db.Exec(
		`DELETE FROM meal_images WHERE meal_id = ? AND filename = ?`,
		mealID,
		filename,
	)
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

	imagePath := s.GetImagePath(mealID, filename)
	if err := os.Remove(imagePath); err != nil && !os.IsNotExist(err) {
		return err
	}

	return nil
}

// --- Day Ratings ---

func (s *Storage) SaveDayRating(r *models.DayRating) error {
	now := time.Now().UnixMilli()
	_, err := s.db.Exec(`
		INSERT INTO day_ratings (date, score, updated_at, deleted_at)
		VALUES (?, ?, ?, NULL)
		ON CONFLICT(date)
		DO UPDATE SET score = excluded.score, updated_at = excluded.updated_at, deleted_at = NULL
	`, r.Date, r.Score, now)
	r.UpdatedAt = now
	r.DeletedAt = nil
	return err
}

func (s *Storage) applyMealCompatibilityFields(m *models.Meal) {
	m.UpdatedAtCompat = m.UpdatedAt
	if len(m.Images) == 0 {
		return
	}

	imagePath := m.Images[0].URL
	m.ImagePath = &imagePath
}

func nullableBoolToInt(value *bool) interface{} {
	if value == nil {
		return nil
	}
	if *value {
		return 1
	}
	return 0
}

func (s *Storage) GetDayRating(date int64) (*models.DayRating, error) {
	var r models.DayRating
	var deletedAt sql.NullInt64
	err := s.db.QueryRow(`
		SELECT date, score, updated_at, deleted_at
		FROM day_ratings
		WHERE date = ? AND deleted_at IS NULL
	`, date).Scan(&r.Date, &r.Score, &r.UpdatedAt, &deletedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if deletedAt.Valid {
		r.DeletedAt = &deletedAt.Int64
	}
	return &r, nil
}

func (s *Storage) DeleteDayRating(date int64) error {
	now := time.Now().UnixMilli()
	result, err := s.db.Exec(`
		UPDATE day_ratings
		SET deleted_at = ?, updated_at = ?
		WHERE date = ? AND deleted_at IS NULL
	`, now, now, date)
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

func (s *Storage) GetDayRatingsSince(timestamp int64) ([]models.DayRating, []int64, error) {
	rows, err := s.db.Query(`
		SELECT date, score, updated_at, deleted_at
		FROM day_ratings
		WHERE updated_at > ?
		ORDER BY updated_at ASC
	`, timestamp)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var ratings []models.DayRating
	var deletedDates []int64

	for rows.Next() {
		var rating models.DayRating
		var deletedAt sql.NullInt64
		if err := rows.Scan(&rating.Date, &rating.Score, &rating.UpdatedAt, &deletedAt); err != nil {
			return nil, nil, err
		}
		if deletedAt.Valid {
			rating.DeletedAt = &deletedAt.Int64
			deletedDates = append(deletedDates, rating.Date)
		}
		ratings = append(ratings, rating)
	}

	if ratings == nil {
		ratings = []models.DayRating{}
	}
	if deletedDates == nil {
		deletedDates = []int64{}
	}

	return ratings, deletedDates, nil
}

// --- Stats ---

func (s *Storage) GetStats() (*models.Stats, error) {
	stats := &models.Stats{
		MealsBySlot: make(map[string]int),
		WeightTrend: "stable",
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
	if err := s.db.QueryRow(
		"SELECT AVG(score) FROM day_ratings WHERE deleted_at IS NULL",
	).Scan(&avgRating); err != nil && err != sql.ErrNoRows {
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

	now := time.Now().UTC()
	startOfToday := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	startOfWeek := startOfToday.AddDate(0, 0, -((int(startOfToday.Weekday()) + 6) % 7))
	startOfMonth := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
	startOfSevenDayWindow := startOfToday.AddDate(0, 0, -6)
	startOfWeekMillis := startOfWeek.UnixMilli()
	startOfMonthMillis := startOfMonth.UnixMilli()
	startOfSevenDayWindowMillis := startOfSevenDayWindow.UnixMilli()

	var latestWeight sql.NullFloat64
	if err := s.db.QueryRow(`
		SELECT weight
		FROM body_metrics
		WHERE weight IS NOT NULL
		AND deleted_at IS NULL
		ORDER BY date DESC
		LIMIT 1
	`).Scan(&latestWeight); err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	if latestWeight.Valid {
		stats.LatestWeight = &latestWeight.Float64
	}

	weightRows, err := s.db.Query(`
		SELECT weight
		FROM body_metrics
		WHERE weight IS NOT NULL
		AND deleted_at IS NULL
		ORDER BY date DESC
		LIMIT 7
	`)
	if err != nil {
		return nil, err
	}
	defer weightRows.Close()

	var weights []float64
	for weightRows.Next() {
		var weight float64
		if err := weightRows.Scan(&weight); err != nil {
			return nil, err
		}
		weights = append(weights, weight)
	}
	if err := weightRows.Err(); err != nil {
		return nil, err
	}
	if len(weights) >= 2 {
		oldest := weights[len(weights)-1]
		newest := weights[0]
		diff := newest - oldest
		switch {
		case diff > 0.1:
			stats.WeightTrend = "up"
		case diff < -0.1:
			stats.WeightTrend = "down"
		default:
			stats.WeightTrend = "stable"
		}
	}

	if err := s.db.QueryRow(`
		SELECT COUNT(*)
		FROM workouts
		WHERE date >= ?
		AND deleted_at IS NULL
	`, startOfWeekMillis).Scan(&stats.WorkoutsThisWeek); err != nil {
		return nil, err
	}

	if err := s.db.QueryRow(`
		SELECT COUNT(*)
		FROM workouts
		WHERE date >= ?
		AND deleted_at IS NULL
	`, startOfMonthMillis).Scan(&stats.WorkoutsThisMonth); err != nil {
		return nil, err
	}

	var avgDailyScreenTimeMs sql.NullFloat64
	if err := s.db.QueryRow(`
		SELECT AVG(total_ms)
		FROM screen_time
		WHERE date >= ?
		AND deleted_at IS NULL
	`, startOfSevenDayWindowMillis).Scan(&avgDailyScreenTimeMs); err != nil {
		return nil, err
	}
	if avgDailyScreenTimeMs.Valid {
		stats.AvgDailyScreenTimeMs = int64(avgDailyScreenTimeMs.Float64)
	}

	var avgMood sql.NullFloat64
	var avgEnergy sql.NullFloat64
	var avgSleepHours sql.NullFloat64
	if err := s.db.QueryRow(`
		SELECT AVG(mood), AVG(energy), AVG(sleep_hours)
		FROM daily_checkins
		WHERE date >= ?
		AND deleted_at IS NULL
	`, startOfSevenDayWindowMillis).Scan(&avgMood, &avgEnergy, &avgSleepHours); err != nil {
		return nil, err
	}
	if avgMood.Valid {
		stats.AvgMood = avgMood.Float64
	}
	if avgEnergy.Valid {
		stats.AvgEnergy = avgEnergy.Float64
	}
	if avgSleepHours.Valid {
		stats.AvgSleepHours = avgSleepHours.Float64
	}

	var avgHydrationMl sql.NullFloat64
	if err := s.db.QueryRow(`
		SELECT AVG(daily_total)
		FROM (
			SELECT SUM(amount_ml) AS daily_total
			FROM hydration
			WHERE date >= ?
			AND deleted_at IS NULL
			GROUP BY date(date / 1000, 'unixepoch')
		)
	`, startOfSevenDayWindowMillis).Scan(&avgHydrationMl); err != nil {
		return nil, err
	}
	if avgHydrationMl.Valid {
		stats.AvgHydrationMl = avgHydrationMl.Float64
	}

	return stats, nil
}
