package models

import (
	"time"

	"github.com/google/uuid"
)

// Driver transaction types
const (
	TxnTypeIncome  = "income"
	TxnTypeExpense = "expense"
)

// Income platforms
const (
	PlatformGojek      = "gojek"
	PlatformGrab       = "grab"
	PlatformShopeeFood = "shopeefood"
	PlatformMaxim      = "maxim"
	PlatformInDrive    = "indrive"
	PlatformCash       = "cash"
	PlatformLainnya    = "lainnya"
)

// Expense categories
const (
	CategoryBensin    = "bensin"
	CategoryMakan     = "makan"
	CategoryAngsuran  = "angsuran"
	CategoryServis    = "servis"
	CategoryPulsa     = "pulsa"
	CategoryParkir    = "parkir"
	CategoryKesehatan = "kesehatan"
	CategoryLainnya   = "lainnya"
)

type DriverTransaction struct {
	ID         uuid.UUID  `json:"id" db:"id"`
	DriverID   uuid.UUID  `json:"driver_id" db:"driver_id"`
	Type       string     `json:"type" db:"type"`
	Category   string     `json:"category" db:"category"`
	Platform   *string    `json:"platform,omitempty" db:"platform"`
	Amount     float64    `json:"amount" db:"amount"`
	Commission float64    `json:"commission" db:"commission"`
	NetAmount  float64    `json:"net_amount" db:"net_amount"`
	Notes      *string    `json:"notes,omitempty" db:"notes"`
	ReceiptURL *string    `json:"receipt_url,omitempty" db:"receipt_url"`
	OrderCount int        `json:"order_count" db:"order_count"`
	CreatedAt  time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time  `json:"updated_at" db:"updated_at"`
	DeletedAt  *time.Time `json:"-" db:"deleted_at"`
}

// Request DTOs

type TransactionCreateRequest struct {
	Type       string  `json:"type" binding:"required,oneof=income expense"`
	Category   string  `json:"category" binding:"required"`
	Platform   string  `json:"platform"`
	Amount     float64 `json:"amount" binding:"required,gt=0"`
	Commission float64 `json:"commission"`
	Notes      string  `json:"notes"`
	OrderCount int     `json:"order_count"`
	ReceiptURL string  `json:"receipt_url"`
}

type TransactionUpdateRequest struct {
	Amount     *float64 `json:"amount"`
	Commission *float64 `json:"commission"`
	Notes      *string  `json:"notes"`
	Category   *string  `json:"category"`
}

// Query filters

type TransactionFilter struct {
	Type     string `form:"type"`
	Platform string `form:"platform"`
	DateFrom string `form:"date_from"`
	DateTo   string `form:"date_to"`
	Page     int    `form:"page,default=1"`
	Limit    int    `form:"limit,default=20"`
}

// Summary response types

type TransactionSummary struct {
	TotalIncome        float64              `json:"total_income"`
	TotalExpense       float64              `json:"total_expense"`
	Profit             float64              `json:"profit"`
	TotalOrders        int                  `json:"total_orders"`
	AvgPerOrder        float64              `json:"avg_per_order"`
	IncomeByPlatform   []PlatformSummary    `json:"income_by_platform"`
	ExpenseByCategory  []CategorySummary    `json:"expense_by_category"`
	DailyBreakdown     []DailySummary       `json:"daily_breakdown"`
}

type PlatformSummary struct {
	Platform string  `json:"platform"`
	Total    float64 `json:"total"`
	Count    int     `json:"count"`
}

type CategorySummary struct {
	Category string  `json:"category"`
	Total    float64 `json:"total"`
	Count    int     `json:"count"`
}

type DailySummary struct {
	Date    string  `json:"date"`
	Income  float64 `json:"income"`
	Expense float64 `json:"expense"`
	Profit  float64 `json:"profit"`
}

// Dashboard response types

type DashboardResponse struct {
	DailyIncome       DailyIncomeData   `json:"daily_income"`
	RecentTransactions []DriverTransaction `json:"recent_transactions"`
	Alerts            []DashboardAlert  `json:"alerts"`
	DanaDarurat       DanaDaruratData   `json:"dana_darurat"`
}

type DailyIncomeData struct {
	Amount        float64 `json:"amount"`
	OrderCount    int     `json:"order_count"`
	Hours         float64 `json:"hours"`
	AvgPerOrder   float64 `json:"avg_per_order"`
	ChangePercent float64 `json:"change_percent"`
}

type DashboardAlert struct {
	Type     string `json:"type"`
	Message  string `json:"message"`
	Severity string `json:"severity"`
}

type DanaDaruratData struct {
	Current      float64 `json:"current"`
	Target       float64 `json:"target"`
	DailyAmount  float64 `json:"daily_amount"`
	EstimatedDays int    `json:"estimated_days"`
}
