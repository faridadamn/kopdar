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

type HourlyRateHandler struct {
	pool       *pgxpool.Pool
	driverRepo *repository.DriverRepository
}

func NewHourlyRateHandler(pool *pgxpool.Pool, driverRepo *repository.DriverRepository) *HourlyRateHandler {
	return &HourlyRateHandler{
		pool:       pool,
		driverRepo: driverRepo,
	}
}

type hourlyRateDay struct {
	Date   string  `json:"date"`
	Hours  float64 `json:"hours"`
	Profit float64 `json:"profit"`
	Rate   float64 `json:"rate"`
}

type hourlyRateResponse struct {
	Period         string           `json:"period"`
	TotalHours     float64          `json:"total_hours"`
	TotalProfit    float64          `json:"total_profit"`
	HourlyRate     float64          `json:"hourly_rate"`
	ZoneAverage    float64          `json:"zone_average"`
	DailyBreakdown []hourlyRateDay  `json:"daily_breakdown"`
	Trend          string           `json:"trend"`
	Insight        string           `json:"insight"`
}

// GET /api/v1/driver/hourly-rate
func (h *HourlyRateHandler) Get(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	period := c.DefaultQuery("period", "week")
	dateFrom := c.Query("date_from")
	dateTo := c.Query("date_to")

	now := time.Now()
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
	}

	if dateFrom == "" {
		dateFrom = now.AddDate(0, 0, -7).Format("2006-01-02")
	}
	if dateTo == "" {
		dateTo = now.Format("2006-01-02")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Query daily hours and profit from transactions
	// For each day: hours = (MAX(created_at) - MIN(created_at)) for income transactions
	// profit = SUM(net_amount) for income - SUM(amount) for expense
	rows, err := h.pool.Query(ctx,
		`SELECT
			TO_CHAR(created_at, 'YYYY-MM-DD') AS date,
			COALESCE(EXTRACT(EPOCH FROM (MAX(created_at) FILTER (WHERE type='income') - MIN(created_at) FILTER (WHERE type='income'))) / 3600.0, 0) AS hours,
			COALESCE(SUM(CASE WHEN type='income' THEN net_amount ELSE -amount END), 0) AS profit
		 FROM driver_transactions
		 WHERE driver_id = $1 AND deleted_at IS NULL
		   AND created_at >= $2 AND created_at <= $3
		 GROUP BY TO_CHAR(created_at, 'YYYY-MM-DD')
		 ORDER BY date ASC`,
		driver.ID, dateFrom, dateTo+" 23:59:59",
	)
	if err != nil {
		utils.InternalError(c, "Gagal menghitung hourly rate: "+err.Error())
		return
	}
	defer rows.Close()

	var breakdown []hourlyRateDay
	var totalHours, totalProfit float64

	for rows.Next() {
		var d hourlyRateDay
		if err := rows.Scan(&d.Date, &d.Hours, &d.Profit); err != nil {
			utils.InternalError(c, "Gagal membaca data: "+err.Error())
			return
		}
		// If only 1 transaction (hours=0), assume 1 hour minimum
		if d.Hours < 1.0 && d.Profit != 0 {
			d.Hours = 1.0
		}
		if d.Hours > 0 {
			d.Rate = d.Profit / d.Hours
		}
		totalHours += d.Hours
		totalProfit += d.Profit
		breakdown = append(breakdown, d)
	}

	if breakdown == nil {
		breakdown = []hourlyRateDay{}
	}

	var hourlyRate float64
	if totalHours > 0 {
		hourlyRate = totalProfit / totalHours
	}

	// Zone average placeholder (hardcoded for now)
	zoneAverage := 22000.0

	// Calculate trend: compare first half vs second half of the period
	trend := calculateTrend(breakdown)

	// Generate insight
	hourlyRateInt := int(math.Round(hourlyRate))
	zoneDiff := 0.0
	if zoneAverage > 0 {
		zoneDiff = ((hourlyRate - zoneAverage) / zoneAverage) * 100
	}

	var insight string
	if hourlyRate > zoneAverage {
		insight = fmt.Sprintf("Kamu dapat Rp %s/jam. %.0f%% lebih tinggi dari rata-rata zona.", formatRupiah(hourlyRateInt), zoneDiff)
	} else if hourlyRate > 0 {
		insight = fmt.Sprintf("Kamu dapat Rp %s/jam. %.0f%% di bawah rata-rata zona. Coba optimasi rute.", formatRupiah(hourlyRateInt), math.Abs(zoneDiff))
	} else {
		insight = "Belum ada data transaksi pada periode ini."
	}

	resp := hourlyRateResponse{
		Period:         period,
		TotalHours:     math.Round(totalHours*10) / 10,
		TotalProfit:    totalProfit,
		HourlyRate:     math.Round(hourlyRate),
		ZoneAverage:    zoneAverage,
		DailyBreakdown: breakdown,
		Trend:          trend,
		Insight:        insight,
	}

	utils.OK(c, "Hourly rate berhasil diambil", resp)
}

func calculateTrend(breakdown []hourlyRateDay) string {
	if len(breakdown) < 2 {
		return "stable"
	}

	mid := len(breakdown) / 2
	var firstHalfRate, secondHalfRate float64
	var firstCount, secondCount int

	for i, d := range breakdown {
		if i < mid {
			firstHalfRate += d.Rate
			firstCount++
		} else {
			secondHalfRate += d.Rate
			secondCount++
		}
	}

	if firstCount > 0 {
		firstHalfRate /= float64(firstCount)
	}
	if secondCount > 0 {
		secondHalfRate /= float64(secondCount)
	}

	diff := secondHalfRate - firstHalfRate
	threshold := firstHalfRate * 0.1 // 10% threshold

	if diff > threshold {
		return "up"
	} else if diff < -threshold {
		return "down"
	}
	return "stable"
}

func formatRupiah(amount int) string {
	str := fmt.Sprintf("%d", amount)
	n := len(str)
	if n <= 3 {
		return str
	}
	result := ""
	for i, c := range str {
		if i > 0 && (n-i)%3 == 0 {
			result += "."
		}
		result += string(c)
	}
	return result
}
