package handlers

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type ExpenseHandler struct {
	pool       *pgxpool.Pool
	driverRepo *repository.DriverRepository
}

func NewExpenseHandler(pool *pgxpool.Pool, driverRepo *repository.DriverRepository) *ExpenseHandler {
	return &ExpenseHandler{
		pool:       pool,
		driverRepo: driverRepo,
	}
}

type expenseItem struct {
	ID         uuid.UUID `json:"id"`
	Category   string    `json:"category"`
	Amount     float64   `json:"amount"`
	Notes      *string   `json:"notes,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
}

type expenseByCategory struct {
	Category   string  `json:"category"`
	Total      float64 `json:"total"`
	Count      int     `json:"count"`
	Percentage float64 `json:"percentage"`
}

type expenseDayGroup struct {
	Date     string        `json:"date"`
	Expenses []expenseItem `json:"expenses"`
	Total    float64       `json:"total"`
}

type expenseListResponse struct {
	Expenses    []expenseDayGroup   `json:"expenses"`
	Total       float64             `json:"total"`
	ByCategory  []expenseByCategory `json:"by_category"`
	Meta        meta                `json:"meta"`
}

type meta struct {
	Page      int   `json:"page"`
	Limit     int   `json:"limit"`
	TotalItem int64 `json:"total_item"`
}

type expenseSummaryResponse struct {
	Total        float64             `json:"total"`
	ByCategory   []expenseByCategory `json:"by_category"`
	DailyAverage float64             `json:"daily_average"`
	VsLastPeriod string              `json:"vs_last_period"`
}

// GET /api/v1/driver/expenses
func (h *ExpenseHandler) List(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	category := c.Query("category")
	dateFrom := c.Query("date_from")
	dateTo := c.Query("date_to")
	page := 1
	limit := 20

	fmt.Sscanf(c.DefaultQuery("page", "1"), "%d", &page)
	fmt.Sscanf(c.DefaultQuery("limit", "20"), "%d", &limit)
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	if dateFrom == "" {
		dateFrom = time.Now().AddDate(0, 0, -30).Format("2006-01-02")
	}
	if dateTo == "" {
		dateTo = time.Now().Format("2006-01-02")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Build WHERE
	where := "driver_id = $1 AND type = 'expense' AND deleted_at IS NULL AND created_at >= $2 AND created_at <= $3"
	args := []interface{}{driver.ID, dateFrom, dateTo + " 23:59:59"}
	argIdx := 4

	if category != "" {
		where += fmt.Sprintf(" AND category = $%d", argIdx)
		args = append(args, category)
		argIdx++
	}

	// Count total
	var totalItem int64
	err = h.pool.QueryRow(ctx,
		"SELECT COUNT(*) FROM driver_transactions WHERE "+where, args...,
	).Scan(&totalItem)
	if err != nil {
		utils.InternalError(c, "Gagal menghitung pengeluaran")
		return
	}

	// Fetch expenses
	offset := (page - 1) * limit
	queryArgs := append(args, limit, offset)
	rows, err := h.pool.Query(ctx,
		`SELECT id, category, amount, notes, created_at
		 FROM driver_transactions WHERE `+where+
			fmt.Sprintf(` ORDER BY created_at DESC LIMIT $%d OFFSET $%d`, argIdx, argIdx+1),
		queryArgs...,
	)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil pengeluaran")
		return
	}
	defer rows.Close()

	var items []expenseItem
	for rows.Next() {
		var item expenseItem
		if err := rows.Scan(&item.ID, &item.Category, &item.Amount, &item.Notes, &item.CreatedAt); err != nil {
			utils.InternalError(c, "Gagal membaca data")
			return
		}
		items = append(items, item)
	}

	if items == nil {
		items = []expenseItem{}
	}

	// Group by date
	grouped := groupExpensesByDate(items)

	// Category totals
	var grandTotal float64
	catTotals := make(map[string]struct {
		total float64
		count int
	})
	for _, item := range items {
		grandTotal += item.Amount
		ct := catTotals[item.Category]
		ct.total += item.Amount
		ct.count++
		catTotals[item.Category] = ct
	}

	var byCategory []expenseByCategory
	for cat, ct := range catTotals {
		pct := 0.0
		if grandTotal > 0 {
			pct = math.Round((ct.total/grandTotal)*100*10) / 10
		}
		byCategory = append(byCategory, expenseByCategory{
			Category:   cat,
			Total:      ct.total,
			Count:      ct.count,
			Percentage: pct,
		})
	}

	resp := expenseListResponse{
		Expenses:   grouped,
		Total:      grandTotal,
		ByCategory: byCategory,
		Meta: meta{
			Page:      page,
			Limit:     limit,
			TotalItem: totalItem,
		},
	}

	utils.OK(c, "Pengeluaran berhasil diambil", resp)
}

// GET /api/v1/driver/expenses/summary
func (h *ExpenseHandler) Summary(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	period := c.DefaultQuery("period", "month")
	now := time.Now()
	var dateFrom, dateTo string

	switch period {
	case "today":
		dateFrom = now.Format("2006-01-02")
		dateTo = now.Format("2006-01-02")
	case "week":
		weekday := int(now.Weekday())
		if weekday == 0 {
			weekday = 7
		}
		dateFrom = now.AddDate(0, 0, -(weekday - 1)).Format("2006-01-02")
		dateTo = now.Format("2006-01-02")
	case "month":
		dateFrom = now.Format("2006-01") + "-01"
		dateTo = now.Format("2006-01-02")
	default:
		dateFrom = now.AddDate(0, 0, -30).Format("2006-01-02")
		dateTo = now.Format("2006-01-02")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Current period total and by category
	rows, err := h.pool.Query(ctx,
		`SELECT category, SUM(amount), COUNT(*)
		 FROM driver_transactions
		 WHERE driver_id = $1 AND type = 'expense' AND deleted_at IS NULL
		   AND created_at >= $2 AND created_at <= $3
		 GROUP BY category ORDER BY SUM(amount) DESC`,
		driver.ID, dateFrom, dateTo+" 23:59:59",
	)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil ringkasan pengeluaran")
		return
	}
	defer rows.Close()

	var total float64
	var byCategory []expenseByCategory
	for rows.Next() {
		var ct expenseByCategory
		if err := rows.Scan(&ct.Category, &ct.Total, &ct.Count); err != nil {
			utils.InternalError(c, "Gagal membaca data")
			return
		}
		total += ct.Total
		byCategory = append(byCategory, ct)
	}

	// Calculate percentages
	for i := range byCategory {
		if total > 0 {
			byCategory[i].Percentage = math.Round((byCategory[i].Total/total)*100*10) / 10
		}
	}

	if byCategory == nil {
		byCategory = []expenseByCategory{}
	}

	// Calculate days in period for daily average
	dateFromTime, _ := time.Parse("2006-01-02", dateFrom)
	dateToTime, _ := time.Parse("2006-01-02", dateTo)
	days := int(dateToTime.Sub(dateFromTime).Hours()/24) + 1
	if days < 1 {
		days = 1
	}
	dailyAverage := total / float64(days)

	// Compare vs last period
	var lastDateFrom, lastDateTo string
	duration := dateToTime.Sub(dateFromTime)
	lastDateTo = dateFromTime.AddDate(0, 0, -1).Format("2006-01-02")
	lastDateFrom = dateFromTime.Add(-duration).Format("2006-01-02")

	var lastTotal float64
	err = h.pool.QueryRow(ctx,
		`SELECT COALESCE(SUM(amount), 0)
		 FROM driver_transactions
		 WHERE driver_id = $1 AND type = 'expense' AND deleted_at IS NULL
		   AND created_at >= $2 AND created_at <= $3`,
		driver.ID, lastDateFrom, lastDateTo+" 23:59:59",
	).Scan(&lastTotal)
	if err != nil {
		lastTotal = 0
	}

	vsLastPeriod := "0%"
	if lastTotal > 0 {
		change := ((total - lastTotal) / lastTotal) * 100
		sign := "+"
		if change < 0 {
			sign = ""
		}
		vsLastPeriod = fmt.Sprintf("%s%.0f%%", sign, change)
	} else if total > 0 {
		vsLastPeriod = "+100%"
	}

	resp := expenseSummaryResponse{
		Total:        total,
		ByCategory:   byCategory,
		DailyAverage: math.Round(dailyAverage),
		VsLastPeriod: vsLastPeriod,
	}

	utils.OK(c, "Ringkasan pengeluaran berhasil diambil", resp)
}

func groupExpensesByDate(items []expenseItem) []expenseDayGroup {
	if len(items) == 0 {
		return []expenseDayGroup{}
	}

	groups := make(map[string]*expenseDayGroup)
	order := []string{}

	for _, item := range items {
		date := item.CreatedAt.Format("2006-01-02")
		if _, exists := groups[date]; !exists {
			groups[date] = &expenseDayGroup{Date: date}
			order = append(order, date)
		}
		groups[date].Expenses = append(groups[date].Expenses, item)
		groups[date].Total += item.Amount
	}

	result := make([]expenseDayGroup, 0, len(order))
	for _, date := range order {
		if groups[date].Expenses == nil {
			groups[date].Expenses = []expenseItem{}
		}
		result = append(result, *groups[date])
	}
	return result
}
