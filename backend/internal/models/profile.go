package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// Driver level constants
const (
	LevelBronze   = "bronze"
	LevelSilver   = "silver"
	LevelGold     = "gold"
	LevelPlatinum = "platinum"
)

// Level thresholds
var LevelThresholds = map[string]int{
	LevelBronze:   0,
	LevelSilver:   1000,
	LevelGold:     5000,
	LevelPlatinum: 20000,
}

// Level order for progression
var LevelOrder = []string{LevelBronze, LevelSilver, LevelGold, LevelPlatinum}

// Point values per action
var PointValues = map[string]int{
	"login_harian":      5,
	"input_income":      10,
	"input_expense":     5,
	"post_community":    10,
	"comment_community": 3,
	"referral_success":  100,
	"auto_save":         5,
	"insurance_active":  50,
}

// Benefits per level
var LevelBenefits = map[string][]string{
	LevelBronze:   {"Kartu anggota", "Forum komunitas"},
	LevelSilver:   {"Prioritas support", "Diskon asuransi 10%"},
	LevelGold:     {"Akses fitur beta", "Diskon asuransi 20%"},
	LevelPlatinum: {"VIP support", "Diskon asuransi 30%", "Cashback referral 2x"},
}

// DriverPoints tracks a driver's points and level
type DriverPoints struct {
	ID        uuid.UUID `json:"id" db:"id"`
	DriverID  uuid.UUID `json:"driver_id" db:"driver_id"`
	Points    int       `json:"points" db:"points"`
	Level     string    `json:"level" db:"level"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// PointsHistory tracks individual point transactions
type PointsHistory struct {
	ID        uuid.UUID `json:"id" db:"id"`
	DriverID  uuid.UUID `json:"driver_id" db:"driver_id"`
	Action    string    `json:"action" db:"action"`
	Points    int       `json:"points" db:"points"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// DriverSettings stores driver preferences
type DriverSettings struct {
	ID                uuid.UUID       `json:"id" db:"id"`
	DriverID          uuid.UUID       `json:"driver_id" db:"driver_id"`
	Language          string          `json:"language" db:"language"`
	ZoneID            string          `json:"zone_id" db:"zone_id"`
	AutoSaveEnabled   bool            `json:"auto_save_enabled" db:"auto_save_enabled"`
	AutoSaveAmount    int             `json:"auto_save_amount" db:"auto_save_amount"`
	Notifications     Notifications   `json:"notifications" db:"notifications"`
	QuietHours        QuietHours      `json:"quiet_hours" db:"quiet_hours"`
	BiometricEnabled  bool            `json:"biometric_enabled" db:"biometric_enabled"`
	CreatedAt         time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time       `json:"updated_at" db:"updated_at"`
}

// Notifications settings
type Notifications struct {
	Community    bool `json:"community"`
	Savings      bool `json:"savings"`
	Insurance    bool `json:"insurance"`
	Advocacy     bool `json:"advocacy"`
	Promotions   bool `json:"promotions"`
}

// QuietHours settings
type QuietHours struct {
	Enabled bool   `json:"enabled"`
	Start   string `json:"start"`
	End     string `json:"end"`
}

// Referral tracks a referral relationship
type Referral struct {
	ID          uuid.UUID  `json:"id" db:"id"`
	ReferrerID  uuid.UUID  `json:"referrer_id" db:"referrer_id"`
	ReferredID  uuid.UUID  `json:"referred_id" db:"referred_id"`
	ReferralCode string   `json:"referral_code" db:"referral_code"`
	Bonus       float64    `json:"bonus" db:"bonus"`
	Status      string     `json:"status" db:"status"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
}

// Referral statuses
const (
	ReferralStatusPending   = "pending"
	ReferralStatusCompleted = "completed"
)

// ProfileStats holds aggregated stats for a driver
type ProfileStats struct {
	TotalOrders       int64   `json:"total_orders"`
	TotalEarnings     float64 `json:"total_earnings"`
	ActiveDays        int     `json:"active_days"`
	Rating            float64 `json:"rating"`
	Level             string  `json:"level"`
	Points            int     `json:"points"`
	PointsToNextLevel int     `json:"points_to_next_level"`
	NextLevel         string  `json:"next_level"`
	MemberSince       string  `json:"member_since"`
	ReferralCode      string  `json:"referral_code"`
}

// MembershipCard holds membership card data
type MembershipCard struct {
	ID          string `json:"id"`
	QRData      string `json:"qr_data"`
	Level       string `json:"level"`
	MemberSince string `json:"member_since"`
}

// ProfileResponse is the full profile response
type ProfileResponse struct {
	Driver         Driver          `json:"driver"`
	User           User            `json:"user"`
	Platforms      []DriverPlatform `json:"platforms"`
	Stats          ProfileStats    `json:"stats"`
	MembershipCard MembershipCard  `json:"membership_card"`
}

// LevelInfoResponse is the level info response
type LevelInfoResponse struct {
	CurrentLevel  string              `json:"current_level"`
	Points        int                 `json:"points"`
	PointsHistory []PointsHistoryItem `json:"points_history"`
	NextLevel     string              `json:"next_level"`
	PointsNeeded  int                 `json:"points_needed"`
	Benefits      map[string][]string `json:"benefits"`
}

// PointsHistoryItem is a single points history entry for the API
type PointsHistoryItem struct {
	Action string `json:"action"`
	Points int    `json:"points"`
	Date   string `json:"date"`
}

// AddPointsRequest is the request body for adding points
type AddPointsRequest struct {
	Action string `json:"action" binding:"required"`
}

// AddPointsResponse is the response for adding points
type AddPointsResponse struct {
	PointsAdded int    `json:"points_added"`
	NewTotal    int    `json:"new_total"`
	NewLevel    string `json:"new_level"`
	LevelUp     bool   `json:"level_up"`
}

// ReferralInfoResponse is the referral info response
type ReferralInfoResponse struct {
	ReferralCode  string            `json:"referral_code"`
	ReferralLink  string            `json:"referral_link"`
	TotalReferrals int              `json:"total_referrals"`
	TotalBonus    float64           `json:"total_bonus"`
	Referrals     []ReferralDetail  `json:"referrals"`
}

// ReferralDetail is a single referral entry for the API
type ReferralDetail struct {
	ID     string  `json:"id"`
	Name   string  `json:"name"`
	Status string  `json:"status"`
	Bonus  float64 `json:"bonus"`
	Date   string  `json:"date"`
}

// ApplyReferralRequest is the request body for applying a referral code
type ApplyReferralRequest struct {
	ReferralCode string `json:"referral_code" binding:"required"`
}

// ShareContentResponse is the response for share content
type ShareContentResponse struct {
	Message     string `json:"message"`
	WhatsAppURL string `json:"whatsapp_url"`
	SMSURL      string `json:"sms_url"`
}

// SettingsUpdateRequest is a partial settings update
type SettingsUpdateRequest struct {
	Language         *string       `json:"language,omitempty"`
	ZoneID           *string       `json:"zone_id,omitempty"`
	AutoSaveEnabled  *bool         `json:"auto_save_enabled,omitempty"`
	AutoSaveAmount   *int          `json:"auto_save_amount,omitempty"`
	Notifications    *Notifications `json:"notifications,omitempty"`
	QuietHours       *QuietHours   `json:"quiet_hours,omitempty"`
	BiometricEnabled *bool         `json:"biometric_enabled,omitempty"`
}

// DeleteAccountRequest is the request body for account deletion
type DeleteAccountRequest struct {
	Reason string `json:"reason" binding:"required"`
}

// Scan helpers for JSONB fields
func (n *Notifications) Scan(src interface{}) error {
	if src == nil {
		return nil
	}
	bytes, ok := src.([]byte)
	if !ok {
		return nil
	}
	return json.Unmarshal(bytes, n)
}

func (n Notifications) Value() (interface{}, error) {
	return json.Marshal(n)
}

func (q *QuietHours) Scan(src interface{}) error {
	if src == nil {
		return nil
	}
	bytes, ok := src.([]byte)
	if !ok {
		return nil
	}
	return json.Unmarshal(bytes, q)
}

func (q QuietHours) Value() (interface{}, error) {
	return json.Marshal(q)
}
