package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

var (
	db     *sql.DB
	apiKey string
)

type Meal struct {
	ID          int64   `json:"id,omitempty"`
	Slot        string  `json:"slot"`
	Date        int64   `json:"date"` // milliseconds since epoch
	Description *string `json:"description,omitempty"`
	ImagePath   *string `json:"imagePath,omitempty"`
}

func main() {
	apiKey = os.Getenv("API_KEY")
	if apiKey == "" {
		log.Fatal("API_KEY environment variable is required")
	}

	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		dbPath = "/data/meals.db"
	}

	var err error
	db, err = sql.Open("sqlite3", dbPath)
	if err != nil {
		log.Fatalf("Failed to open database: %v", err)
	}
	defer db.Close()

	// Create table if not exists
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS meals(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			slot TEXT NOT NULL,
			date INTEGER NOT NULL,
			description TEXT,
			imagePath TEXT
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create table: %v", err)
	}

	// Create index
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date)`)
	if err != nil {
		log.Fatalf("Failed to create index: %v", err)
	}

	http.HandleFunc("/health", authMiddleware(healthHandler))
	http.HandleFunc("/meals", authMiddleware(mealsHandler))

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting server on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Allow /health without auth for k8s probes
		if r.URL.Path == "/health" && r.Method == http.MethodGet {
			next(w, r)
			return
		}

		providedKey := r.Header.Get("X-API-Key")
		if providedKey == "" {
			http.Error(w, `{"error":"missing API key"}`, http.StatusUnauthorized)
			return
		}

		if providedKey != apiKey {
			http.Error(w, `{"error":"invalid API key"}`, http.StatusUnauthorized)
			return
		}

		next(w, r)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func mealsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		getMeals(w, r)
	case http.MethodPost:
		saveMeal(w, r)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func getMeals(w http.ResponseWriter, r *http.Request) {
	dateStr := r.URL.Query().Get("date")
	if dateStr == "" {
		http.Error(w, `{"error":"date parameter required (YYYY-MM-DD)"}`, http.StatusBadRequest)
		return
	}

	// Parse date
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		http.Error(w, `{"error":"invalid date format, use YYYY-MM-DD"}`, http.StatusBadRequest)
		return
	}

	// Get start and end of day in milliseconds
	startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)
	endOfDay := startOfDay.Add(24 * time.Hour)

	rows, err := db.Query(
		"SELECT id, slot, date, description, imagePath FROM meals WHERE date >= ? AND date < ? ORDER BY date ASC",
		startOfDay.UnixMilli(), endOfDay.UnixMilli(),
	)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	meals := []Meal{}
	for rows.Next() {
		var m Meal
		err := rows.Scan(&m.ID, &m.Slot, &m.Date, &m.Description, &m.ImagePath)
		if err != nil {
			http.Error(w, fmt.Sprintf(`{"error":"scan error: %v"}`, err), http.StatusInternalServerError)
			return
		}
		meals = append(meals, m)
	}

	json.NewEncoder(w).Encode(meals)
}

func saveMeal(w http.ResponseWriter, r *http.Request) {
	var m Meal
	if err := json.NewDecoder(r.Body).Decode(&m); err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	// Validate slot
	validSlots := map[string]bool{
		"breakfast": true, "lunch": true, "afternoonSnack": true, "dinner": true,
	}
	if !validSlots[m.Slot] {
		http.Error(w, `{"error":"invalid slot, must be breakfast, lunch, afternoonSnack, or dinner"}`, http.StatusBadRequest)
		return
	}

	// Insert meal
	result, err := db.Exec(
		"INSERT INTO meals (slot, date, description, imagePath) VALUES (?, ?, ?, ?)",
		m.Slot, m.Date, m.Description, m.ImagePath,
	)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"insert error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	id, err := result.LastInsertId()
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"last insert id error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	m.ID = id
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(m)
}
