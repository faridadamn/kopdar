package handlers

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/services"
	"github.com/kopdar/backend/internal/utils"
)

type ProfileHandler struct {
	profileRepo  *repository.ProfileRepository
	driverRepo   *repository.DriverRepository
	userRepo     *repository.UserRepository
	pointsSvc    *services.PointsService
	uploadDir    string
}

func NewProfileHandler(
	profileRepo *repository.ProfileRepository,
	driverRepo *repository.DriverRepository,
	userRepo *repository.UserRepository,
	pointsSvc *services.PointsService,
	uploadDir string,
) *ProfileHandler {
	return &ProfileHandler{
		profileRepo: profileRepo,
		driverRepo:  driverRepo,
		userRepo:    userRepo,
		pointsSvc:   pointsSvc,
		uploadDir:   uploadDir,
	}
}

// GET /api/v1/driver/profile
func (h *ProfileHandler) GetProfile(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	user, err := h.userRepo.FindByID(userID)
	if err != nil {
		utils.NotFound(c, "Data user tidak ditemukan")
		return
	}

	platforms, _ := h.profileRepo.GetDriverPlatforms(driver.ID)
	if platforms == nil {
		platforms = []models.DriverPlatform{}
	}

	// Get stats
	stats, _ := h.profileRepo.GetDriverStats(driver.ID)
	if stats == nil {
		stats = &models.ProfileStats{}
	}

	// Enrich with points and level
	dp, _ := h.profileRepo.GetOrCreatePoints(driver.ID)
	if dp != nil {
		stats.Level = dp.Level
		stats.Points = dp.Points
		nextLevel, pointsNeeded := h.pointsSvc.GetNextLevel(dp.Level, dp.Points)
		stats.NextLevel = nextLevel
		stats.PointsToNextLevel = pointsNeeded
	} else {
		stats.Level = models.LevelBronze
		stats.NextLevel = models.LevelSilver
		stats.PointsToNextLevel = models.LevelThresholds[models.LevelSilver]
	}

	if driver.ReferralCode != nil {
		stats.ReferralCode = *driver.ReferralCode
	}

	stats.MemberSince = driver.CreatedAt.Format("2006-01-02")

	// Membership card
	memberID := fmt.Sprintf("KPD-%d-%05d", driver.CreatedAt.Year(), driver.ID.ID()%100000)
	membershipCard := models.MembershipCard{
		ID:          memberID,
		QRData:      fmt.Sprintf("https://kopdar.app/verify/%s", memberID),
		Level:       stats.Level,
		MemberSince: stats.MemberSince,
	}

	utils.OK(c, "Profil berhasil diambil", models.ProfileResponse{
		Driver:         *driver,
		User:           *user,
		Platforms:      platforms,
		Stats:          *stats,
		MembershipCard: membershipCard,
	})
}

// PUT /api/v1/driver/profile/photo
func (h *ProfileHandler) UpdatePhoto(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	file, err := c.FormFile("photo")
	if err != nil {
		utils.BadRequest(c, "File foto tidak ditemukan")
		return
	}

	// Validate file size (max 5MB)
	if file.Size > 5*1024*1024 {
		utils.BadRequest(c, "Ukuran foto maksimal 5MB")
		return
	}

	// Validate file type
	ext := filepath.Ext(file.Filename)
	allowedExts := map[string]bool{".jpg": true, ".jpeg": true, ".png": true}
	if !allowedExts[ext] {
		utils.BadRequest(c, "Format foto harus JPG atau PNG")
		return
	}

	// Generate unique filename
	filename := fmt.Sprintf("profile_%s_%d%s", driver.ID.String()[:8], time.Now().Unix(), ext)
	profileDir := filepath.Join(h.uploadDir, "profiles")
	os.MkdirAll(profileDir, 0755)

	savePath := filepath.Join(profileDir, filename)
	if err := c.SaveUploadedFile(file, savePath); err != nil {
		utils.InternalError(c, "Gagal menyimpan foto")
		return
	}

	photoURL := fmt.Sprintf("/uploads/profiles/%s", filename)

	// Update both driver selfie and user avatar
	if err := h.profileRepo.UpdateDriverPhoto(driver.ID, photoURL); err != nil {
		utils.InternalError(c, "Gagal mengupdate foto profil")
		return
	}
	h.profileRepo.UpdateUserAvatar(userID, photoURL)

	utils.OK(c, "Foto profil berhasil diupdate", gin.H{
		"photo_url": photoURL,
	})
}

// GET /api/v1/driver/level
func (h *ProfileHandler) GetLevel(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	dp, err := h.profileRepo.GetOrCreatePoints(driver.ID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil data level")
		return
	}

	// Get history
	history, _ := h.profileRepo.GetPointsHistory(driver.ID, 50)
	historyItems := make([]models.PointsHistoryItem, 0, len(history))
	for _, h := range history {
		historyItems = append(historyItems, models.PointsHistoryItem{
			Action: h.Action,
			Points: h.Points,
			Date:   h.CreatedAt.Format("2006-01-02 15:04"),
		})
	}

	nextLevel, pointsNeeded := h.pointsSvc.GetNextLevel(dp.Level, dp.Points)

	utils.OK(c, "Data level berhasil diambil", models.LevelInfoResponse{
		CurrentLevel:  dp.Level,
		Points:        dp.Points,
		PointsHistory: historyItems,
		NextLevel:     nextLevel,
		PointsNeeded:  pointsNeeded,
		Benefits:      models.LevelBenefits,
	})
}

// POST /api/v1/driver/level/add-points (internal use)
func (h *ProfileHandler) AddPoints(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.AddPointsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	resp, err := h.pointsSvc.AddPoints(driver.ID, req.Action)
	if err != nil {
		utils.InternalError(c, "Gagal menambahkan points")
		return
	}

	utils.OK(c, "Points berhasil ditambahkan", resp)
}
