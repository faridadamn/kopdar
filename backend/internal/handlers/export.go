package handlers

import (
	"context"
	"encoding/csv"
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type ExportHandler struct {
	pool       *pgxpool.Pool
	driverRepo *repository.DriverRepository
}

func NewExportHandler(pool *pgxpool.Pool, driverRepo *repository.DriverRepository) *ExportHandler {
	return &ExportHandler{
		pool:       pool,
		driverRepo: driverRepo,
	}
}

type exportRow struct {
	Date       string
	Type       string
	Category   string
	Platform   string
	Gross      float64
	Commission float64
	Net        float64
	Notes      string
}

// GET /api/v1/driver/export
func (h *ExportHandler) CSV(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	dateFrom := c.Query("date_from")
	dateTo := c.Query("date_to")
	exportType := c.DefaultQuery("type", "all")

	now := time.Now()
	if dateFrom == "" {
		dateFrom = now.AddDate(0, 0, -30).Format("2006-01-02")
	}
	if dateTo == "" {
		dateTo = now.Format("2006-01-02")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Build query
	where := "driver_id = $1 AND deleted_at IS NULL AND created_at >= $2 AND created_at <= $3"
	args := []interface{}{driver.ID, dateFrom, dateTo + " 23:59:59"}

	if exportType != "all" {
		where += " AND type = $4"
		args = append(args, exportType)
	}

	rows, err := h.pool.Query(ctx,
		`SELECT
			TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI'),
			type,
			category,
			COALESCE(platform, ''),
			amount,
			commission,
			net_amount,
			COALESCE(notes, '')
		 FROM driver_transactions
		 WHERE `+where+`
		 ORDER BY created_at ASC`,
		args...,
	)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil data export: "+err.Error())
		return
	}
	defer rows.Close()

	var exportRows []exportRow
	for rows.Next() {
		var r exportRow
		if err := rows.Scan(&r.Date, &r.Type, &r.Category, &r.Platform, &r.Gross, &r.Commission, &r.Net, &r.Notes); err != nil {
			utils.InternalError(c, "Gagal membaca data: "+err.Error())
			return
		}
		exportRows = append(exportRows, r)
	}

	// Set CSV headers
	filename := fmt.Sprintf("kopdar_%s_%s.csv", dateFrom, dateTo)
	c.Header("Content-Type", "text/csv; charset=utf-8")
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))

	writer := csv.NewWriter(c.Writer)
	defer writer.Flush()

	// Write BOM for Excel compatibility
	c.Writer.Write([]byte("\xEF\xBB\xBF"))

	// CSV header row
	writer.Write([]string{
		"tanggal", "tipe", "kategori", "platform", "gross", "komisi", "net", "catatan",
	})

	// Data rows
	for _, r := range exportRows {
		writer.Write([]string{
			r.Date,
			r.Type,
			r.Category,
			r.Platform,
			fmt.Sprintf("%.0f", r.Gross),
			fmt.Sprintf("%.0f", r.Commission),
			fmt.Sprintf("%.0f", r.Net),
			r.Notes,
		})
	}

	// If no data, still return the CSV with headers only
	if exportRows == nil {
		// CSV already has headers, just return empty data
	}
}
