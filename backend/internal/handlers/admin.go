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

type AdminHandler struct {
	driverRepo *repository.DriverRepository
	userRepo   *repository.UserRepository
}

func NewAdminHandler(driverRepo *repository.DriverRepository, userRepo *repository.UserRepository) *AdminHandler {
	return &AdminHandler{
		driverRepo: driverRepo,
		userRepo:   userRepo,
	}
}

// GET /api/v1/admin/drivers/pending
func (h *AdminHandler) ListPendingDrivers(c *gin.Context) {
	var query models.PaginationQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		query.Page = 1
		query.PageSize = 20
	}

	if query.Page < 1 {
		query.Page = 1
	}
	if query.PageSize < 1 || query.PageSize > 100 {
		query.PageSize = 20
	}

	drivers, total, err := h.driverRepo.ListPending(query.Page, query.PageSize, query.Search)
	if err != nil {
		utils.InternalError(c, "Failed to fetch pending drivers")
		return
	}

 totalPages := int(total) / query.PageSize
	if int(total)%query.PageSize > 0 {
		totalPages++
	}

	utils.OK(c, "Pending drivers retrieved", models.PaginatedResponse{
		Data:       drivers,
		Page:       query.Page,
		PageSize:   query.PageSize,
		TotalItems: total,
		TotalPages: totalPages,
	})
}

// GET /api/v1/admin/drivers/:id
func (h *AdminHandler) GetDriverDetail(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "Invalid driver ID")
		return
	}

	driver, err := h.driverRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Driver not found")
		return
	}

	// Get user info too
	user, err := h.userRepo.FindByID(driver.UserID)
	if err != nil {
		utils.InternalError(c, "Failed to fetch user info")
		return
	}

	utils.OK(c, "Driver detail retrieved", gin.H{
		"driver": driver,
		"user":   user,
	})
}

// PUT /api/v1/admin/drivers/:id/approve
func (h *AdminHandler) ApproveDriver(c *gin.Context) {
	adminID := c.MustGet(middleware.ContextUserID).(uuid.UUID)
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "Invalid driver ID")
		return
	}

	driver, err := h.driverRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Driver not found")
		return
	}

	if driver.VerificationStatus != models.VerificationPending {
		utils.BadRequest(c, "Driver is not in pending status")
		return
	}

	if err := h.driverRepo.UpdateVerificationStatus(id, models.VerificationApproved, nil, adminID); err != nil {
		utils.InternalError(c, "Failed to approve driver")
		return
	}

	utils.OK(c, "Driver approved successfully", gin.H{
		"driver_id": id,
		"status":    models.VerificationApproved,
	})
}

// PUT /api/v1/admin/drivers/:id/reject
func (h *AdminHandler) RejectDriver(c *gin.Context) {
	adminID := c.MustGet(middleware.ContextUserID).(uuid.UUID)
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "Invalid driver ID")
		return
	}

	var req models.RejectRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Rejection reason is required")
		return
	}

	driver, err := h.driverRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Driver not found")
		return
	}

	if driver.VerificationStatus != models.VerificationPending {
		utils.BadRequest(c, "Driver is not in pending status")
		return
	}

	if err := h.driverRepo.UpdateVerificationStatus(id, models.VerificationRejected, &req.Reason, adminID); err != nil {
		utils.InternalError(c, "Failed to reject driver")
		return
	}

	utils.OK(c, "Driver rejected", gin.H{
		"driver_id": id,
		"status":    models.VerificationRejected,
		"reason":    req.Reason,
	})
}

// GET /api/v1/admin/stats
func (h *AdminHandler) GetStats(c *gin.Context) {
	totalDrivers, _ := h.driverRepo.CountTotal()
	pending, _ := h.driverRepo.CountByStatus(models.VerificationPending)
	approved, _ := h.driverRepo.CountByStatus(models.VerificationApproved)
	rejected, _ := h.driverRepo.CountByStatus(models.VerificationRejected)
	totalUsers, _ := h.userRepo.CountUsers()
	activeEmergencies, _ := h.driverRepo.CountActiveEmergencies()

	utils.OK(c, "Stats retrieved", models.AdminStats{
		TotalDrivers:      totalDrivers,
		PendingDrivers:    pending,
		ApprovedDrivers:   approved,
		RejectedDrivers:   rejected,
		TotalUsers:        totalUsers,
		ActiveEmergencies: activeEmergencies,
	})
}

// Helper: log admin action (placeholder — writes to admin_logs table)
func logAdminAction(adminID uuid.UUID, action, targetType string, targetID uuid.UUID) models.AdminLog {
	return models.AdminLog{
		ID:         uuid.New(),
		AdminID:    adminID,
		Action:     action,
		TargetType: &targetType,
		TargetID:   &targetID,
		CreatedAt:  time.Now(),
	}
}
