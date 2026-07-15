package handlers

import (
	"context"
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type InsightsHandler struct {
	pool       *pgxpool.Pool
	driverRepo *repository.DriverRepository
}

func NewInsightsHandler(pool *pgxpool.Pool, driverRepo *repository.DriverRepository) *InsightsHandler {
	return &InsightsHandler{
		pool:       pool,
		driverRepo: driverRepo,
	}
}

type insight struct {
	Type     string `json:"type"`
	Severity string `json:"severity"`
	Title    string `json:"title"`
	Message  string `json:"message"`
	Icon     string `json:"icon"`
}

type insightsResponse struct {
	Insights    []insight `json:"insights"`
	GeneratedAt time.Time `json:"generated_at"`
}

// GET /api/v1/driver/insights
func (h *InsightsHandler) Get(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	now := time.Now()
	weekday := int(now.Weekday())
	if weekday == 0 {
		weekday = 7
	}
	thisWeekFrom := now.AddDate(0, 0, -(weekday - 1)).Format("2006-01-02")
	thisWeekTo := now.Format("2006-01-02")
	lastWeekTo := now.AddDate(0, 0, -(weekday)).Format("2006-01-02")
	lastWeekFrom := now.AddDate(0, 0, -(weekday + 6)).Format("2006-01-02")

	var insights []insight

	// 1. Compare expense by category week-over-week → flag if >10% increase
	expenseInsights := h.checkExpenseTrends(ctx, driver.ID, thisWeekFrom, thisWeekTo+" 23:59:59", lastWeekFrom, lastWeekTo+" 23:59:59")
	insights = append(insights, expenseInsights...)

	// 2. Check total hours this week → warn if >55 hours
	hoursInsight := h.checkBurnout(ctx, driver.ID, thisWeekFrom, thisWeekTo+" 23:59:59")
	if hoursInsight != nil {
		insights = append(insights, *hoursInsight)
	}

	// 3. Compare profit per order across platforms → recommend highest
	platformInsight := h.checkPlatformRecommendation(ctx, driver.ID, thisWeekFrom, thisWeekTo+" 23:59:59")
	if platformInsight != nil {
		insights = append(insights, *platformInsight)
	}

	// 4. Check savings progress
	savingsInsight := h.checkSavingsProgress(ctx, driver.ID)
	if savingsInsight != nil {
		insights = append(insights, *savingsInsight)
	}

	// Sort by severity: danger > warning > info
	insights = sortBySeverity(insights)

	// Max 3 insights
	if len(insights) > 3 {
		insights = insights[:3]
	}

	if insights == nil {
		insights = []insight{}
	}

	resp := insightsResponse{
		Insights:    insights,
		GeneratedAt: now,
	}

	utils.OK(c, "Insight berhasil diambil", resp)
}

func (h *InsightsHandler) checkExpenseTrends(ctx context.Context, driverID uuid.UUID, thisFrom, thisTo, lastFrom, lastTo string) []insight {
	var results []insight

	rows, err := h.pool.Query(ctx,
		`SELECT category,
			COALESCE(SUM(CASE WHEN created_at >= $2 AND created_at <= $3 THEN amount ELSE 0 END), 0) AS this_week,
			COALESCE(SUM(CASE WHEN created_at >= $4 AND created_at <= $5 THEN amount ELSE 0 END), 0) AS last_week
		 FROM driver_transactions
		 WHERE driver_id = $1 AND type = 'expense' AND deleted_at IS NULL
		   AND created_at >= $4 AND created_at <= $3
		 GROUP BY category
		 HAVING SUM(CASE WHEN created_at >= $4 AND created_at <= $5 THEN amount ELSE 0 END) > 0`,
		driverID, thisFrom, thisTo, lastFrom, lastTo,
	)
	if err != nil {
		return results
	}
	defer rows.Close()

	for rows.Next() {
		var category string
		var thisWeek, lastWeek float64
		if err := rows.Scan(&category, &thisWeek, &lastWeek); err != nil {
			continue
		}

		if lastWeek > 0 {
			change := ((thisWeek - lastWeek) / lastWeek) * 100
			if change > 10 {
				results = append(results, insight{
					Type:     "expense_trend",
					Severity: "warning",
					Title:    fmt.Sprintf("%s naik %.0f%%", categoryName(category), change),
					Message:  fmt.Sprintf("Pengeluaran %s minggu ini naik %.0f%% dari minggu lalu. Coba cari alternatif yang lebih hemat.", category, change),
					Icon:     categoryIcon(category),
				})
			}
		}
	}

	return results
}

func (h *InsightsHandler) checkBurnout(ctx context.Context, driverID uuid.UUID, dateFrom, dateTo string) *insight {
	var totalHours *float64
	err := h.pool.QueryRow(ctx,
		`SELECT SUM(hours)
		 FROM (
			SELECT EXTRACT(EPOCH FROM (MAX(created_at) - MIN(created_at))) / 3600.0 AS hours
			FROM driver_transactions
			WHERE driver_id = $1 AND type = 'income' AND deleted_at IS NULL
			  AND created_at >= $2 AND created_at <= $3
			GROUP BY TO_CHAR(created_at, 'YYYY-MM-DD')
			HAVING COUNT(*) > 1
		 ) daily_hours`,
		driverID, dateFrom, dateTo,
	).Scan(&totalHours)

	if err != nil || totalHours == nil {
		return nil
	}

	hours := *totalHours
	if hours > 55 {
		return &insight{
			Type:     "burnout_warning",
			Severity: "danger",
			Title:    "Hati-hati burnout!",
			Message:  fmt.Sprintf("Kamu narik %.0f jam minggu ini. Istirahat yang cukup ya.", hours),
			Icon:     "⚠️",
		}
	}
	return nil
}

func (h *InsightsHandler) checkPlatformRecommendation(ctx context.Context, driverID uuid.UUID, dateFrom, dateTo string) *insight {
	rows, err := h.pool.Query(ctx,
		`SELECT platform,
			SUM(net_amount) AS total_profit,
			SUM(order_count) AS total_orders,
			CASE WHEN SUM(order_count) > 0 THEN SUM(net_amount)::float / SUM(order_count) ELSE 0 END AS profit_per_order
		 FROM driver_transactions
		 WHERE driver_id = $1 AND type = 'income' AND deleted_at IS NULL
		   AND platform IS NOT NULL AND platform != ''
		   AND created_at >= $2 AND created_at <= $3
		 GROUP BY platform
		 HAVING SUM(order_count) >= 3
		 ORDER BY profit_per_order DESC
		 LIMIT 1`,
		driverID, dateFrom, dateTo,
	)
	if err != nil {
		return nil
	}
	defer rows.Close()

	if rows.Next() {
		var platform string
		var totalProfit float64
		var totalOrders int
		var profitPerOrder float64
		if err := rows.Scan(&platform, &totalProfit, &totalOrders, &profitPerOrder); err != nil {
			return nil
		}

		return &insight{
			Type:     "platform_recommendation",
			Severity: "info",
			Title:    fmt.Sprintf("Fokus ke %s", platformName(platform)),
			Message:  fmt.Sprintf("%s kasih profit per order tertinggi minggu ini (Rp %s/order).", platformName(platform), formatRupiah(int(profitPerOrder))),
			Icon:     "💡",
		}
	}
	return nil
}

func (h *InsightsHandler) checkSavingsProgress(ctx context.Context, driverID uuid.UUID) *insight {
	var current float64
	err := h.pool.QueryRow(ctx,
		`SELECT COALESCE(balance, 0) FROM savings
		 WHERE user_id = (SELECT user_id FROM drivers WHERE id = $1) AND type = 'emergency'`,
		driverID,
	).Scan(&current)

	if err != nil {
		return nil
	}

	target := 1000000.0
	progress := (current / target) * 100

	if progress >= 50 && progress < 100 {
		return &insight{
			Type:     "savings_progress",
			Severity: "info",
			Title:    "Dana darurat hampir tercapai!",
			Message:  fmt.Sprintf("Dana darurat kamu sudah %.0f%% dari target Rp 1.000.000. Tinggal sedikit lagi!", progress),
			Icon:     "🎯",
		}
	} else if progress >= 100 {
		return &insight{
			Type:     "savings_progress",
			Severity: "info",
			Title:    "Dana darurat tercapai! 🎉",
			Message:  "Selamat! Dana darurat kamu sudah tercapai. Pertahankan!",
			Icon:     "🎉",
		}
	}
	return nil
}

func sortBySeverity(insights []insight) []insight {
	severityOrder := map[string]int{
		"danger":  0,
		"warning": 1,
		"info":    2,
	}

	// Simple insertion sort (max 5-6 items)
	for i := 1; i < len(insights); i++ {
		key := insights[i]
		j := i - 1
		for j >= 0 && severityOrder[insights[j].Severity] > severityOrder[key.Severity] {
			insights[j+1] = insights[j]
			j--
		}
		insights[j+1] = key
	}
	return insights
}

func categoryName(category string) string {
	names := map[string]string{
		"bensin":    "Bensin",
		"makan":     "Makan",
		"angsuran":  "Angsuran",
		"servis":    "Servis",
		"pulsa":     "Pulsa",
		"parkir":    "Parkir",
		"kesehatan": "Kesehatan",
		"lainnya":   "Lainnya",
	}
	if n, ok := names[category]; ok {
		return n
	}
	return category
}



func categoryIcon(category string) string {
	icons := map[string]string{
		"bensin":    "⛽",
		"makan":     "🍔",
		"angsuran":  "💳",
		"servis":    "🔧",
		"pulsa":     "📱",
		"parkir":    "🅿️",
		"kesehatan": "🏥",
		"lainnya":   "📦",
	}
	if i, ok := icons[category]; ok {
		return i
	}
	return "📦"
}

func platformName(platform string) string {
	names := map[string]string{
		"gojek":      "Gojek",
		"grab":       "Grab",
		"shopeefood": "ShopeeFood",
		"maxim":      "Maxim",
		"indrive":    "InDrive",
		"cash":       "Cash",
		"lainnya":    "Lainnya",
	}
	if n, ok := names[platform]; ok {
		return n
	}
	return platform
}
