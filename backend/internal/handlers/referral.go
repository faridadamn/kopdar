package handlers

import (
	"fmt"
	"net/url"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/services"
	"github.com/kopdar/backend/internal/utils"
)

type ReferralHandler struct {
	profileRepo *repository.ProfileRepository
	driverRepo  *repository.DriverRepository
	pointsSvc   *services.PointsService
}

func NewReferralHandler(
	profileRepo *repository.ProfileRepository,
	driverRepo *repository.DriverRepository,
	pointsSvc *services.PointsService,
) *ReferralHandler {
	return &ReferralHandler{
		profileRepo: profileRepo,
		driverRepo:  driverRepo,
		pointsSvc:   pointsSvc,
	}
}

// GET /api/v1/driver/referral
func (h *ReferralHandler) GetInfo(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	referralCode := ""
	if driver.ReferralCode != nil {
		referralCode = *driver.ReferralCode
	}

	referrals, _ := h.profileRepo.GetReferralsByReferrer(driver.ID)
	if referrals == nil {
		referrals = []models.Referral{}
	}

	var totalBonus float64
	details := make([]models.ReferralDetail, 0, len(referrals))
	for _, ref := range referrals {
		totalBonus += ref.Bonus

		name, _ := h.profileRepo.GetUserName(ref.ReferredID)
		details = append(details, models.ReferralDetail{
			ID:     ref.ID.String(),
			Name:   name,
			Status: ref.Status,
			Bonus:  ref.Bonus,
			Date:   ref.CreatedAt.Format("2006-01-02"),
		})
	}

	utils.OK(c, "Data referral berhasil diambil", models.ReferralInfoResponse{
		ReferralCode:   referralCode,
		ReferralLink:   fmt.Sprintf("https://kopdar.app/invite/%s", referralCode),
		TotalReferrals: len(referrals),
		TotalBonus:     totalBonus,
		Referrals:      details,
	})
}

// POST /api/v1/driver/referral/apply
func (h *ReferralHandler) ApplyCode(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.ApplyReferralRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	// Check if already referred
	hasRef, _ := h.profileRepo.HasReferral(userID)
	if hasRef {
		utils.BadRequest(c, "Kamu sudah menggunakan kode referral sebelumnya")
		return
	}

	// Find referrer by code
	referrerDriver, err := h.profileRepo.GetDriverByReferralCode(req.ReferralCode)
	if err != nil {
		utils.BadRequest(c, "Kode referral tidak ditemukan")
		return
	}

	// Prevent self-referral
	if referrerDriver.UserID == userID {
		utils.BadRequest(c, "Tidak bisa menggunakan kode referral sendiri")
		return
	}

	// Create referral record
	bonusAmount := 25000.00
	ref := &models.Referral{
		ReferrerID:   referrerDriver.UserID,
		ReferredID:   userID,
		ReferralCode: req.ReferralCode,
		Bonus:        bonusAmount,
		Status:       models.ReferralStatusCompleted,
	}

	if err := h.profileRepo.CreateReferral(ref); err != nil {
		utils.InternalError(c, "Gagal menyimpan referral: "+err.Error())
		return
	}

	// Add points to referrer
	h.pointsSvc.AddPoints(referrerDriver.ID, "referral_success")

	utils.Created(c, "Kode referral berhasil digunakan! Selamat bergabung!", gin.H{
		"referral_code": req.ReferralCode,
		"bonus":         bonusAmount,
	})
}

// GET /api/v1/driver/referral/share
func (h *ReferralHandler) ShareContent(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	referralCode := ""
	if driver.ReferralCode != nil {
		referralCode = *driver.ReferralCode
	}

	message := fmt.Sprintf(
		"Bergabunglah dengan KopDar! Pakai kode referral ku: %s. Download: https://kopdar.app/invite/%s",
		referralCode, referralCode,
	)

	whatsappURL := fmt.Sprintf("https://wa.me/?text=%s", url.QueryEscape(message))
	smsURL := fmt.Sprintf("sms:?body=%s", url.QueryEscape(message))

	utils.OK(c, "Konten share berhasil dibuat", models.ShareContentResponse{
		Message:     message,
		WhatsAppURL: whatsappURL,
		SMSURL:      smsURL,
	})
}
