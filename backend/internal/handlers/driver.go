package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

const maxRegistrationUploadBytes int64 = 5 << 20

type DriverHandler struct {
	driverRepo *repository.DriverRepository
	userRepo   *repository.UserRepository
	uploadDir  string
}

func NewDriverHandler(driverRepo *repository.DriverRepository, userRepo *repository.UserRepository, uploadDir string) *DriverHandler {
	return &DriverHandler{driverRepo: driverRepo, userRepo: userRepo, uploadDir: uploadDir}
}

func (h *DriverHandler) Register(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)
	if _, err := h.driverRepo.FindByUserID(userID); err == nil {
		utils.Conflict(c, "Driver profile already exists")
		return
	}

	var req models.DriverRegisterRequest
	if err := c.ShouldBind(&req); err != nil {
		utils.BadRequest(c, "Invalid or missing registration fields: "+err.Error())
		return
	}

	dob, err := time.Parse("2006-01-02", req.DateOfBirth)
	if err != nil || dob.After(time.Now().AddDate(-17, 0, 0)) {
		utils.BadRequest(c, "Invalid date of birth or minimum age is 17 years")
		return
	}

	var platforms []string
	if err := json.Unmarshal([]byte(req.Platforms), &platforms); err != nil || len(platforms) == 0 {
		utils.BadRequest(c, "At least one valid platform is required")
		return
	}

	uploaded := make([]string, 0, 3)
	cleanup := func() {
		for _, path := range uploaded {
			_ = os.Remove(filepath.Join(h.uploadDir, path))
		}
	}

	ktpURL, err := h.saveUploadedFile(c, "ktp_photo", userID.String())
	if err != nil {
		utils.BadRequest(c, "Invalid KTP photo: "+err.Error())
		return
	}
	uploaded = append(uploaded, ktpURL)

	selfieURL, err := h.saveUploadedFile(c, "selfie_photo", userID.String())
	if err != nil {
		cleanup()
		utils.BadRequest(c, "Invalid selfie photo: "+err.Error())
		return
	}
	uploaded = append(uploaded, selfieURL)

	stnkURL, err := h.saveUploadedFile(c, "stnk_photo", userID.String())
	if err != nil {
		cleanup()
		utils.BadRequest(c, "Invalid STNK photo: "+err.Error())
		return
	}
	uploaded = append(uploaded, stnkURL)

	driver := &models.Driver{
		UserID:                  userID,
		NIK:                     &req.NIK,
		DateOfBirth:             &dob,
		Address:                 &req.Address,
		City:                    &req.City,
		Province:                &req.Province,
		PostalCode:              optionalString(req.PostalCode),
		KTPPhotoURL:             &ktpURL,
		SelfiePhotoURL:          &selfieURL,
		STNKPhotoURL:            &stnkURL,
		VehicleType:             &req.VehicleType,
		VehicleBrand:            &req.VehicleBrand,
		VehicleModel:            &req.VehicleModel,
		VehicleColor:            &req.VehicleColor,
		VehiclePlate:            &req.VehiclePlate,
		VehicleYear:             &req.VehicleYear,
		BankName:                &req.BankName,
		BankAccountNumber:       &req.BankAccountNumber,
		BankAccountName:         &req.BankAccountName,
		EmergencyContactName:    &req.EmergencyContactName,
		EmergencyContactPhone:   &req.EmergencyContactPhone,
		VerificationStatus:      models.VerificationPending,
	}
	code := strings.ToUpper(uuid.New().String()[:8])
	driver.ReferralCode = &code

	if err := h.driverRepo.RegisterDriver(req.FullName, driver, platforms); err != nil {
		cleanup()
		utils.InternalError(c, "Failed to create driver registration: "+err.Error())
		return
	}

	utils.Created(c, "Driver registration submitted", gin.H{
		"driver_id":            driver.ID,
		"verification_status": driver.VerificationStatus,
		"referral_code":        driver.ReferralCode,
	})
}

func (h *DriverHandler) GetProfile(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)
	user, err := h.userRepo.FindByID(userID)
	if err != nil {
		utils.NotFound(c, "User not found")
		return
	}
	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.OK(c, "Profile retrieved", gin.H{"user": user, "driver": nil})
		return
	}
	utils.OK(c, "Profile retrieved", gin.H{"user": user, "driver": driver})
}

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
	if req.FullName != nil {
		if user, err := h.userRepo.FindByID(userID); err == nil {
			user.FullName = req.FullName
			_ = h.userRepo.Update(user)
		}
	}
	if req.Address != nil { driver.Address = req.Address }
	if req.City != nil { driver.City = req.City }
	if req.Province != nil { driver.Province = req.Province }
	if req.PostalCode != nil { driver.PostalCode = req.PostalCode }
	if req.VehicleType != nil { driver.VehicleType = req.VehicleType }
	if req.VehicleBrand != nil { driver.VehicleBrand = req.VehicleBrand }
	if req.VehicleModel != nil { driver.VehicleModel = req.VehicleModel }
	if req.VehicleColor != nil { driver.VehicleColor = req.VehicleColor }
	if req.VehiclePlate != nil { driver.VehiclePlate = req.VehiclePlate }
	if req.VehicleYear != nil { driver.VehicleYear = req.VehicleYear }
	if req.BankName != nil { driver.BankName = req.BankName }
	if req.BankAccountNumber != nil { driver.BankAccountNumber = req.BankAccountNumber }
	if req.BankAccountName != nil { driver.BankAccountName = req.BankAccountName }
	if req.EmergencyContactName != nil { driver.EmergencyContactName = req.EmergencyContactName }
	if req.EmergencyContactPhone != nil { driver.EmergencyContactPhone = req.EmergencyContactPhone }
	if err := h.driverRepo.Update(driver); err != nil {
		utils.InternalError(c, "Failed to update profile")
		return
	}
	utils.OK(c, "Profile updated", driver)
}

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
		return "", fmt.Errorf("field is required")
	}
	defer file.Close()
	if header.Size <= 0 || header.Size > maxRegistrationUploadBytes {
		return "", fmt.Errorf("file must be between 1 byte and 5 MB")
	}

	sniff := make([]byte, 512)
	n, err := file.Read(sniff)
	if err != nil && err != io.EOF {
		return "", fmt.Errorf("unable to inspect file")
	}
	contentType := http.DetectContentType(sniff[:n])
	extensions := map[string]string{
		"image/jpeg": ".jpg",
		"image/png":  ".png",
		"image/webp": ".webp",
	}
	ext, ok := extensions[contentType]
	if !ok {
		return "", fmt.Errorf("only JPEG, PNG, or WebP images are allowed")
	}
	if _, err := file.Seek(0, io.SeekStart); err != nil {
		return "", fmt.Errorf("unable to read file")
	}

	uploadPath := filepath.Join(h.uploadDir, "drivers", prefix)
	if err := os.MkdirAll(uploadPath, 0750); err != nil {
		return "", fmt.Errorf("failed to create upload directory")
	}
	filename := fmt.Sprintf("%s_%s%s", fieldName, uuid.NewString(), ext)
	fullPath := filepath.Join(uploadPath, filename)
	dst, err := os.OpenFile(fullPath, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0640)
	if err != nil {
		return "", fmt.Errorf("failed to create destination file")
	}
	defer dst.Close()
	written, err := io.Copy(dst, io.LimitReader(file, maxRegistrationUploadBytes+1))
	if err != nil || written > maxRegistrationUploadBytes {
		_ = os.Remove(fullPath)
		return "", fmt.Errorf("failed to save valid image")
	}
	return filepath.Join("drivers", prefix, filename), nil
}

func optionalString(value string) *string {
	value = strings.TrimSpace(value)
	if value == "" { return nil }
	return &value
}
