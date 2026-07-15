package handlers

import (
	"github.com/gin-gonic/gin"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/services"
	"github.com/kopdar/backend/internal/utils"
)

type AuthHandler struct {
	authSvc *services.AuthService
	otpSvc  *services.OTPService
}

func NewAuthHandler(authSvc *services.AuthService, otpSvc *services.OTPService) *AuthHandler {
	return &AuthHandler{authSvc: authSvc, otpSvc: otpSvc}
}

// POST /api/v1/auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Phone number is required")
		return
	}

	otp, err := h.authSvc.RequestOTP(req.Phone)
	if err != nil {
		utils.InternalError(c, "Failed to send OTP")
		return
	}

	resp := gin.H{"message": "OTP sent successfully"}
	if h.otpSvc.IsMockMode() {
		resp["otp"] = otp // Mock mode: return OTP in response
	}
	utils.OK(c, "OTP sent", resp)
}

// POST /api/v1/auth/verify-otp
func (h *AuthHandler) VerifyOTP(c *gin.Context) {
	var req models.VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Phone and OTP are required")
		return
	}

	tokens, err := h.authSvc.VerifyOTP(req.Phone, req.OTP)
	if err != nil {
		if err == services.ErrInvalidOTP {
			utils.Unauthorized(c, "Invalid or expired OTP")
			return
		}
		utils.InternalError(c, "Verification failed")
		return
	}

	utils.OK(c, "Authentication successful", tokens)
}

// POST /api/v1/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Phone and OTP are required")
		return
	}

	tokens, err := h.authSvc.Login(req.Phone, req.OTP)
	if err != nil {
		if err == services.ErrInvalidOTP {
			utils.Unauthorized(c, "Invalid or expired OTP")
			return
		}
		utils.InternalError(c, "Login failed")
		return
	}

	utils.OK(c, "Login successful", tokens)
}

// POST /api/v1/auth/refresh
func (h *AuthHandler) Refresh(c *gin.Context) {
	var req models.RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Refresh token is required")
		return
	}

	tokens, err := h.authSvc.Refresh(req.RefreshToken)
	if err != nil {
		if err == services.ErrTokenRevoked || err == services.ErrInvalidToken {
			utils.Unauthorized(c, "Invalid refresh token")
			return
		}
		utils.InternalError(c, "Token refresh failed")
		return
	}

	utils.OK(c, "Token refreshed", tokens)
}

// DELETE /api/v1/auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	var req models.RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Refresh token is required")
		return
	}

	if err := h.authSvc.Logout(req.RefreshToken); err != nil {
		utils.InternalError(c, "Logout failed")
		return
	}

	utils.OK(c, "Logged out successfully", nil)
}
