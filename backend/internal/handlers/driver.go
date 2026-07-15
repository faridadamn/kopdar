package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type DriverHandler struct {
	driverRepo *repository.DriverRepository
	userRepo   *repository.UserRepository
	uploadDir  string
}

func NewDriverHandler(driverRepo *repository.DriverRepository, userRepo *repository.UserRepository, uploadDir string) *DriverHandler {
	return &DriverHandler{
		driverRepo: driverRepo,
		userRepo:   userRepo,
		uploadDir:  uploadDir,
	}
}

// POST /api/v1/driver/register
func (h *DriverHandler) Register(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	// Parse multipart form
	var req models.DriverRegisterRequest
	if err := c.ShouldBind(&req); err != nil {
		utils.BadRequest(c, "Missing required fields: "+err.Error())
		return
	}

	// Parse date of birth
	dob, err := time.Parse("2006-01-02", req.DateOfBirth)
	if err != nil {
		utils.BadRequest(c, "Invalid date format, use YYYY-MM-DD")
		return
	}

	// Save uploaded files
	ktpURL, err := h.saveUploadedFile(c, "ktp_photo", userID.String())
	if err != nil {
		utils.BadRequest(c, "Failed to save KTP photo: "+err.Error())
		return
	}

	selfieURL, err := h.saveUploadedFile(c, "selfie_photo", userID.String())
	if err != nil {
		utils.BadRequest(c, "Failed to save selfie photo: "+err.Error())
		return
	}

	stnkURL, err := h.saveUploadedFile(c, "stnk_photo", userID.String())
	if err != nil {
		utils.BadRequest(c, "Failed to save STNK photo: "+err.Error())
		return
	}

	// Update user full name
	user, err := h.userRepo.FindByID(userID)
	if err != nil {
		utils.InternalError(c, "User not found")
		return
	}
	user.FullName = &req.FullName
	if err := h.userRepo.Update(user); err != nil {
		utils.InternalError(c, "Failed to update user profile")
		return
	}

	// Create driver profile
	driver := &models.Driver{
		UserID:               userID,
		NIK:                  &req.NIK,
		DateOfBirth:          &dob,
		Address:              &req.Address,
		City:                 &req.City,
		Province:             &req.Province,
		PostalCode:           &req.PostalCode,
		KTPPhotoURL:          &ktpURL,
		SelfiePhotoURL:       &selfieURL,
		STNKPhotoURL:         &stnkURL,
		VehicleType:          &req.VehicleType,
		VehiclePlate:         &req.VehiclePlate,
		EmergencyContactName: &req.EmergencyContactName,
		EmergencyContactPhone: &req.EmergencyContactPhone,
		VerificationStatus:   models.VerificationPending,
	}

	if req.VehicleYear > 0 {
		driver.VehicleYear = &req.VehicleYear
	}

	// Generate referral code
	code := uuid.New().String()[:8]
	driver.ReferralCode = &code

	if err := h.driverRepo.Create(driver); err != nil {
		utils.InternalError(c, "Failed to create driver profile: "+err.Error())
		return
	}

	// Add platforms if provided
	if req.Platforms != "" {
		var platforms []string
		if json.Unmarshal([]byte(req.Platforms), &platforms) == nil {
			for _, p := range platforms {
				_ = h.driverRepo.AddPlatform(driver.ID, p)
			}
		}
	}

	utils.Created(c, "Driver registration submitted", gin.H{
		"driver_id":      driver.ID,
		"verification_status": driver.VerificationStatus,
		"referral_code":  driver.ReferralCode,
	})
}

// GET /api/v1/driver/profile
func (h *DriverHandler) GetProfile(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	user, err := h.userRepo.FindByID(userID)
	if err != nil {
		utils.NotFound(c, "User not found")
		return
	}

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		// User exists but no driver profile yet
		utils.OK(c, "Profile retrieved", gin.H{
			"user":   user,
			"driver": nil,
		})
		return
	}

	utils.OK(c, "Profile retrieved", gin.H{
		"user":   user,
		"driver": driver,
	})
}

// PUT /api/v1/driver/profile
func (h *DriverHandler) UpdateProfile(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	var req models.DriverProfileUpdate
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Invalid request body")
		return
	}

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Driver profile not found")
		return
	}

	// Update user name if provided
	if req.FullName != nil {
		user, _ := h.userRepo.FindByID(userID)
		user.FullName = req.FullName
		_ = h.userRepo.Update(user)
	}

	// Update driver fields
	if req.Address != nil {
		driver.Address = req.Address
	}
	if req.City != nil {
		driver.City = req.City
	}
	if req.Province != nil {
		driver.Province = req.Province
	}
	if req.PostalCode != nil {
		driver.PostalCode = req.PostalCode
	}
	if req.VehicleType != nil {
		driver.VehicleType = req.VehicleType
	}
	if req.VehiclePlate != nil {
		driver.VehiclePlate = req.VehiclePlate
	}
	if req.VehicleYear != nil {
		driver.VehicleYear = req.VehicleYear
	}
	if req.EmergencyContactName != nil {
		driver.EmergencyContactName = req.EmergencyContactName
	}
	if req.EmergencyContactPhone != nil {
		driver.EmergencyContactPhone = req.EmergencyContactPhone
	}

	if err := h.driverRepo.Update(driver); err != nil {
		utils.InternalError(c, "Failed to update profile")
		return
	}

	utils.OK(c, "Profile updated", driver)
}

// GET /api/v1/driver/status
func (h *DriverHandler) GetStatus(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Driver profile not found. Please register first.")
		return
	}

	utils.OK(c, "Status retrieved", gin.H{
		"verification_status": driver.VerificationStatus,
		"rejection_reason":    driver.RejectionReason,
		"verified_at":         driver.VerifiedAt,
	})
}

func (h *DriverHandler) saveUploadedFile(c *gin.Context, fieldName, prefix string) (string, error) {
	file, header, err := c.Request.FormFile(fieldName)
	if err != nil {
		return "", fmt.Errorf("field %s is required", fieldName)
	}
	defer file.Close()

	// Create upload directory
	uploadPath := filepath.Join(h.uploadDir, "drivers", prefix)
	if err := os.MkdirAll(uploadPath, 0755); err != nil {
		return "", fmt.Errorf("failed to create upload directory")
	}

	// Generate unique filename
	ext := filepath.Ext(header.Filename)
	filename := fmt.Sprintf("%s_%d%s", fieldName, time.Now().UnixNano(), ext)
	fullPath := filepath.Join(uploadPath, filename)

	// Save file
	dst, err := os.Create(fullPath)
	if err != nil {
		return "", fmt.Errorf("failed to save file")
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		return "", fmt.Errorf("failed to write file")
	}

	return filepath.Join("drivers", prefix, filename), nil
}
