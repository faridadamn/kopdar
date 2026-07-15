package handlers

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type TransactionHandler struct {
	txnRepo    *repository.TransactionRepository
	driverRepo *repository.DriverRepository
}

func NewTransactionHandler(txnRepo *repository.TransactionRepository, driverRepo *repository.DriverRepository) *TransactionHandler {
	return &TransactionHandler{
		txnRepo:    txnRepo,
		driverRepo: driverRepo,
	}
}

// POST /api/v1/transactions
func (h *TransactionHandler) Create(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.TransactionCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	// Validate category for expense
	if req.Type == models.TxnTypeExpense {
		if !isValidExpenseCategory(req.Category) {
			utils.BadRequest(c, "Kategori pengeluaran tidak valid")
			return
		}
	}

	// Platform is required for income
	if req.Type == models.TxnTypeIncome {
		if req.Platform == "" {
			utils.BadRequest(c, "Platform wajib diisi untuk pemasukan")
			return
		}
		if !isValidPlatform(req.Platform) {
			utils.BadRequest(c, "Platform tidak valid")
			return
		}
	}

	// Default order count for income
	orderCount := req.OrderCount
	if orderCount < 1 {
		orderCount = 1
	}

	// Auto-calculate net_amount
	commission := req.Commission
	netAmount := req.Amount - commission

	txn := &models.DriverTransaction{
		DriverID:   driver.ID,
		Type:       req.Type,
		Category:   req.Category,
		Amount:     req.Amount,
		Commission: commission,
		NetAmount:  netAmount,
		OrderCount: orderCount,
	}

	if req.Platform != "" {
		txn.Platform = &req.Platform
	}
	if req.Notes != "" {
		txn.Notes = &req.Notes
	}
	if req.ReceiptURL != "" {
		txn.ReceiptURL = &req.ReceiptURL
	}

	if err := h.txnRepo.Create(txn); err != nil {
		utils.InternalError(c, "Gagal menyimpan transaksi: "+err.Error())
		return
	}

	utils.Created(c, "Transaksi berhasil disimpan", txn)
}

// GET /api/v1/transactions
func (h *TransactionHandler) List(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var filter models.TransactionFilter
	if err := c.ShouldBindQuery(&filter); err != nil {
		// Use defaults
	}

	// Default date range: last 30 days
	if filter.DateFrom == "" {
		filter.DateFrom = time.Now().AddDate(0, 0, -30).Format("2006-01-02")
	}
	if filter.DateTo == "" {
		filter.DateTo = time.Now().Format("2006-01-02")
	}

	txns, total, err := h.txnRepo.List(driver.ID, filter)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil transaksi")
		return
	}

	if txns == nil {
		txns = []models.DriverTransaction{}
	}

 totalPages := int(total) / filter.Limit
	if int(total)%filter.Limit > 0 {
		totalPages++
	}

	utils.OK(c, "Transaksi berhasil diambil", gin.H{
		"data":        txns,
		"page":        filter.Page,
		"limit":       filter.Limit,
		"total_items": total,
		"total_pages": totalPages,
	})
}

// GET /api/v1/transactions/summary
func (h *TransactionHandler) Summary(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	period := c.DefaultQuery("period", "month")
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
		dateFrom = now.AddDate(0, 0, -30).Format("2006-01-02")
	}
	if dateTo == "" {
		dateTo = now.Format("2006-01-02")
	}

	summary, err := h.txnRepo.GetSummary(driver.ID, dateFrom, dateTo)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil ringkasan: "+err.Error())
		return
	}

	// Ensure slices are not nil for JSON
	if summary.IncomeByPlatform == nil {
		summary.IncomeByPlatform = []models.PlatformSummary{}
	}
	if summary.ExpenseByCategory == nil {
		summary.ExpenseByCategory = []models.CategorySummary{}
	}
	if summary.DailyBreakdown == nil {
		summary.DailyBreakdown = []models.DailySummary{}
	}

	utils.OK(c, "Ringkasan berhasil diambil", summary)
}

// GET /api/v1/transactions/:id
func (h *TransactionHandler) Get(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID transaksi tidak valid")
		return
	}

	txn, err := h.txnRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Transaksi tidak ditemukan")
		return
	}

	// Ensure the transaction belongs to this driver
	if txn.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke transaksi ini")
		return
	}

	utils.OK(c, "Transaksi berhasil diambil", txn)
}

// PUT /api/v1/transactions/:id
func (h *TransactionHandler) Update(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID transaksi tidak valid")
		return
	}

	txn, err := h.txnRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Transaksi tidak ditemukan")
		return
	}

	if txn.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke transaksi ini")
		return
	}

	// Check 24-hour edit window
	if time.Since(txn.CreatedAt) > 24*time.Hour {
		utils.BadRequest(c, "Transaksi hanya bisa diubah dalam 24 jam setelah dibuat")
		return
	}

	var req models.TransactionUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	// Apply partial updates
	if req.Amount != nil {
		txn.Amount = *req.Amount
	}
	if req.Commission != nil {
		txn.Commission = *req.Commission
	}
	if req.Notes != nil {
		txn.Notes = req.Notes
	}
	if req.Category != nil {
		if txn.Type == models.TxnTypeExpense && !isValidExpenseCategory(*req.Category) {
			utils.BadRequest(c, "Kategori pengeluaran tidak valid")
			return
		}
		txn.Category = *req.Category
	}

	// Recalculate net_amount
	txn.NetAmount = txn.Amount - txn.Commission

	if err := h.txnRepo.Update(txn); err != nil {
		utils.InternalError(c, "Gagal mengupdate transaksi")
		return
	}

	utils.OK(c, "Transaksi berhasil diupdate", txn)
}

// DELETE /api/v1/transactions/:id
func (h *TransactionHandler) Delete(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID transaksi tidak valid")
		return
	}

	txn, err := h.txnRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Transaksi tidak ditemukan")
		return
	}

	if txn.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke transaksi ini")
		return
	}

	// Check 24-hour delete window
	if time.Since(txn.CreatedAt) > 24*time.Hour {
		utils.BadRequest(c, "Transaksi hanya bisa dihapus dalam 24 jam setelah dibuat")
		return
	}

	if err := h.txnRepo.SoftDelete(id); err != nil {
		utils.InternalError(c, "Gagal menghapus transaksi")
		return
	}

	utils.OK(c, "Transaksi berhasil dihapus", gin.H{
		"id":      id,
		"message": fmt.Sprintf("Transaksi %s berhasil dihapus", id.String()[:8]),
	})
}

// Validation helpers

func isValidExpenseCategory(category string) bool {
	switch category {
	case models.CategoryBensin, models.CategoryMakan, models.CategoryAngsuran,
		models.CategoryServis, models.CategoryPulsa, models.CategoryParkir,
		models.CategoryKesehatan, models.CategoryLainnya:
		return true
	default:
		return false
	}
}

func isValidPlatform(platform string) bool {
	switch platform {
	case models.PlatformGojek, models.PlatformGrab, models.PlatformShopeeFood,
		models.PlatformMaxim, models.PlatformInDrive, models.PlatformCash,
		models.PlatformLainnya:
		return true
	default:
		return false
	}
}
