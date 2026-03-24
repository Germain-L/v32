package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gmn/v32-backend/internal/models"
	"github.com/gmn/v32-backend/internal/storage"
)

type Handlers struct {
	store *storage.Storage
}

func New(store *storage.Storage) *Handlers {
	return &Handlers{store: store}
}

func (h *Handlers) Routes() *http.ServeMux {
	mux := http.NewServeMux()
	
	// Health check (no auth)
	mux.HandleFunc("/health", h.health)
	
	// Meals
	mux.HandleFunc("/meals", h.mealsHandler)
	mux.HandleFunc("/meals/recent", h.recentMeals)
	
	// Images
	mux.HandleFunc("/images/", h.serveImage)
	mux.HandleFunc("/upload", h.uploadImage)
	
	// Stats
	mux.HandleFunc("/stats", h.stats)
	
	// Day ratings
	mux.HandleFunc("/rating", h.ratingHandler)
	
	return mux
}

// --- Health ---

func (h *Handlers) health(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

// --- Meals ---

func (h *Handlers) mealsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		h.getMeals(w, r)
	case http.MethodPost:
		h.saveMeal(w, r)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handlers) getMeals(w http.ResponseWriter, r *http.Request) {
	dateStr := r.URL.Query().Get("date")
	if dateStr == "" {
		http.Error(w, `{"error":"date parameter required (YYYY-MM-DD)"}`, http.StatusBadRequest)
		return
	}

	meals, err := h.store.GetMealsByDate(dateStr)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(meals)
}

func (h *Handlers) saveMeal(w http.ResponseWriter, r *http.Request) {
	var m models.Meal
	if err := json.NewDecoder(r.Body).Decode(&m); err != nil {
		log.Printf("[ERROR] Invalid JSON: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	if !m.Validate() {
		log.Printf("[WARN] Invalid meal: slot=%s, date=%d", m.Slot, m.Date)
		http.Error(w, `{"error":"invalid meal: slot must be breakfast/lunch/afternoonSnack/dinner, date required"}`, http.StatusBadRequest)
		return
	}

	if err := h.store.SaveMeal(&m); err != nil {
		log.Printf("[ERROR] Save meal failed: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"save error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Meal saved: id=%d slot=%s date=%s", m.ID, m.Slot, models.DateFromMillis(m.Date))
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(m)
}

func (h *Handlers) recentMeals(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	days := 7
	if d := r.URL.Query().Get("days"); d != "" {
		if parsed, err := strconv.Atoi(d); err == nil && parsed > 0 && parsed <= 30 {
			days = parsed
		}
	}

	meals, err := h.store.GetRecentMeals(days)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(meals)
}

// --- Images ---

func (h *Handlers) uploadImage(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	// Parse multipart form (max 20MB)
	if err := r.ParseMultipartForm(20 << 20); err != nil {
		log.Printf("[ERROR] Parse multipart: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"parse error: %v"}`, err), http.StatusBadRequest)
		return
	}

	// Get meal ID
	mealIDStr := r.FormValue("mealId")
	if mealIDStr == "" {
		http.Error(w, `{"error":"mealId required"}`, http.StatusBadRequest)
		return
	}
	mealID, err := strconv.ParseInt(mealIDStr, 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid mealId"}`, http.StatusBadRequest)
		return
	}

	// Get file
	file, header, err := r.FormFile("image")
	if err != nil {
		log.Printf("[ERROR] Get form file: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"file error: %v"}`, err), http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Read file data
	data, err := io.ReadAll(file)
	if err != nil {
		log.Printf("[ERROR] Read file: %v", err)
		http.Error(w, `{"error":"read error"}`, http.StatusInternalServerError)
		return
	}

	// Generate filename
	ext := filepath.Ext(header.Filename)
	if ext == "" {
		ext = ".jpg"
	}
	filename := fmt.Sprintf("%d_%d%s", mealID, time.Now().UnixNano(), ext)

	// Save file
	if err := h.store.SaveImageFile(mealID, filename, data); err != nil {
		log.Printf("[ERROR] Save image file: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"save error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	// Save to database
	if err := h.store.SaveImage(mealID, filename); err != nil {
		log.Printf("[ERROR] Save image DB: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"db error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Image uploaded: mealId=%d filename=%s size=%d bytes", mealID, filename, len(data))
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{
		"status":   "ok",
		"filename": filename,
		"url":      fmt.Sprintf("/images/%d/%s", mealID, filename),
	})
}

func (h *Handlers) serveImage(w http.ResponseWriter, r *http.Request) {
	// URL format: /images/{mealId}/{filename}
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/images/"), "/")
	if len(parts) != 2 {
		http.Error(w, "invalid image path", http.StatusBadRequest)
		return
	}

	mealID, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		http.Error(w, "invalid meal ID", http.StatusBadRequest)
		return
	}
	filename := parts[1]

	imagePath := h.store.GetImagePath(mealID, filename)
	http.ServeFile(w, r, imagePath)
}

// --- Stats ---

func (h *Handlers) stats(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	stats, err := h.store.GetStats()
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(stats)
}

// --- Day Ratings ---

func (h *Handlers) ratingHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		h.getRating(w, r)
	case http.MethodPost:
		h.saveRating(w, r)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handlers) getRating(w http.ResponseWriter, r *http.Request) {
	dateStr := r.URL.Query().Get("date")
	if dateStr == "" {
		http.Error(w, `{"error":"date parameter required (epoch millis)"}`, http.StatusBadRequest)
		return
	}

	date, err := strconv.ParseInt(dateStr, 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid date"}`, http.StatusBadRequest)
		return
	}

	rating, err := h.store.GetDayRating(date)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	if rating == nil {
		json.NewEncoder(w).Encode(nil)
		return
	}

	json.NewEncoder(w).Encode(rating)
}

func (h *Handlers) saveRating(w http.ResponseWriter, r *http.Request) {
	var rating models.DayRating
	if err := json.NewDecoder(r.Body).Decode(&rating); err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	if !rating.Validate() {
		http.Error(w, `{"error":"invalid rating: score must be 1-5"}`, http.StatusBadRequest)
		return
	}

	if err := h.store.SaveDayRating(&rating); err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"save error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(rating)
}
