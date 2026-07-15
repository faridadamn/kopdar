package handlers

import (
	"fmt"
	"math"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type SavingHandler struct {
	savingRepo *repository.SavingRepository
	driverRepo *repository.DriverRepository
}

func NewSavingHandler(savingRepo *repository.SavingRepository, driverRepo *repository.DriverRepository) *SavingHandler {
	return &SavingHandler{
		savingRepo: savingRepo,
		driverRepo: driverRepo,
	}
}

// POST /api/v1/driver/savings
func (h *SavingHandler) Create(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.SavingsCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	savings := &models.Savings{
		DriverID:     driver.ID,
		GoalName:     req.GoalName,
		GoalIcon:     req.GoalIcon,
		TargetAmount: req.TargetAmount,
		DailyAmount:  req.DailyAmount,
		AutoSave:     req.AutoSave,
		Status:       models.SavingsStatusActive,
	}

	if err := h.savingRepo.Create(savings); err != nil {
		utils.InternalError(c, "Gagal membuat tabungan: "+err.Error())
		return
	}

	utils.Created(c, "Tabungan berhasil dibuat", savings)
}

// GET /api/v1/driver/savings
func (h *SavingHandler) List(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	savings, err := h.savingRepo.ListByDriver(driver.ID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil daftar tabungan")
		return
	}

	if savings == nil {
		savings = []models.Savings{}
	}

	var totalSaved, totalTarget float64
	goals := make([]models.SavingsGoalDetail, 0, len(savings))

	for _, s := range savings {
		totalSaved += s.CurrentAmount
		totalTarget += s.TargetAmount

		detail := models.SavingsGoalDetail{
			Savings:         s,
			ProgressPercent: calculateProgress(s.CurrentAmount, s.TargetAmount),
			EstimatedDays:   CalculateEstimatedDays(s.CurrentAmount, s.TargetAmount, s.DailyAmount),
		}

		// Get recent deposits
		recentTxns, err := h.savingRepo.GetRecentTransactions(s.ID, 3)
		if err == nil && recentTxns != nil {
			detail.RecentTxns = recentTxns
		} else {
			detail.RecentTxns = []models.SavingsTransaction{}
		}

		goals = append(goals, detail)
	}

	utils.OK(c, "Daftar tabungan berhasil diambil", models.SavingsListResponse{
		TotalSaved:  totalSaved,
		TotalTarget: totalTarget,
		Goals:       goals,
	})
}

// GET /api/v1/driver/savings/:id
func (h *SavingHandler) Get(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID tabungan tidak valid")
		return
	}

	savings, err := h.savingRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Tabungan tidak ditemukan")
		return
	}

	if savings.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke tabungan ini")
		return
	}

	// Parse pagination
	page := 1
	limit := 20
	if p := c.Query("page"); p != "" {
		fmt.Sscanf(p, "%d", &page)
	}
	if l := c.Query("limit"); l != "" {
		fmt.Sscanf(l, "%d", &limit)
	}
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	txns, total, err := h.savingRepo.ListTransactions(id, limit, offset)
	if err != nil {
		txns = []models.SavingsTransaction{}
	}
	if txns == nil {
		txns = []models.SavingsTransaction{}
	}

	detail := models.SavingsGoalDetail{
		Savings:          *savings,
		ProgressPercent:  calculateProgress(savings.CurrentAmount, savings.TargetAmount),
		EstimatedDays:    CalculateEstimatedDays(savings.CurrentAmount, savings.TargetAmount, savings.DailyAmount),
		TransactionCount: total,
		Transactions:     txns,
	}

	utils.OK(c, "Detail tabungan berhasil diambil", detail)
}

// PUT /api/v1/driver/savings/:id
func (h *SavingHandler) Update(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID tabungan tidak valid")
		return
	}

	savings, err := h.savingRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Tabungan tidak ditemukan")
		return
	}

	if savings.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke tabungan ini")
		return
	}

	var req models.SavingsUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	if req.DailyAmount != nil {
		savings.DailyAmount = *req.DailyAmount
	}
	if req.AutoSave != nil {
		savings.AutoSave = *req.AutoSave
	}
	if req.TargetAmount != nil {
		savings.TargetAmount = *req.TargetAmount
	}

	if err := h.savingRepo.Update(savings); err != nil {
		utils.InternalError(c, "Gagal mengupdate tabungan")
		return
	}

	utils.OK(c, "Tabungan berhasil diupdate", savings)
}

// POST /api/v1/driver/savings/:id/deposit
func (h *SavingHandler) Deposit(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID tabungan tidak valid")
		return
	}

	savings, err := h.savingRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Tabungan tidak ditemukan")
		return
	}

	if savings.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke tabungan ini")
		return
	}

	var req models.SavingsDepositRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	newAmount := savings.CurrentAmount + req.Amount

	// Create transaction record
	txn := &models.SavingsTransaction{
		SavingsID: savings.ID,
		Type:      models.SavingsTxnTypeDeposit,
		Amount:    req.Amount,
		Method:    models.SavingsTxnMethodManual,
		Status:    "completed",
	}

	if err := h.savingRepo.CreateTransaction(txn); err != nil {
		utils.InternalError(c, "Gagal menyimpan transaksi: "+err.Error())
		return
	}

	// Update current amount
	if err := h.savingRepo.UpdateAmount(savings.ID, newAmount); err != nil {
		utils.InternalError(c, "Gagal mengupdate saldo tabungan")
		return
	}

	savings.CurrentAmount = newAmount

	// Check if goal reached
	if newAmount >= savings.TargetAmount && savings.Status == models.SavingsStatusActive {
		savings.Status = models.SavingsStatusReached
		h.savingRepo.Update(savings)
	}

	utils.OK(c, "Setoran berhasil", gin.H{
		"transaction":    txn,
		"current_amount": newAmount,
		"progress":       calculateProgress(newAmount, savings.TargetAmount),
	})
}

// POST /api/v1/driver/savings/:id/withdraw
func (h *SavingHandler) Withdraw(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID tabungan tidak valid")
		return
	}

	savings, err := h.savingRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Tabungan tidak ditemukan")
		return
	}

	if savings.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke tabungan ini")
		return
	}

	var req models.SavingsWithdrawRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	// Validation: amount must not exceed current amount
	if req.Amount > savings.CurrentAmount {
		utils.BadRequest(c, fmt.Sprintf("Saldo tidak cukup. Saldo saat ini: Rp %.0f", savings.CurrentAmount))
		return
	}

	// Validation: Dana Darurat must leave minimum Rp 50,000
	if savings.GoalName == "Dana Darurat" {
		remaining := savings.CurrentAmount - req.Amount
		if remaining < 50000 {
			utils.BadRequest(c, "Dana Darurat harus menyisakan minimal Rp 50.000")
			return
		}
	}

	newAmount := savings.CurrentAmount - req.Amount

	var notes *string
	if req.Notes != "" {
		notes = &req.Notes
	}

	// Create transaction record
	txn := &models.SavingsTransaction{
		SavingsID: savings.ID,
		Type:      models.SavingsTxnTypeWithdrawal,
		Amount:    req.Amount,
		Method:    models.SavingsTxnMethodManual,
		Status:    "completed",
		Notes:     notes,
	}

	if err := h.savingRepo.CreateTransaction(txn); err != nil {
		utils.InternalError(c, "Gagal menyimpan transaksi: "+err.Error())
		return
	}

	// Update current amount
	if err := h.savingRepo.UpdateAmount(savings.ID, newAmount); err != nil {
		utils.InternalError(c, "Gagal mengupdate saldo tabungan")
		return
	}

	savings.CurrentAmount = newAmount

	utils.OK(c, "Penarikan berhasil", gin.H{
		"transaction":    txn,
		"current_amount": newAmount,
		"progress":       calculateProgress(newAmount, savings.TargetAmount),
	})
}

// PUT /api/v1/driver/savings/:id/pause
func (h *SavingHandler) Pause(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID tabungan tidak valid")
		return
	}

	savings, err := h.savingRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Tabungan tidak ditemukan")
		return
	}

	if savings.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke tabungan ini")
		return
	}

	savings.AutoSave = false
	savings.Status = models.SavingsStatusPaused

	if err := h.savingRepo.Update(savings); err != nil {
		utils.InternalError(c, "Gagal menjeda tabungan")
		return
	}

	utils.OK(c, "Tabungan berhasil dijeda", savings)
}

// PUT /api/v1/driver/savings/:id/resume
func (h *SavingHandler) Resume(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID tabungan tidak valid")
		return
	}

	savings, err := h.savingRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Tabungan tidak ditemukan")
		return
	}

	if savings.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke tabungan ini")
		return
	}

	savings.AutoSave = true
	savings.Status = models.SavingsStatusActive

	if err := h.savingRepo.Update(savings); err != nil {
		utils.InternalError(c, "Gagal melanjutkan tabungan")
		return
	}

	utils.OK(c, "Tabungan berhasil dilanjutkan", savings)
}

// Helper functions

func calculateProgress(current, target float64) int {
	if target <= 0 {
		return 0
	}
	pct := int((current / target) * 100)
	if pct > 100 {
		pct = 100
	}
	return pct
}

// CalculateEstimatedDays returns the number of days to reach the target
func CalculateEstimatedDays(current, target, dailyAmount float64) int {
	if dailyAmount <= 0 {
		return 0
	}
	remaining := target - current
	if remaining <= 0 {
		return 0
	}
	return int(math.Ceil(remaining / dailyAmount))
}

// FormatRupiah formats a number as Rupiah string
func FormatRupiah(amount float64) string {
	return fmt.Sprintf("Rp %.0f", amount)
}

// FormatDateShort formats a time for display
func FormatDateShort(t time.Time) string {
	return t.Format("2006-01-02")
}
