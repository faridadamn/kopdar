package models

import (
	"time"

	"github.com/google/uuid"
)

// Savings statuses
const (
	SavingsStatusActive  = "active"
	SavingsStatusPaused  = "paused"
	SavingsStatusReached = "reached"
	SavingsStatusClosed  = "closed"
)

// Savings transaction types
const (
	SavingsTxnTypeDeposit    = "deposit"
	SavingsTxnTypeWithdrawal = "withdrawal"
)

// Savings transaction methods
const (
	SavingsTxnMethodAuto   = "auto"
	SavingsTxnMethodManual = "manual"
)

// Savings represents a driver's savings goal
type Savings struct {
	ID            uuid.UUID  `json:"id" db:"id"`
	DriverID      uuid.UUID  `json:"driver_id" db:"driver_id"`
	GoalName      string     `json:"goal_name" db:"goal_name"`
	GoalIcon      string     `json:"goal_icon" db:"goal_icon"`
	TargetAmount  float64    `json:"target_amount" db:"target_amount"`
	CurrentAmount float64    `json:"current_amount" db:"current_amount"`
	DailyAmount   float64    `json:"daily_amount" db:"daily_amount"`
	AutoSave      bool       `json:"auto_save" db:"auto_save"`
	Status        string     `json:"status" db:"status"`
	CreatedAt     time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at" db:"updated_at"`
}

// SavingsTransaction represents a deposit or withdrawal
type SavingsTransaction struct {
	ID        uuid.UUID `json:"id" db:"id"`
	SavingsID uuid.UUID `json:"savings_id" db:"savings_id"`
	Type      string    `json:"type" db:"type"`
	Amount    float64   `json:"amount" db:"amount"`
	Method    string    `json:"method" db:"method"`
	Status    string    `json:"status" db:"status"`
	Notes     *string   `json:"notes,omitempty" db:"notes"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// SavingsGoalDetail is the response for a single savings goal with computed fields
type SavingsGoalDetail struct {
	Savings
	ProgressPercent   int                 `json:"progress_percent"`
	EstimatedDays     int                 `json:"estimated_days"`
	RecentTxns        []SavingsTransaction `json:"recent_transactions,omitempty"`
	TransactionCount  int                 `json:"transaction_count,omitempty"`
	Transactions      []SavingsTransaction `json:"transactions,omitempty"`
}

// SavingsListResponse is the response for listing all savings goals
type SavingsListResponse struct {
	TotalSaved  float64              `json:"total_saved"`
	TotalTarget float64              `json:"total_target"`
	Goals       []SavingsGoalDetail  `json:"goals"`
}

// Request DTOs

type SavingsCreateRequest struct {
	GoalName    string  `json:"goal_name" binding:"required"`
	GoalIcon    string  `json:"goal_icon" binding:"required"`
	TargetAmount float64 `json:"target_amount" binding:"required,gt=0"`
	DailyAmount  float64 `json:"daily_amount" binding:"required,gt=0"`
	AutoSave    bool    `json:"auto_save"`
}

type SavingsUpdateRequest struct {
	DailyAmount  *float64 `json:"daily_amount"`
	AutoSave     *bool    `json:"auto_save"`
	TargetAmount *float64 `json:"target_amount"`
}

type SavingsDepositRequest struct {
	Amount float64 `json:"amount" binding:"required,gt=0"`
}

type SavingsWithdrawRequest struct {
	Amount float64 `json:"amount" binding:"required,gt=0"`
	Notes  string  `json:"notes"`
}
