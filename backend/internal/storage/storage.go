package storage

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"

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
			description TEXT
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
	return nil
}

func (s *Storage) Close() error {
	return s.db.Close()
}

// --- Meals ---

func (s *Storage) SaveMeal(m *models.Meal) error {
	result, err := s.db.Exec(
		"INSERT INTO meals (slot, date, description) VALUES (?, ?, ?)",
		m.Slot, m.Date, m.Description,
	)
	if err != nil {
		return err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return err
	}
	m.ID = id
	return nil
}

func (s *Storage) GetMealsByDate(dateStr string) ([]models.Meal, error) {
	// Parse date and get range
	// dateStr is YYYY-MM-DD
	
	rows, err := s.db.Query(`
		SELECT m.id, m.slot, m.date, m.description
		FROM meals m
		WHERE date(m.date / 1000, 'unixepoch') = ?
		ORDER BY m.date ASC
	`, dateStr)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var meals []models.Meal
	for rows.Next() {
		var m models.Meal
		if err := rows.Scan(&m.ID, &m.Slot, &m.Date, &m.Description); err != nil {
			return nil, err
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
		SELECT m.id, m.slot, m.date, m.description
		FROM meals m
		WHERE m.date >= strftime('%s', 'now', ? || ' days') * 1000
		ORDER BY m.date DESC
	`, fmt.Sprintf("-%d", days))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var meals []models.Meal
	for rows.Next() {
		var m models.Meal
		if err := rows.Scan(&m.ID, &m.Slot, &m.Date, &m.Description); err != nil {
			return nil, err
		}
		m.Images, _ = s.GetImagesByMeal(m.ID)
		meals = append(meals, m)
	}

	if meals == nil {
		meals = []models.Meal{}
	}
	return meals, nil
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
	if err := s.db.QueryRow("SELECT AVG(score) FROM day_ratings").Scan(&stats.AvgRating); err != nil && err != sql.ErrNoRows {
		return nil, err
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
