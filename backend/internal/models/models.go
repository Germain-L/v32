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
	ID        int64  `json:"id,omitempty"`
	MealID    int64  `json:"mealId"`
	Filename  string `json:"filename"`
	URL       string `json:"url,omitempty"`
}

type DayRating struct {
	Date  int64 `json:"date"` // epoch day (date only, no time)
	Score int   `json:"score"`
}

type Stats struct {
	TotalMeals    int            `json:"totalMeals"`
	MealsBySlot   map[string]int `json:"mealsBySlot"`
	CurrentStreak int            `json:"currentStreak"`
	DaysLogged    int            `json:"daysLogged"`
	AvgRating     float64        `json:"avgRating"`
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

func (m *Meal) Validate() bool {
	return ValidSlots[m.Slot] && m.Date > 0
}

func (r *DayRating) Validate() bool {
	return r.Score >= 1 && r.Score <= 5
}

// Helper to get date string from epoch millis
func DateFromMillis(millis int64) string {
	return time.UnixMilli(millis).UTC().Format("2006-01-02")
}
