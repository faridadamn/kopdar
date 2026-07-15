package handlers

import (
	"fmt"
	"math"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type PinjolHandler struct {
	pinjolRepo *repository.PinjolRepository
	savingRepo *repository.SavingRepository
	driverRepo *repository.DriverRepository
}

func NewPinjolHandler(pinjolRepo *repository.PinjolRepository, savingRepo *repository.SavingRepository, driverRepo *repository.DriverRepository) *PinjolHandler {
	return &PinjolHandler{
		pinjolRepo: pinjolRepo,
		savingRepo: savingRepo,
		driverRepo: driverRepo,
	}
}

// POST /api/v1/driver/pinjol
func (h *PinjolHandler) Create(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.PinjolCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	// Validate dates
	startDate, err := time.Parse("2006-01-02", req.StartDate)
	if err != nil {
		utils.BadRequest(c, "Format tanggal mulai tidak valid (YYYY-MM-DD)")
		return
	}
	endDate, err := time.Parse("2006-01-02", req.EndDate)
	if err != nil {
		utils.BadRequest(c, "Format tanggal berakhir tidak valid (YYYY-MM-DD)")
		return
	}
	if endDate.Before(startDate) {
		utils.BadRequest(c, "Tanggal berakhir harus setelah tanggal mulai")
		return
	}

	// Calculate risk level based on interest rate
	riskLevel := calculateRiskLevel(req.InterestRate)

	record := &models.PinjolRecord{
		DriverID:           driver.ID,
		AppName:            req.AppName,
		Principal:          req.Principal,
		InterestRate:       req.InterestRate,
		MonthlyInstallment: req.MonthlyInstallment,
		OutstandingAmount:  req.Principal, // Initial outstanding = principal
		TotalPaidInterest:  0,
		StartDate:          req.StartDate,
		EndDate:            req.EndDate,
		RiskLevel:          riskLevel,
	}

	if err := h.pinjolRepo.Create(record); err != nil {
		utils.InternalError(c, "Gagal menyimpan catatan pinjaman: "+err.Error())
		return
	}

	utils.Created(c, "Catatan pinjaman berhasil disimpan", record)
}

// GET /api/v1/driver/pinjol
func (h *PinjolHandler) List(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	records, err := h.pinjolRepo.ListByDriver(driver.ID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil daftar pinjaman")
		return
	}

	if records == nil {
		records = []models.PinjolRecord{}
	}

	// Get driver's average monthly income for debt-to-income ratio
	avgIncome, _ := h.savingRepo.GetDriverAvgMonthlyIncome(driver.ID)

	var totalOutstanding, totalPaidInterest, totalMonthlyInstall float64
	riskSummary := models.RiskSummary{}
	recordDetails := make([]models.PinjolRecordDetail, 0, len(records))

	for _, r := range records {
		totalOutstanding += r.OutstandingAmount
		totalPaidInterest += r.TotalPaidInterest
		totalMonthlyInstall += r.MonthlyInstallment

		switch r.RiskLevel {
		case models.RiskLevelSafe:
			riskSummary.Safe++
		case models.RiskLevelWarning:
			riskSummary.Warning++
		case models.RiskLevelDanger:
			riskSummary.Danger++
		}

		detail := buildPinjolDetail(r)
		recordDetails = append(recordDetails, detail)
	}

	// Calculate debt-to-income ratio
	var dtiRatio float64
	if avgIncome > 0 {
		dtiRatio = math.Round((totalMonthlyInstall/avgIncome)*100) / 100
	}

	// Generate recommendations
	recommendations := generatePinjolRecommendations(records, avgIncome)

	utils.OK(c, "Daftar pinjaman berhasil diambil", models.PinjolListResponse{
		TotalOutstanding:    totalOutstanding,
		TotalPaidInterest:   totalPaidInterest,
		TotalMonthlyInstall: totalMonthlyInstall,
		DebtToIncomeRatio:   dtiRatio,
		RiskSummary:         riskSummary,
		Records:             recordDetails,
		Recommendations:     recommendations,
	})
}

// GET /api/v1/driver/pinjol/:id
func (h *PinjolHandler) Get(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID pinjaman tidak valid")
		return
	}

	record, err := h.pinjolRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Catatan pinjaman tidak ditemukan")
		return
	}

	if record.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke catatan pinjaman ini")
		return
	}

	detail := buildPinjolDetail(*record)

	utils.OK(c, "Detail pinjaman berhasil diambil", detail)
}

// PUT /api/v1/driver/pinjol/:id
func (h *PinjolHandler) Update(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID pinjaman tidak valid")
		return
	}

	record, err := h.pinjolRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Catatan pinjaman tidak ditemukan")
		return
	}

	if record.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke catatan pinjaman ini")
		return
	}

	var req models.PinjolUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	if req.OutstandingAmount != nil {
		record.OutstandingAmount = *req.OutstandingAmount
	}
	if req.InterestRate != nil {
		record.InterestRate = *req.InterestRate
		record.RiskLevel = calculateRiskLevel(*req.InterestRate)
	}

	if err := h.pinjolRepo.Update(record); err != nil {
		utils.InternalError(c, "Gagal mengupdate catatan pinjaman")
		return
	}

	utils.OK(c, "Catatan pinjaman berhasil diupdate", record)
}

// DELETE /api/v1/driver/pinjol/:id
func (h *PinjolHandler) Delete(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID pinjaman tidak valid")
		return
	}

	record, err := h.pinjolRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Catatan pinjaman tidak ditemukan")
		return
	}

	if record.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke catatan pinjaman ini")
		return
	}

	if err := h.pinjolRepo.Delete(id); err != nil {
		utils.InternalError(c, "Gagal menghapus catatan pinjaman")
		return
	}

	utils.OK(c, "Catatan pinjaman berhasil dihapus", gin.H{
		"id":      id,
		"message": fmt.Sprintf("Catatan pinjaman %s berhasil dihapus", id.String()[:8]),
	})
}

// GET /api/v1/driver/pinjol/:id/simulate
func (h *PinjolHandler) Simulate(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID pinjaman tidak valid")
		return
	}

	record, err := h.pinjolRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Catatan pinjaman tidak ditemukan")
		return
	}

	if record.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke catatan pinjaman ini")
		return
	}

	// Parse months query param (default 3)
	months := 3
	if m := c.Query("months"); m != "" {
		if parsed, err := strconv.Atoi(m); err == nil && parsed >= 1 && parsed <= 12 {
			months = parsed
		}
	}

	simulation := calculatePayoffSimulation(record, months)

	// Check if driver can afford from savings
	savings, _ := h.savingRepo.ListByDriver(driver.ID)
	var totalSavings float64
	for _, s := range savings {
		totalSavings += s.CurrentAmount
	}
	simulation.CanAffordFromSavings = totalSavings >= record.OutstandingAmount

	// Generate recommendation text
	if simulation.CanAffordFromSavings {
		simulation.Recommendation = fmt.Sprintf(
			"Jika lunasi dalam %d bulan, kamu hemat Rp %.0f bunga. Saldo tabunganmu cukup untuk melunasi!",
			months, simulation.InterestSavedVsFullTerm,
		)
	} else {
		simulation.Recommendation = fmt.Sprintf(
			"Jika lunasi dalam %d bulan, kamu hemat Rp %.0f bunga",
			months, simulation.InterestSavedVsFullTerm,
		)
	}

	utils.OK(c, "Simulasi pelunasan berhasil", simulation)
}

// Helper functions

func calculateRiskLevel(interestRate float64) string {
	if interestRate < 1.5 {
		return models.RiskLevelSafe
	} else if interestRate <= 2.0 {
		return models.RiskLevelWarning
	}
	return models.RiskLevelDanger
}

func buildPinjolDetail(r models.PinjolRecord) models.PinjolRecordDetail {
	monthsRemaining := calculateMonthsRemaining(r.EndDate)
	totalInterestFullTerm := calculateTotalInterest(r)

	detail := models.PinjolRecordDetail{
		PinjolRecord:              r,
		MonthsRemaining:           monthsRemaining,
		TotalInterestIfFullTerm:   totalInterestFullTerm,
	}

	// Calculate early payoff savings
	if r.OutstandingAmount > 0 && r.InterestRate > 0 {
		payoffNext := calculatePayoffSavings(r, 1)
		payoff3 := calculatePayoffSavings(r, 3)

		detail.SavingsIfEarlyPayoff = &models.EarlyPayoffSavings{
			PayoffNextMonth: &models.PayoffOption{InterestSaved: payoffNext},
			PayoffIn3Months: &models.PayoffOption{InterestSaved: payoff3},
		}
	}

	return detail
}

func calculateMonthsRemaining(endDateStr string) int {
	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		return 0
	}
	now := time.Now()
	if endDate.Before(now) {
		return 0
	}
	months := 0
	for d := now; d.Before(endDate); d = d.AddDate(0, 1, 0) {
		months++
	}
	return months
}

func calculateTotalInterest(r models.PinjolRecord) float64 {
	// Total interest = monthly_installment * months_remaining - outstanding_amount
	monthsRemaining := calculateMonthsRemaining(r.EndDate)
	totalPayments := r.MonthlyInstallment * float64(monthsRemaining)
	totalInterest := totalPayments - r.OutstandingAmount
	if totalInterest < 0 {
		totalInterest = 0
	}
	return totalInterest
}

func calculatePayoffSavings(r models.PinjolRecord, payoffMonths int) float64 {
	// Interest saved = total_interest_full_term - interest_paid_in_payoff_months
	totalInterestFull := calculateTotalInterest(r)
	monthsRemaining := calculateMonthsRemaining(r.EndDate)

	if payoffMonths >= monthsRemaining {
		return 0
	}

	// Simplified: interest for payoff period
	interestPerMonth := (r.InterestRate / 100) * r.OutstandingAmount / float64(monthsRemaining)
	interestDuringPayoff := interestPerMonth * float64(payoffMonths)
	savings := totalInterestFull - interestDuringPayoff
	if savings < 0 {
		savings = 0
	}
	return math.Round(savings)
}

func calculatePayoffSimulation(r *models.PinjolRecord, months int) models.PayoffSimulation {
	monthsRemaining := calculateMonthsRemaining(r.EndDate)
	totalInterestFull := calculateTotalInterest(*r)

	// Total payments = monthly_installment * payoff_months
	totalPayments := r.MonthlyInstallment * float64(months)
	if totalPayments > r.OutstandingAmount {
		totalPayments = r.OutstandingAmount
	}

	// Interest in payoff period (simplified)
	interestPerMonth := (r.InterestRate / 100) * r.OutstandingAmount
	if monthsRemaining > 0 {
		interestPerMonth = interestPerMonth / float64(monthsRemaining)
	}
	totalInterest := interestPerMonth * float64(months)
	if totalInterest > totalInterestFull {
		totalInterest = totalInterestFull
	}

	interestSaved := totalInterestFull - totalInterest
	if interestSaved < 0 {
		interestSaved = 0
	}

	return models.PayoffSimulation{
		Months:                  months,
		TotalPayments:           math.Round(totalPayments),
		TotalInterest:           math.Round(totalInterest),
		InterestSavedVsFullTerm: math.Round(interestSaved),
	}
}

func generatePinjolRecommendations(records []models.PinjolRecord, avgIncome float64) []string {
	var recs []string

	if len(records) == 0 {
		return recs
	}

	// Find highest interest rate record
	var highestRate *models.PinjolRecord
	for i := range records {
		if records[i].OutstandingAmount > 0 {
			if highestRate == nil || records[i].InterestRate > highestRate.InterestRate {
				highestRate = &records[i]
			}
		}
	}

	if highestRate != nil {
		interestSaved := calculatePayoffSavings(*highestRate, 1)
		if interestSaved > 0 {
			recs = append(recs, fmt.Sprintf(
				"Lunasi %s dulu — hemat Rp %.0f bunga",
				highestRate.AppName, interestSaved,
			))
		}
	}

	// Check debt-to-income ratio
	if avgIncome > 0 {
		var totalMonthly float64
		for _, r := range records {
			totalMonthly += r.MonthlyInstallment
		}
		dti := totalMonthly / avgIncome
		if dti > 0.3 {
			recs = append(recs, fmt.Sprintf(
				"Rasio cicilanmu %.0f%% dari penghasilan — idealnya di bawah 30%%. Kurangi pinjaman baru.",
				dti*100,
			))
		}
	}

	// Count danger-level records
	dangerCount := 0
	for _, r := range records {
		if r.RiskLevel == models.RiskLevelDanger && r.OutstandingAmount > 0 {
			dangerCount++
		}
	}
	if dangerCount > 0 {
		recs = append(recs, fmt.Sprintf(
			"Kamu punya %d pinjaman berisiko tinggi (>2%% bunga). Prioritaskan pelunasan.",
			dangerCount,
		))
	}

	if len(recs) == 0 {
		recs = []string{}
	}

	return recs
}
