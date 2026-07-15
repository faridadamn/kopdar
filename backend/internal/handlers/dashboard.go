package handlers

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type DashboardHandler struct {
	txnRepo    *repository.TransactionRepository
	driverRepo *repository.DriverRepository
}

func NewDashboardHandler(txnRepo *repository.TransactionRepository, driverRepo *repository.DriverRepository) *DashboardHandler {
	return &DashboardHandler{
		txnRepo:    txnRepo,
		driverRepo: driverRepo,
	}
}

// GET /api/v1/dashboard
func (h *DashboardHandler) Get(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	today := c.DefaultQuery("date", time.Now().Format("2006-01-02"))
	yesterday := parseDateSafe(today).AddDate(0, 0, -1).Format("2006-01-02")

	// Daily income data
	todayIncome, todayOrders, _ := h.txnRepo.GetDailyIncome(driver.ID, today)
	yesterdayIncome, _, _ := h.txnRepo.GetDailyIncome(driver.ID, yesterday)
	hours, _ := h.txnRepo.GetDailyHours(driver.ID, today)

	var avgPerOrder float64
	if todayOrders > 0 {
		avgPerOrder = todayIncome / float64(todayOrders)
	}

	var changePercent float64
	if yesterdayIncome > 0 {
		changePercent = ((todayIncome - yesterdayIncome) / yesterdayIncome) * 100
	}

	// Recent transactions (last 4)
	recentTxns, _ := h.txnRepo.GetRecentTransactions(driver.ID, 4)
	if recentTxns == nil {
		recentTxns = []models.DriverTransaction{}
	}

	// Alerts (placeholder — would integrate with pinjol_records and insurance_policies)
	alerts := h.buildAlerts(driver.ID)

	// Dana darurat
	emergencyFund, _ := h.txnRepo.GetEmergencyFund(driver.ID)
	targetFund := 1000000.0 // Rp 1 juta target
	var dailyAmount float64
	if todayOrders > 0 {
		dailyAmount = todayIncome * 0.1 // Assume 10% allocation to emergency fund
	}
	var estimatedDays int
	remaining := targetFund - emergencyFund
	if remaining < 0 {
		remaining = 0
	}
	if dailyAmount > 0 {
		estimatedDays = int(remaining / dailyAmount)
	}

	dashboard := models.DashboardResponse{
		DailyIncome: models.DailyIncomeData{
			Amount:        todayIncome,
			OrderCount:    todayOrders,
			Hours:         hours,
			AvgPerOrder:   avgPerOrder,
			ChangePercent: changePercent,
		},
		RecentTransactions: recentTxns,
		Alerts:            alerts,
		DanaDarurat: models.DanaDaruratData{
			Current:       emergencyFund,
			Target:        targetFund,
			DailyAmount:   dailyAmount,
			EstimatedDays: estimatedDays,
		},
	}

	utils.OK(c, "Dashboard berhasil diambil", dashboard)
}

func (h *DashboardHandler) buildAlerts(driverID uuid.UUID) []models.DashboardAlert {
	// Placeholder alerts — in production these would query pinjol_records and insurance_policies
	// For now return sample alerts to demonstrate the structure
	alerts := []models.DashboardAlert{}

	// Check if driver has any outstanding pinjol debts
	// This would query: SELECT * FROM pinjol_records WHERE user_id = ... AND status IN ('disbursed', 'repaying')
	// For now, return empty alerts
	_ = driverID

	return alerts
}

func parseDateSafe(dateStr string) time.Time {
	t, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return time.Now()
	}
	return t
}
