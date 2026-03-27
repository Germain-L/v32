package handlers

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
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
	mux.HandleFunc("/auth/strava", h.stravaAuthHandler)
	mux.HandleFunc("/auth/strava/callback", h.stravaAuthCallback)
	mux.HandleFunc("/auth/strava/disconnect", h.stravaDisconnect)
	mux.HandleFunc("/auth/strava/success", h.stravaAuthSuccess)
	mux.HandleFunc("/strava/sync", h.stravaSync)

	// Meals
	mux.HandleFunc("/meals", h.mealsHandler)
	mux.HandleFunc("/meals/recent", h.recentMeals)
	mux.HandleFunc("/meals/since", h.mealsSince)
	mux.HandleFunc("/meals/bulk", h.bulkMeals)
	mux.HandleFunc("/meals/", h.mealByID)

	// Screen time
	mux.HandleFunc("/screen-time", h.screenTimeHandler)
	mux.HandleFunc("/screen-time/recent", h.recentScreenTime)
	mux.HandleFunc("/screen-time/stats", h.screenTimeStats)

	// Workouts
	mux.HandleFunc("/workouts", h.workoutsHandler)
	mux.HandleFunc("/workouts/recent", h.recentWorkouts)
	mux.HandleFunc("/workouts/stats", h.workoutStats)
	mux.HandleFunc("/workouts/since", h.workoutsSince)
	mux.HandleFunc("/workouts/", h.workoutByID)

	// Body metrics
	mux.HandleFunc("/body-metrics", h.bodyMetricsHandler)
	mux.HandleFunc("/body-metrics/recent", h.recentBodyMetrics)
	mux.HandleFunc("/body-metrics/since", h.bodyMetricsSince)
	mux.HandleFunc("/body-metrics/", h.bodyMetricByID)

	// Images
	mux.HandleFunc("/images/", h.serveImage)
	mux.HandleFunc("/upload", h.uploadImage)

	// Stats
	mux.HandleFunc("/stats", h.stats)

	// Day ratings
	mux.HandleFunc("/rating", h.ratingHandler)
	mux.HandleFunc("/checkins", h.checkinHandler)
	mux.HandleFunc("/checkins/recent", h.recentCheckins)
	mux.HandleFunc("/hydration", h.hydrationHandler)
	mux.HandleFunc("/hydration/recent", h.recentHydration)
	mux.HandleFunc("/hydration/", h.deleteHydration)

	return mux
}

// --- Health ---

func (h *Handlers) health(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

type stravaTokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresAt    int64  `json:"expires_at"`
	Athlete      struct {
		ID int64 `json:"id"`
	} `json:"athlete"`
}

type stravaActivity struct {
	ID               int64    `json:"id"`
	Name             string   `json:"name"`
	Type             string   `json:"type"`
	StartDate        string   `json:"start_date"`
	MovingTime       int      `json:"moving_time"`
	Distance         float64  `json:"distance"`
	AverageHeartrate *float64 `json:"average_heartrate"`
	MaxHeartrate     *float64 `json:"max_heartrate"`
	Calories         *float64 `json:"calories"`
}

func (h *Handlers) stravaAuthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	clientID := os.Getenv("STRAVA_CLIENT_ID")
	if clientID == "" {
		http.Error(w, `{"error":"STRAVA_CLIENT_ID not configured"}`, http.StatusInternalServerError)
		return
	}

	redirectURL := (&url.URL{
		Scheme: "https",
		Host:   "www.strava.com",
		Path:   "/oauth/authorize",
		RawQuery: url.Values{
			"client_id":       {clientID},
			"response_type":   {"code"},
			"redirect_uri":    {h.stravaRedirectURI()},
			"scope":           {"read,activity:read_all"},
			"approval_prompt": {"auto"},
		}.Encode(),
	}).String()

	http.Redirect(w, r, redirectURL, http.StatusFound)
}

func (h *Handlers) stravaAuthCallback(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	code := r.URL.Query().Get("code")
	if code == "" {
		http.Error(w, `{"error":"missing code"}`, http.StatusBadRequest)
		return
	}

	clientID := os.Getenv("STRAVA_CLIENT_ID")
	clientSecret := os.Getenv("STRAVA_CLIENT_SECRET")
	if clientID == "" || clientSecret == "" {
		http.Error(w, `{"error":"Strava credentials not configured"}`, http.StatusInternalServerError)
		return
	}

	tokenResp, err := h.stravaTokenRequest(url.Values{
		"client_id":     {clientID},
		"client_secret": {clientSecret},
		"code":          {code},
		"grant_type":    {"authorization_code"},
	})
	if err != nil {
		log.Printf("[ERROR] Strava token exchange failed: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"token exchange failed: %v"}`, err), http.StatusBadGateway)
		return
	}

	if err := h.store.SaveStravaTokens(tokenResp.AccessToken, tokenResp.RefreshToken, tokenResp.ExpiresAt, tokenResp.Athlete.ID); err != nil {
		log.Printf("[ERROR] Save Strava tokens failed: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"failed to save tokens: %v"}`, err), http.StatusInternalServerError)
		return
	}

	http.Redirect(w, r, h.stravaSuccessURL(), http.StatusFound)
}

func (h *Handlers) stravaDisconnect(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	if err := h.store.DeleteStravaTokens(); err != nil {
		log.Printf("[ERROR] Delete Strava tokens failed: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"disconnect failed: %v"}`, err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) stravaAuthSuccess(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprint(w, `<!doctype html><html><head><title>Strava Connected</title></head><body><h1>Strava connected</h1><p>You can close this window.</p></body></html>`)
}

func (h *Handlers) stravaSync(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	accessToken, _, expiresAt, athleteID, err := h.store.GetStravaTokens()
	if err == sql.ErrNoRows {
		http.Error(w, `{"error":"strava not connected"}`, http.StatusNotFound)
		return
	}
	if err != nil {
		log.Printf("[ERROR] Load Strava tokens failed: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"token load failed: %v"}`, err), http.StatusInternalServerError)
		return
	}

	accessToken, err = h.refreshStravaTokenIfNeeded(accessToken, expiresAt, athleteID)
	if err != nil {
		log.Printf("[ERROR] Refresh Strava token failed: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"token refresh failed: %v"}`, err), http.StatusBadGateway)
		return
	}

	activities, err := h.fetchStravaActivities(accessToken)
	if err != nil {
		log.Printf("[ERROR] Fetch Strava activities failed: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"activity fetch failed: %v"}`, err), http.StatusBadGateway)
		return
	}

	imported := 0
	for _, activity := range activities {
		workout, err := stravaActivityToWorkout(activity)
		if err != nil {
			log.Printf("[WARN] Skipping Strava activity %d: %v", activity.ID, err)
			continue
		}
		if err := h.store.SaveWorkout(workout); err != nil {
			log.Printf("[ERROR] Save Strava workout failed: activity=%d err=%v", activity.ID, err)
			http.Error(w, fmt.Sprintf(`{"error":"failed to save activity %d: %v"}`, activity.ID, err), http.StatusInternalServerError)
			return
		}
		imported++
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"imported":   imported,
		"activities": len(activities),
	})
}

func (h *Handlers) stravaRedirectURI() string {
	return strings.TrimRight(h.apiBaseURL(), "/") + "/auth/strava/callback"
}

func (h *Handlers) stravaSuccessURL() string {
	return strings.TrimRight(h.apiBaseURL(), "/") + "/auth/strava/success"
}

func (h *Handlers) apiBaseURL() string {
	if value := os.Getenv("API_BASE_URL"); value != "" {
		return value
	}
	if value := os.Getenv("BASE_URL"); value != "" {
		return value
	}
	return "http://localhost:8080"
}

func (h *Handlers) stravaTokenRequest(values url.Values) (*stravaTokenResponse, error) {
	req, err := http.NewRequest(http.MethodPost, "https://www.strava.com/oauth/token", bytes.NewBufferString(values.Encode()))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("status %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	var tokenResp stravaTokenResponse
	if err := json.Unmarshal(body, &tokenResp); err != nil {
		return nil, err
	}

	return &tokenResp, nil
}

func (h *Handlers) refreshStravaTokenIfNeeded(accessToken string, expiresAt int64, athleteID int64) (string, error) {
	if time.Now().Unix() < expiresAt-60 {
		return accessToken, nil
	}

	_, refreshToken, _, storedAthleteID, err := h.store.GetStravaTokens()
	if err != nil {
		return "", err
	}
	if athleteID == 0 {
		athleteID = storedAthleteID
	}

	clientID := os.Getenv("STRAVA_CLIENT_ID")
	clientSecret := os.Getenv("STRAVA_CLIENT_SECRET")
	if clientID == "" || clientSecret == "" {
		return "", fmt.Errorf("STRAVA_CLIENT_ID or STRAVA_CLIENT_SECRET not configured")
	}

	tokenResp, err := h.stravaTokenRequest(url.Values{
		"client_id":     {clientID},
		"client_secret": {clientSecret},
		"grant_type":    {"refresh_token"},
		"refresh_token": {refreshToken},
	})
	if err != nil {
		return "", err
	}

	if tokenResp.Athlete.ID == 0 {
		tokenResp.Athlete.ID = athleteID
	}

	if err := h.store.SaveStravaTokens(tokenResp.AccessToken, tokenResp.RefreshToken, tokenResp.ExpiresAt, tokenResp.Athlete.ID); err != nil {
		return "", err
	}

	return tokenResp.AccessToken, nil
}

func (h *Handlers) fetchStravaActivities(accessToken string) ([]stravaActivity, error) {
	req, err := http.NewRequest(http.MethodGet, "https://www.strava.com/api/v3/athlete/activities?per_page=30", nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)

	client := &http.Client{Timeout: 20 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("status %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	var activities []stravaActivity
	if err := json.Unmarshal(body, &activities); err != nil {
		return nil, err
	}

	return activities, nil
}

func stravaActivityToWorkout(activity stravaActivity) (*models.Workout, error) {
	startTime, err := time.Parse(time.RFC3339, activity.StartDate)
	if err != nil {
		return nil, err
	}

	sourceID := strconv.FormatInt(activity.ID, 10)
	rawData, err := json.Marshal(activity)
	if err != nil {
		return nil, err
	}
	stravaData := string(rawData)

	workoutType := mapStravaWorkoutType(activity.Type)
	durationSeconds := activity.MovingTime
	distanceMeters := activity.Distance
	var heartRateAvg *int
	if activity.AverageHeartrate != nil {
		value := int(*activity.AverageHeartrate)
		heartRateAvg = &value
	}
	var heartRateMax *int
	if activity.MaxHeartrate != nil {
		value := int(*activity.MaxHeartrate)
		heartRateMax = &value
	}
	var calories *int
	if activity.Calories != nil {
		value := int(*activity.Calories)
		calories = &value
	}
	var notes *string
	if activity.Name != "" {
		notes = &activity.Name
	}

	return &models.Workout{
		Type:            workoutType,
		Date:            startTime.UnixMilli(),
		DurationSeconds: &durationSeconds,
		DistanceMeters:  &distanceMeters,
		Calories:        calories,
		HeartRateAvg:    heartRateAvg,
		HeartRateMax:    heartRateMax,
		Notes:           notes,
		Source:          "strava",
		SourceID:        &sourceID,
		StravaData:      &stravaData,
	}, nil
}

func mapStravaWorkoutType(value string) string {
	switch strings.ToLower(value) {
	case "run", "trailrun", "virtualrun":
		return "run"
	case "ride", "virtualride", "ebikeride", "mountainbikeride", "gravelride":
		return "cycle"
	case "walk":
		return "walk"
	case "hike":
		return "hiking"
	case "swim":
		return "swim"
	case "workout", "weighttraining":
		return "gym"
	default:
		return "other"
	}
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

func (h *Handlers) screenTimeHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		h.screenTimeByDate(w, r)
	case http.MethodPost:
		h.saveScreenTime(w, r)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handlers) screenTimeByDate(w http.ResponseWriter, r *http.Request) {
	dateStr := r.URL.Query().Get("date")
	if dateStr == "" {
		http.Error(w, `{"error":"date parameter required (YYYY-MM-DD)"}`, http.StatusBadRequest)
		return
	}

	screenTime, apps, err := h.store.GetScreenTimeByDate(dateStr)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"screenTime": screenTime,
		"apps":       apps,
	}

	json.NewEncoder(w).Encode(response)
}

func (h *Handlers) saveScreenTime(w http.ResponseWriter, r *http.Request) {
	var payload struct {
		Date    int64                  `json:"date"`
		TotalMs int64                  `json:"totalMs"`
		Pickups *int                   `json:"pickups,omitempty"`
		Apps    []models.ScreenTimeApp `json:"apps"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		log.Printf("[ERROR] Invalid JSON: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	if payload.Date <= 0 {
		http.Error(w, `{"error":"invalid screen time: date required"}`, http.StatusBadRequest)
		return
	}

	screenTime := models.ScreenTime{
		Date:    payload.Date,
		TotalMs: payload.TotalMs,
		Pickups: payload.Pickups,
	}

	if err := h.store.UpsertScreenTime(&screenTime, payload.Apps); err != nil {
		log.Printf("[ERROR] Save screen time failed: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"save error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Screen time saved: id=%d date=%s", screenTime.ID, models.DateFromMillis(screenTime.Date))
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"screenTime": screenTime,
		"apps":       payload.Apps,
	})
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

func (h *Handlers) recentScreenTime(w http.ResponseWriter, r *http.Request) {
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

	entries, err := h.store.GetRecentScreenTime(days)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(entries)
}

func (h *Handlers) screenTimeStats(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	days := 30
	if d := r.URL.Query().Get("days"); d != "" {
		if parsed, err := strconv.Atoi(d); err == nil && parsed > 0 {
			days = parsed
		}
	}

	avgDailyMs, totalPickups, topApps, err := h.store.GetScreenTimeStats(days)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"avgDailyMs":   avgDailyMs,
		"totalPickups": totalPickups,
		"topApps":      topApps,
	})
}

// --- Sync Operations ---

func (h *Handlers) bodyMetricsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		h.getBodyMetrics(w, r)
	case http.MethodPost:
		h.saveBodyMetric(w, r)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handlers) getBodyMetrics(w http.ResponseWriter, r *http.Request) {
	dateStr := r.URL.Query().Get("date")
	if dateStr == "" {
		http.Error(w, `{"error":"date parameter required (YYYY-MM-DD)"}`, http.StatusBadRequest)
		return
	}

	metrics, err := h.store.GetBodyMetricByDate(dateStr)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(metrics)
}

func (h *Handlers) saveBodyMetric(w http.ResponseWriter, r *http.Request) {
	var m models.BodyMetric
	if err := json.NewDecoder(r.Body).Decode(&m); err != nil {
		log.Printf("[ERROR] Invalid JSON: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	if !m.Validate() {
		log.Printf("[WARN] Invalid body metric: date=%d", m.Date)
		http.Error(w, `{"error":"invalid body metric: date required"}`, http.StatusBadRequest)
		return
	}

	if err := h.store.SaveBodyMetric(&m); err != nil {
		log.Printf("[ERROR] Save body metric failed: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"save error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Body metric saved: id=%d date=%s", m.ID, models.DateFromMillis(m.Date))
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(m)
}

func (h *Handlers) recentBodyMetrics(w http.ResponseWriter, r *http.Request) {
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

	metrics, err := h.store.GetRecentBodyMetrics(days)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(metrics)
}

func (h *Handlers) mealByID(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Extract ID from path: /meals/{id}
	pathParts := strings.Split(strings.TrimPrefix(r.URL.Path, "/meals/"), "/")
	if len(pathParts) == 0 || pathParts[0] == "" {
		http.Error(w, `{"error":"meal ID required"}`, http.StatusBadRequest)
		return
	}

	id, err := strconv.ParseInt(pathParts[0], 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid meal ID"}`, http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodGet:
		h.getMealByID(w, r, id)
	case http.MethodPut:
		h.updateMeal(w, r, id)
	case http.MethodDelete:
		h.deleteMeal(w, r, id)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handlers) bodyMetricByID(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Extract ID from path: /body-metrics/{id}
	pathParts := strings.Split(strings.TrimPrefix(r.URL.Path, "/body-metrics/"), "/")
	if len(pathParts) == 0 || pathParts[0] == "" {
		http.Error(w, `{"error":"body metric ID required"}`, http.StatusBadRequest)
		return
	}

	id, err := strconv.ParseInt(pathParts[0], 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid body metric ID"}`, http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodGet:
		h.getBodyMetricByID(w, r, id)
	case http.MethodPut:
		h.updateBodyMetric(w, r, id)
	case http.MethodDelete:
		h.deleteBodyMetric(w, r, id)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handlers) getMealByID(w http.ResponseWriter, r *http.Request, id int64) {
	meal, err := h.store.GetMealByID(id)
	if err != nil {
		log.Printf("[ERROR] Get meal by ID failed: id=%d err=%v", id, err)
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	if meal == nil {
		http.Error(w, `{"error":"meal not found"}`, http.StatusNotFound)
		return
	}

	log.Printf("[INFO] Get meal by ID: id=%d", id)
	json.NewEncoder(w).Encode(meal)
}

func (h *Handlers) getBodyMetricByID(w http.ResponseWriter, r *http.Request, id int64) {
	metric, err := h.store.GetBodyMetricByID(id)
	if err != nil {
		log.Printf("[ERROR] Get body metric by ID failed: id=%d err=%v", id, err)
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	if metric == nil {
		http.Error(w, `{"error":"body metric not found"}`, http.StatusNotFound)
		return
	}

	log.Printf("[INFO] Get body metric by ID: id=%d", id)
	json.NewEncoder(w).Encode(metric)
}

func (h *Handlers) updateMeal(w http.ResponseWriter, r *http.Request, id int64) {
	var m models.Meal
	if err := json.NewDecoder(r.Body).Decode(&m); err != nil {
		log.Printf("[ERROR] Invalid JSON: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	m.ID = id
	if !m.Validate() {
		log.Printf("[WARN] Invalid meal update: id=%d slot=%s date=%d", id, m.Slot, m.Date)
		http.Error(w, `{"error":"invalid meal: slot must be breakfast/lunch/afternoonSnack/dinner, date required"}`, http.StatusBadRequest)
		return
	}

	if err := h.store.UpdateMeal(&m); err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, `{"error":"meal not found"}`, http.StatusNotFound)
			return
		}
		log.Printf("[ERROR] Update meal failed: id=%d err=%v", id, err)
		http.Error(w, fmt.Sprintf(`{"error":"update error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Meal updated: id=%d slot=%s date=%s", id, m.Slot, models.DateFromMillis(m.Date))
	json.NewEncoder(w).Encode(m)
}

func (h *Handlers) deleteMeal(w http.ResponseWriter, r *http.Request, id int64) {
	if err := h.store.SoftDeleteMeal(id); err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, `{"error":"meal not found"}`, http.StatusNotFound)
			return
		}
		log.Printf("[ERROR] Delete meal failed: id=%d err=%v", id, err)
		http.Error(w, fmt.Sprintf(`{"error":"delete error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Meal soft deleted: id=%d", id)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) updateBodyMetric(w http.ResponseWriter, r *http.Request, id int64) {
	var m models.BodyMetric
	if err := json.NewDecoder(r.Body).Decode(&m); err != nil {
		log.Printf("[ERROR] Invalid JSON: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	m.ID = id
	if !m.Validate() {
		log.Printf("[WARN] Invalid body metric update: id=%d date=%d", id, m.Date)
		http.Error(w, `{"error":"invalid body metric: date required"}`, http.StatusBadRequest)
		return
	}

	if err := h.store.UpdateBodyMetric(&m); err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, `{"error":"body metric not found"}`, http.StatusNotFound)
			return
		}
		log.Printf("[ERROR] Update body metric failed: id=%d err=%v", id, err)
		http.Error(w, fmt.Sprintf(`{"error":"update error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Body metric updated: id=%d date=%s", id, models.DateFromMillis(m.Date))
	json.NewEncoder(w).Encode(m)
}

func (h *Handlers) deleteBodyMetric(w http.ResponseWriter, r *http.Request, id int64) {
	if err := h.store.SoftDeleteBodyMetric(id); err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, `{"error":"body metric not found"}`, http.StatusNotFound)
			return
		}
		log.Printf("[ERROR] Delete body metric failed: id=%d err=%v", id, err)
		http.Error(w, fmt.Sprintf(`{"error":"delete error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Body metric soft deleted: id=%d", id)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) mealsSince(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	timestampStr := r.URL.Query().Get("timestamp")
	if timestampStr == "" {
		http.Error(w, `{"error":"timestamp parameter required (epoch millis)"}`, http.StatusBadRequest)
		return
	}

	timestamp, err := strconv.ParseInt(timestampStr, 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid timestamp"}`, http.StatusBadRequest)
		return
	}

	meals, deletedIDs, err := h.store.GetMealsSince(timestamp)
	if err != nil {
		log.Printf("[ERROR] Get meals since failed: timestamp=%d err=%v", timestamp, err)
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	// Find the latest timestamp
	var latestTimestamp int64
	for _, m := range meals {
		if m.UpdatedAt > latestTimestamp {
			latestTimestamp = m.UpdatedAt
		}
	}

	response := map[string]interface{}{
		"meals":      meals,
		"deletedIds": deletedIDs,
		"timestamp":  latestTimestamp,
	}

	log.Printf("[INFO] Sync since %d: %d meals, %d deleted", timestamp, len(meals), len(deletedIDs))
	json.NewEncoder(w).Encode(response)
}

func (h *Handlers) bodyMetricsSince(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	timestampStr := r.URL.Query().Get("timestamp")
	if timestampStr == "" {
		http.Error(w, `{"error":"timestamp parameter required (epoch millis)"}`, http.StatusBadRequest)
		return
	}

	timestamp, err := strconv.ParseInt(timestampStr, 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid timestamp"}`, http.StatusBadRequest)
		return
	}

	metrics, deletedIDs, err := h.store.GetBodyMetricsSince(timestamp)
	if err != nil {
		log.Printf("[ERROR] Get body metrics since failed: timestamp=%d err=%v", timestamp, err)
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	var latestTimestamp int64
	for _, m := range metrics {
		if m.UpdatedAt > latestTimestamp {
			latestTimestamp = m.UpdatedAt
		}
	}

	response := map[string]interface{}{
		"bodyMetrics": metrics,
		"deletedIds":  deletedIDs,
		"timestamp":   latestTimestamp,
	}

	log.Printf("[INFO] Sync since %d: %d body metrics, %d deleted", timestamp, len(metrics), len(deletedIDs))
	json.NewEncoder(w).Encode(response)
}

func (h *Handlers) bulkMeals(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	var meals []models.Meal
	if err := json.NewDecoder(r.Body).Decode(&meals); err != nil {
		log.Printf("[ERROR] Invalid JSON: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	if len(meals) == 0 {
		http.Error(w, `{"error":"no meals provided"}`, http.StatusBadRequest)
		return
	}

	// Validate all meals
	for i, m := range meals {
		if !m.Validate() {
			log.Printf("[WARN] Invalid meal in bulk at index %d: slot=%s date=%d", i, m.Slot, m.Date)
			http.Error(w, fmt.Sprintf(`{"error":"invalid meal at index %d"}`, i), http.StatusBadRequest)
			return
		}
	}

	results, err := h.store.BulkSaveMeals(meals)
	if err != nil {
		log.Printf("[ERROR] Bulk save meals failed: err=%v", err)
		http.Error(w, fmt.Sprintf(`{"error":"bulk save error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Bulk saved %d meals", len(results))
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(results)
}

// --- Workouts ---

func (h *Handlers) workoutsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		h.getWorkouts(w, r)
	case http.MethodPost:
		h.saveWorkout(w, r)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handlers) getWorkouts(w http.ResponseWriter, r *http.Request) {
	dateStr := r.URL.Query().Get("date")
	if dateStr == "" {
		http.Error(w, `{"error":"date parameter required (YYYY-MM-DD)"}`, http.StatusBadRequest)
		return
	}

	workouts, err := h.store.GetWorkoutsByDate(dateStr)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(workouts)
}

func (h *Handlers) saveWorkout(w http.ResponseWriter, r *http.Request) {
	var m models.Workout
	if err := json.NewDecoder(r.Body).Decode(&m); err != nil {
		log.Printf("[ERROR] Invalid JSON: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	if !m.Validate() {
		log.Printf("[WARN] Invalid workout: type=%s date=%d", m.Type, m.Date)
		http.Error(w, `{"error":"invalid workout: type must be run/cycle/gym/swim/walk/hiking/other, date required"}`, http.StatusBadRequest)
		return
	}

	if err := h.store.SaveWorkout(&m); err != nil {
		log.Printf("[ERROR] Save workout failed: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"save error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Workout saved: id=%d type=%s date=%s", m.ID, m.Type, models.DateFromMillis(m.Date))
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(m)
}

func (h *Handlers) recentWorkouts(w http.ResponseWriter, r *http.Request) {
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

	workouts, err := h.store.GetRecentWorkouts(days)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(workouts)
}

func (h *Handlers) workoutStats(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	days := 30
	if d := r.URL.Query().Get("days"); d != "" {
		if parsed, err := strconv.Atoi(d); err == nil && parsed > 0 {
			days = parsed
		}
	}

	stats, err := h.store.GetWorkoutStats(days)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(stats)
}

func (h *Handlers) workoutByID(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Extract ID from path: /workouts/{id}
	pathParts := strings.Split(strings.TrimPrefix(r.URL.Path, "/workouts/"), "/")
	if len(pathParts) == 0 || pathParts[0] == "" {
		http.Error(w, `{"error":"workout ID required"}`, http.StatusBadRequest)
		return
	}

	id, err := strconv.ParseInt(pathParts[0], 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid workout ID"}`, http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodGet:
		h.getWorkoutByID(w, r, id)
	case http.MethodPut:
		h.updateWorkout(w, r, id)
	case http.MethodDelete:
		h.deleteWorkout(w, r, id)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handlers) getWorkoutByID(w http.ResponseWriter, r *http.Request, id int64) {
	workout, err := h.store.GetWorkoutByID(id)
	if err != nil {
		log.Printf("[ERROR] Get workout by ID failed: id=%d err=%v", id, err)
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	if workout == nil {
		http.Error(w, `{"error":"workout not found"}`, http.StatusNotFound)
		return
	}

	log.Printf("[INFO] Get workout by ID: id=%d", id)
	json.NewEncoder(w).Encode(workout)
}

func (h *Handlers) updateWorkout(w http.ResponseWriter, r *http.Request, id int64) {
	var m models.Workout
	if err := json.NewDecoder(r.Body).Decode(&m); err != nil {
		log.Printf("[ERROR] Invalid JSON: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	m.ID = id
	if !m.Validate() {
		log.Printf("[WARN] Invalid workout update: id=%d type=%s date=%d", id, m.Type, m.Date)
		http.Error(w, `{"error":"invalid workout: type must be run/cycle/gym/swim/walk/hiking/other, date required"}`, http.StatusBadRequest)
		return
	}

	if err := h.store.UpdateWorkout(&m); err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, `{"error":"workout not found"}`, http.StatusNotFound)
			return
		}
		log.Printf("[ERROR] Update workout failed: id=%d err=%v", id, err)
		http.Error(w, fmt.Sprintf(`{"error":"update error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Workout updated: id=%d type=%s date=%s", id, m.Type, models.DateFromMillis(m.Date))
	json.NewEncoder(w).Encode(m)
}

func (h *Handlers) deleteWorkout(w http.ResponseWriter, r *http.Request, id int64) {
	if err := h.store.SoftDeleteWorkout(id); err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, `{"error":"workout not found"}`, http.StatusNotFound)
			return
		}
		log.Printf("[ERROR] Delete workout failed: id=%d err=%v", id, err)
		http.Error(w, fmt.Sprintf(`{"error":"delete error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	log.Printf("[INFO] Workout soft deleted: id=%d", id)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handlers) workoutsSince(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	timestampStr := r.URL.Query().Get("timestamp")
	if timestampStr == "" {
		http.Error(w, `{"error":"timestamp parameter required (epoch millis)"}`, http.StatusBadRequest)
		return
	}

	timestamp, err := strconv.ParseInt(timestampStr, 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid timestamp"}`, http.StatusBadRequest)
		return
	}

	workouts, deletedIDs, err := h.store.GetWorkoutsSince(timestamp)
	if err != nil {
		log.Printf("[ERROR] Get workouts since failed: timestamp=%d err=%v", timestamp, err)
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	// Find the latest timestamp
	var latestTimestamp int64
	for _, m := range workouts {
		if m.UpdatedAt > latestTimestamp {
			latestTimestamp = m.UpdatedAt
		}
	}

	response := map[string]interface{}{
		"workouts":   workouts,
		"deletedIds": deletedIDs,
		"timestamp":  latestTimestamp,
	}

	log.Printf("[INFO] Sync since %d: %d workouts, %d deleted", timestamp, len(workouts), len(deletedIDs))
	json.NewEncoder(w).Encode(response)
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

// --- Daily Checkins ---

func (h *Handlers) checkinHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		h.getCheckin(w, r)
	case http.MethodPost:
		h.saveCheckin(w, r)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handlers) getCheckin(w http.ResponseWriter, r *http.Request) {
	dateStr := r.URL.Query().Get("date")
	if dateStr == "" {
		http.Error(w, `{"error":"date parameter required (YYYY-MM-DD)"}`, http.StatusBadRequest)
		return
	}

	checkin, err := h.store.GetCheckinByDate(dateStr)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	if checkin == nil {
		json.NewEncoder(w).Encode(nil)
		return
	}

	json.NewEncoder(w).Encode(checkin)
}

func (h *Handlers) saveCheckin(w http.ResponseWriter, r *http.Request) {
	var checkin models.DailyCheckin
	if err := json.NewDecoder(r.Body).Decode(&checkin); err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	if checkin.Date <= 0 {
		http.Error(w, `{"error":"invalid checkin: date required"}`, http.StatusBadRequest)
		return
	}

	if err := h.store.SaveCheckin(&checkin); err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"save error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(checkin)
}

func (h *Handlers) recentCheckins(w http.ResponseWriter, r *http.Request) {
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

	checkins, err := h.store.GetRecentCheckins(days)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(checkins)
}

// --- Hydration ---

func (h *Handlers) hydrationHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		h.getHydration(w, r)
	case http.MethodPost:
		h.saveHydration(w, r)
	default:
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
	}
}

func (h *Handlers) getHydration(w http.ResponseWriter, r *http.Request) {
	dateStr := r.URL.Query().Get("date")
	if dateStr == "" {
		http.Error(w, `{"error":"date parameter required (YYYY-MM-DD)"}`, http.StatusBadRequest)
		return
	}

	entries, err := h.store.GetHydrationByDate(dateStr)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(entries)
}

func (h *Handlers) saveHydration(w http.ResponseWriter, r *http.Request) {
	var hydration models.Hydration
	if err := json.NewDecoder(r.Body).Decode(&hydration); err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"invalid JSON: %v"}`, err), http.StatusBadRequest)
		return
	}

	if hydration.Date <= 0 || hydration.AmountMl <= 0 {
		http.Error(w, `{"error":"invalid hydration: date and amountMl required"}`, http.StatusBadRequest)
		return
	}

	if err := h.store.SaveHydration(&hydration); err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"save error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(hydration)
}

func (h *Handlers) recentHydration(w http.ResponseWriter, r *http.Request) {
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

	entries, err := h.store.GetRecentHydration(days)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"database error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(entries)
}

func (h *Handlers) deleteHydration(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodDelete {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	pathParts := strings.Split(strings.TrimPrefix(r.URL.Path, "/hydration/"), "/")
	if len(pathParts) == 0 || pathParts[0] == "" {
		http.Error(w, `{"error":"hydration ID required"}`, http.StatusBadRequest)
		return
	}

	id, err := strconv.ParseInt(pathParts[0], 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid hydration ID"}`, http.StatusBadRequest)
		return
	}

	if err := h.store.DeleteHydration(id); err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, `{"error":"hydration not found"}`, http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf(`{"error":"delete error: %v"}`, err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
