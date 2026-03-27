package models

import "time"

type Meal struct {
	ID          int64       `json:"id,omitempty"`
	Slot        string      `json:"slot"`
	Date        int64       `json:"date"` // milliseconds since epoch
	Description *string     `json:"description,omitempty"`
	Images      []MealImage `json:"images,omitempty"`
	UpdatedAt   int64       `json:"updatedAt"`
	DeletedAt   *int64      `json:"deletedAt,omitempty"`
	ServerID    int64       `json:"serverId,omitempty"` // Original ID before migration
}

type MealImage struct {
	ID       int64  `json:"id,omitempty"`
	MealID   int64  `json:"mealId"`
	Filename string `json:"filename"`
	URL      string `json:"url,omitempty"`
}

type BodyMetric struct {
	ID        int64    `json:"id,omitempty"`
	Date      int64    `json:"date"`
	Weight    *float64 `json:"weight,omitempty"`
	BodyFat   *float64 `json:"bodyFat,omitempty"`
	Notes     *string  `json:"notes,omitempty"`
	CreatedAt int64    `json:"createdAt"`
	UpdatedAt int64    `json:"updatedAt"`
	DeletedAt *int64   `json:"deletedAt,omitempty"`
}

type Hydration struct {
	ID        int64 `json:"id,omitempty"`
	Date      int64 `json:"date"`
	AmountMl  int   `json:"amountMl"`
	CreatedAt int64 `json:"createdAt"`
}

type Workout struct {
	ID              int64    `json:"id,omitempty"`
	Type            string   `json:"type"`
	Date            int64    `json:"date"`
	DurationSeconds *int     `json:"durationSeconds,omitempty"`
	DistanceMeters  *float64 `json:"distanceMeters,omitempty"`
	Calories        *int     `json:"calories,omitempty"`
	HeartRateAvg    *int     `json:"heartRateAvg,omitempty"`
	HeartRateMax    *int     `json:"heartRateMax,omitempty"`
	Notes           *string  `json:"notes,omitempty"`
	Source          string   `json:"source"`
	SourceID        *string  `json:"sourceId,omitempty"`
	StravaData      *string  `json:"stravaData,omitempty"`
	CreatedAt       int64    `json:"createdAt"`
	UpdatedAt       int64    `json:"updatedAt"`
	DeletedAt       *int64   `json:"deletedAt,omitempty"`
}

type ScreenTime struct {
	ID        int64 `json:"id,omitempty"`
	Date      int64 `json:"date"`
	TotalMs   int64 `json:"totalMs"`
	Pickups   *int  `json:"pickups,omitempty"`
	CreatedAt int64 `json:"createdAt"`
}

type ScreenTimeApp struct {
	ID           int64  `json:"id,omitempty"`
	ScreenTimeID int64  `json:"screenTimeId"`
	PackageName  string `json:"packageName"`
	AppName      string `json:"appName"`
	DurationMs   int64  `json:"durationMs"`
}

type DailyCheckin struct {
	ID           int64    `json:"id,omitempty"`
	Date         int64    `json:"date"` // epoch day (date only, no time)
	Mood         *int     `json:"mood,omitempty"`
	Energy       *int     `json:"energy,omitempty"`
	Focus        *int     `json:"focus,omitempty"`
	Stress       *int     `json:"stress,omitempty"`
	SleepHours   *float64 `json:"sleepHours,omitempty"`
	SleepQuality *int     `json:"sleepQuality,omitempty"`
	Notes        *string  `json:"notes,omitempty"`
	CreatedAt    int64    `json:"createdAt"`
	UpdatedAt    int64    `json:"updatedAt"`
}

type DayRating struct {
	Date  int64 `json:"date"` // epoch day (date only, no time)
	Score int   `json:"score"`
}

type Stats struct {
	TotalMeals           int            `json:"totalMeals"`
	MealsBySlot          map[string]int `json:"mealsBySlot"`
	CurrentStreak        int            `json:"currentStreak"`
	DaysLogged           int            `json:"daysLogged"`
	AvgRating            float64        `json:"avgRating"`
	LatestWeight         *float64       `json:"latestWeight"`
	WeightTrend          string         `json:"weightTrend"`
	WorkoutsThisWeek     int            `json:"workoutsThisWeek"`
	WorkoutsThisMonth    int            `json:"workoutsThisMonth"`
	AvgDailyScreenTimeMs int64          `json:"avgDailyScreenTimeMs"`
	AvgMood              float64        `json:"avgMood"`
	AvgEnergy            float64        `json:"avgEnergy"`
	AvgSleepHours        float64        `json:"avgSleepHours"`
	AvgHydrationMl       float64        `json:"avgHydrationMl"`
}

type ErrorResponse struct {
	Error string `json:"error"`
}

var ValidSlots = map[string]bool{
	"breakfast":      true,
	"lunch":          true,
	"afternoonSnack": true,
	"dinner":         true,
}

var ValidWorkoutTypes = map[string]bool{
	"run":    true,
	"cycle":  true,
	"gym":    true,
	"swim":   true,
	"walk":   true,
	"hiking": true,
	"other":  true,
}

func (m *Meal) Validate() bool {
	return ValidSlots[m.Slot] && m.Date > 0
}

func (m *BodyMetric) Validate() bool {
	return m.Date > 0
}

func (m *Workout) Validate() bool {
	return ValidWorkoutTypes[m.Type] && m.Date > 0
}

func (r *DayRating) Validate() bool {
	return r.Score >= 1 && r.Score <= 5
}

// Helper to get date string from epoch millis
func DateFromMillis(millis int64) string {
	return time.UnixMilli(millis).UTC().Format("2006-01-02")
}
