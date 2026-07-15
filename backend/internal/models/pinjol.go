package models

import (
	"time"

	"github.com/google/uuid"
)

// Risk levels
const (
	RiskLevelSafe    = "safe"
	RiskLevelWarning = "warning"
	RiskLevelDanger  = "danger"
)

// PinjolRecord represents a loan record from a fintech platform
type PinjolRecord struct {
	ID                   uuid.UUID  `json:"id" db:"id"`
	DriverID             uuid.UUID  `json:"driver_id" db:"driver_id"`
	AppName              string     `json:"app_name" db:"app_name"`
	Principal            float64    `json:"principal" db:"principal"`
	InterestRate         float64    `json:"interest_rate" db:"interest_rate"`
	MonthlyInstallment   float64    `json:"monthly_installment" db:"monthly_installment"`
	OutstandingAmount    float64    `json:"outstanding_amount" db:"outstanding_amount"`
	TotalPaidInterest    float64    `json:"total_paid_interest" db:"total_paid_interest"`
	StartDate            string     `json:"start_date" db:"start_date"`
	EndDate              string     `json:"end_date" db:"end_date"`
	RiskLevel            string     `json:"risk_level" db:"risk_level"`
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at" db:"updated_at"`
}

// PinjolListResponse is the response for listing all pinjol records
type PinjolListResponse struct {
	TotalOutstanding      float64            `json:"total_outstanding"`
	TotalPaidInterest     float64            `json:"total_paid_interest"`
	TotalMonthlyInstall   float64            `json:"total_monthly_installment"`
	DebtToIncomeRatio     float64            `json:"debt_to_income_ratio"`
	RiskSummary           RiskSummary        `json:"risk_summary"`
	Records               []PinjolRecordDetail `json:"records"`
	Recommendations       []string           `json:"recommendations"`
}

// RiskSummary counts records by risk level
type RiskSummary struct {
	Safe    int `json:"safe"`
	Warning int `json:"warning"`
	Danger  int `json:"danger"`
}

// PinjolRecordDetail extends PinjolRecord with computed fields
type PinjolRecordDetail struct {
	PinjolRecord
	MonthsRemaining           int                `json:"months_remaining"`
	TotalInterestIfFullTerm   float64            `json:"total_interest_if_full_term"`
	SavingsIfEarlyPayoff      *EarlyPayoffSavings `json:"savings_if_early_payoff,omitempty"`
}

// EarlyPayoffSavings shows potential interest savings for early payoff
type EarlyPayoffSavings struct {
	PayoffNextMonth  *PayoffOption `json:"payoff_next_month,omitempty"`
	PayoffIn3Months  *PayoffOption `json:"payoff_in_3_months,omitempty"`
}

// PayoffOption represents a payoff scenario
type PayoffOption struct {
	InterestSaved float64 `json:"interest_saved"`
}

// PayoffSimulation is the response for the simulation endpoint
type PayoffSimulation struct {
	Months                     int     `json:"months"`
	TotalPayments              float64 `json:"total_payments"`
	TotalInterest              float64 `json:"total_interest"`
	InterestSavedVsFullTerm    float64 `json:"interest_saved_vs_full_term"`
	CanAffordFromSavings       bool    `json:"can_afford_from_savings"`
	Recommendation             string  `json:"recommendation"`
}

// Request DTOs

type PinjolCreateRequest struct {
	AppName            string  `json:"app_name" binding:"required"`
	Principal          float64 `json:"principal" binding:"required,gt=0"`
	InterestRate       float64 `json:"interest_rate" binding:"required,gte=0"`
	MonthlyInstallment float64 `json:"monthly_installment" binding:"required,gt=0"`
	StartDate          string  `json:"start_date" binding:"required"`
	EndDate            string  `json:"end_date" binding:"required"`
}

type PinjolUpdateRequest struct {
	OutstandingAmount *float64 `json:"outstanding_amount"`
	InterestRate      *float64 `json:"interest_rate"`
}
