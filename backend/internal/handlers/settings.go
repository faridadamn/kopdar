package handlers

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type SettingsHandler struct {
	profileRepo *repository.ProfileRepository
	driverRepo  *repository.DriverRepository
}

func NewSettingsHandler(
	profileRepo *repository.ProfileRepository,
	driverRepo *repository.DriverRepository,
) *SettingsHandler {
	return &SettingsHandler{
		profileRepo: profileRepo,
		driverRepo:  driverRepo,
	}
}

// GET /api/v1/driver/settings
func (h *SettingsHandler) Get(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	settings, err := h.profileRepo.GetOrCreateSettings(driver.ID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil pengaturan")
		return
	}

	utils.OK(c, "Pengaturan berhasil diambil", settings)
}

// PUT /api/v1/driver/settings
func (h *SettingsHandler) Update(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.SettingsUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	settings, err := h.profileRepo.GetOrCreateSettings(driver.ID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil pengaturan")
		return
	}

	// Apply partial updates
	if req.Language != nil {
		settings.Language = *req.Language
	}
	if req.ZoneID != nil {
		settings.ZoneID = *req.ZoneID
	}
	if req.AutoSaveEnabled != nil {
		settings.AutoSaveEnabled = *req.AutoSaveEnabled
	}
	if req.AutoSaveAmount != nil {
		settings.AutoSaveAmount = *req.AutoSaveAmount
	}
	if req.Notifications != nil {
		settings.Notifications = *req.Notifications
	}
	if req.QuietHours != nil {
		settings.QuietHours = *req.QuietHours
	}
	if req.BiometricEnabled != nil {
		settings.BiometricEnabled = *req.BiometricEnabled
	}

	if err := h.profileRepo.UpdateSettings(settings); err != nil {
		utils.InternalError(c, "Gagal mengupdate pengaturan")
		return
	}

	utils.OK(c, "Pengaturan berhasil diupdate", settings)
}

// POST /api/v1/driver/settings/test-notification
func (h *SettingsHandler) TestNotification(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	// Verify driver exists
	_, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	// In a real system, this would send a push notification
	// For now, we just confirm the request
	utils.OK(c, "Notifikasi test berhasil dikirim", gin.H{
		"sent": true,
	})
}

// DELETE /api/v1/driver/account
func (h *SettingsHandler) DeleteAccount(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	var req models.DeleteAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	if err := h.profileRepo.SoftDeleteAccount(userID); err != nil {
		utils.InternalError(c, "Gagal menghapus akun")
		return
	}

	utils.OK(c, "Akun berhasil dihapus", gin.H{
		"deleted": true,
		"message": "Akun berhasil dihapus",
	})
}
