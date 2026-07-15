package models

import (
	"time"

	"github.com/google/uuid"
)

// User roles
const (
	RoleDriver     = "driver"
	RoleAdmin      = "admin"
	RoleSuperAdmin = "superadmin"
)

// User statuses
const (
	StatusActive    = "active"
	StatusSuspended = "suspended"
	StatusDeleted   = "deleted"
)

// Driver verification statuses
const (
	VerificationPending     = "pending"
	VerificationApproved    = "approved"
	VerificationRejected    = "rejected"
	VerificationNeedsReview = "needs_review"
)

type User struct {
	ID        uuid.UUID  `json:"id" db:"id"`
	Phone     string     `json:"phone" db:"phone"`
	FullName  *string    `json:"full_name,omitempty" db:"full_name"`
	Role      string     `json:"role" db:"role"`
	Status    string     `json:"status" db:"status"`
	AvatarURL *string    `json:"avatar_url,omitempty" db:"avatar_url"`
	CreatedAt time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt time.Time  `json:"updated_at" db:"updated_at"`
}

type RefreshToken struct {
	ID        uuid.UUID `json:"id" db:"id"`
	UserID    uuid.UUID `json:"user_id" db:"user_id"`
	TokenHash string    `json:"-" db:"token_hash"`
	ExpiresAt time.Time `json:"expires_at" db:"expires_at"`
	Revoked   bool      `json:"revoked" db:"revoked"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type Driver struct {
	ID                   uuid.UUID  `json:"id" db:"id"`
	UserID               uuid.UUID  `json:"user_id" db:"user_id"`
	NIK                  *string    `json:"nik,omitempty" db:"nik"`
	DateOfBirth          *time.Time `json:"date_of_birth,omitempty" db:"date_of_birth"`
	Address              *string    `json:"address,omitempty" db:"address"`
	City                 *string    `json:"city,omitempty" db:"city"`
	Province             *string    `json:"province,omitempty" db:"province"`
	PostalCode           *string    `json:"postal_code,omitempty" db:"postal_code"`
	KTPPhotoURL          *string    `json:"ktp_photo_url,omitempty" db:"ktp_photo_url"`
	SelfiePhotoURL       *string    `json:"selfie_photo_url,omitempty" db:"selfie_photo_url"`
	VehicleType          *string    `json:"vehicle_type,omitempty" db:"vehicle_type"`
	VehiclePlate         *string    `json:"vehicle_plate,omitempty" db:"vehicle_plate"`
	VehicleYear          *int       `json:"vehicle_year,omitempty" db:"vehicle_year"`
	STNKPhotoURL         *string    `json:"stnk_photo_url,omitempty" db:"stnk_photo_url"`
	VerificationStatus   string     `json:"verification_status" db:"verification_status"`
	RejectionReason      *string    `json:"rejection_reason,omitempty" db:"rejection_reason"`
	VerifiedAt           *time.Time `json:"verified_at,omitempty" db:"verified_at"`
	VerifiedBy           *uuid.UUID `json:"verified_by,omitempty" db:"verified_by"`
	ReferralCode         *string    `json:"referral_code,omitempty" db:"referral_code"`
	EmergencyContactName *string    `json:"emergency_contact_name,omitempty" db:"emergency_contact_name"`
	EmergencyContactPhone *string   `json:"emergency_contact_phone,omitempty" db:"emergency_contact_phone"`
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at" db:"updated_at"`
}

type DriverPlatform struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	DriverID         uuid.UUID  `json:"driver_id" db:"driver_id"`
	Platform         string     `json:"platform" db:"platform"`
	PlatformDriverID *string    `json:"platform_driver_id,omitempty" db:"platform_driver_id"`
	IsActive         bool       `json:"is_active" db:"is_active"`
	JoinedAt         *time.Time `json:"joined_at,omitempty" db:"joined_at"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
}

// Request/Response DTOs

type RegisterRequest struct {
	Phone string `json:"phone" binding:"required"`
}

type VerifyOTPRequest struct {
	Phone string `json:"phone" binding:"required"`
	OTP   string `json:"otp" binding:"required"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type RejectRequest struct {
	Reason string `json:"reason" binding:"required"`
}

type TokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
	TokenType    string `json:"token_type"`
}

type DriverRegisterRequest struct {
	FullName             string   `form:"full_name" binding:"required"`
	NIK                  string   `form:"nik" binding:"required"`
	DateOfBirth          string   `form:"date_of_birth" binding:"required"`
	Address              string   `form:"address" binding:"required"`
	City                 string   `form:"city" binding:"required"`
	Province             string   `form:"province" binding:"required"`
	PostalCode           string   `form:"postal_code"`
	VehicleType          string   `form:"vehicle_type" binding:"required"`
	VehiclePlate         string   `form:"vehicle_plate" binding:"required"`
	VehicleYear          int      `form:"vehicle_year"`
	EmergencyContactName string   `form:"emergency_contact_name"`
	EmergencyContactPhone string  `form:"emergency_contact_phone"`
	Platforms            string   `form:"platforms"` // JSON array of platform names
}

type DriverProfileUpdate struct {
	FullName              *string `json:"full_name"`
	Address               *string `json:"address"`
	City                  *string `json:"city"`
	Province              *string `json:"province"`
	PostalCode            *string `json:"postal_code"`
	VehicleType           *string `json:"vehicle_type"`
	VehiclePlate          *string `json:"vehicle_plate"`
	VehicleYear           *int    `json:"vehicle_year"`
	EmergencyContactName  *string `json:"emergency_contact_name"`
	EmergencyContactPhone *string `json:"emergency_contact_phone"`
}

type PaginationQuery struct {
	Page     int    `form:"page,default=1"`
	PageSize int    `form:"page_size,default=20"`
	Search   string `form:"search"`
}

type PaginatedResponse struct {
	Data       interface{} `json:"data"`
	Page       int         `json:"page"`
	PageSize   int         `json:"page_size"`
	TotalItems int64       `json:"total_items"`
	TotalPages int         `json:"total_pages"`
}

type AdminStats struct {
	TotalDrivers      int64 `json:"total_drivers"`
	PendingDrivers    int64 `json:"pending_drivers"`
	ApprovedDrivers   int64 `json:"approved_drivers"`
	RejectedDrivers   int64 `json:"rejected_drivers"`
	TotalUsers        int64 `json:"total_users"`
	ActiveEmergencies int64 `json:"active_emergencies"`
}

type AdminLog struct {
	ID         uuid.UUID   `json:"id"`
	AdminID    uuid.UUID   `json:"admin_id"`
	Action     string      `json:"action"`
	TargetType *string     `json:"target_type,omitempty"`
	TargetID   *uuid.UUID  `json:"target_id,omitempty"`
	Details    interface{} `json:"details,omitempty"`
	IPAddress  *string     `json:"ip_address,omitempty"`
	CreatedAt  time.Time   `json:"created_at"`
}
