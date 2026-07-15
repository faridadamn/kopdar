package models

import (
	"time"

	"github.com/google/uuid"
)

// Insurance product types
const (
	InsuranceTypeAccident = "accident"
	InsuranceTypeInpatient = "inpatient"
	InsuranceTypeVehicle  = "vehicle"
	InsuranceTypeFamily   = "family"
)

// Insurance policy statuses
const (
	InsurancePolicyStatusActive   = "active"
	InsurancePolicyStatusExpired  = "expired"
	InsurancePolicyStatusCancelled = "cancelled"
)

// Insurance claim types
const (
	InsuranceClaimTypeKecelakaan = "kecelakaan"
	InsuranceClaimTypeRawatInap  = "rawat_inap"
	InsuranceClaimTypeKendaraan  = "kendaraan"
)

// Insurance claim statuses
const (
	InsuranceClaimStatusPending    = "pending"
	InsuranceClaimStatusApproved   = "approved"
	InsuranceClaimStatusRejected   = "rejected"
	InsuranceClaimStatusReimbursed = "reimbursed"
)

// InsuranceProduct represents an available insurance product
type InsuranceProduct struct {
	ID              uuid.UUID              `json:"id" db:"id"`
	Name            string                 `json:"name" db:"name"`
	Description     string                 `json:"description" db:"description"`
	ProductType     string                 `json:"product_type" db:"product_type"`
	Icon            string                 `json:"icon" db:"icon"`
	CoverageDetails map[string]interface{} `json:"coverage_details" db:"coverage_details"`
	PriceMember     float64                `json:"price_member" db:"price_member"`
	PriceNonMember  float64                `json:"price_non_member" db:"price_non_member"`
	PartnerName     string                 `json:"partner_name" db:"partner_name"`
	Status          string                 `json:"status" db:"status"`
	CreatedAt       time.Time              `json:"created_at" db:"created_at"`
}

// InsurancePolicy represents a purchased insurance policy
type InsurancePolicy struct {
	ID            uuid.UUID `json:"id" db:"id"`
	DriverID      uuid.UUID `json:"driver_id" db:"driver_id"`
	ProductID     uuid.UUID `json:"product_id" db:"product_id"`
	PolicyNumber  string    `json:"policy_number" db:"policy_number"`
	Premium       float64   `json:"premium" db:"premium"`
	PaymentMethod string    `json:"payment_method" db:"payment_method"`
	Status        string    `json:"status" db:"status"`
	StartDate     time.Time `json:"start_date" db:"start_date"`
	EndDate       time.Time `json:"end_date" db:"end_date"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
}

// InsuranceClaim represents an insurance claim filed by a driver
type InsuranceClaim struct {
	ID           uuid.UUID `json:"id" db:"id"`
	PolicyID     uuid.UUID `json:"policy_id" db:"policy_id"`
	DriverID     uuid.UUID `json:"driver_id" db:"driver_id"`
	ClaimType    string    `json:"claim_type" db:"claim_type"`
	Description  string    `json:"description" db:"description"`
	EvidenceURLs []string  `json:"evidence_urls" db:"evidence_urls"`
	Status       string    `json:"status" db:"status"`
	AdminNotes   *string   `json:"admin_notes,omitempty" db:"admin_notes"`
	ResolvedAt   *time.Time `json:"resolved_at,omitempty" db:"resolved_at"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

// InsuranceProductDetail is the response for a single product with additional context
type InsuranceProductDetail struct {
	InsuranceProduct
	HasActivePolicy bool `json:"has_active_policy"`
}

// InsurancePolicyDetail is the response for a single policy with product info
type InsurancePolicyDetail struct {
	InsurancePolicy
	Product       InsuranceProduct `json:"product"`
	DaysUntilExpiry int            `json:"days_until_expiry"`
}

// InsuranceClaimDetail is the response for a single claim with policy info
type InsuranceClaimDetail struct {
	InsuranceClaim
	Policy        InsurancePolicy  `json:"policy"`
	Product       InsuranceProduct `json:"product"`
}

// InsuranceListProductsResponse is the response for listing products
type InsuranceListProductsResponse struct {
	Products []InsuranceProductDetail `json:"products"`
}

// InsuranceListPoliciesResponse is the response for listing policies
type InsuranceListPoliciesResponse struct {
	Policies []InsurancePolicyDetail `json:"policies"`
}

// InsuranceListClaimsResponse is the response for listing claims
type InsuranceListClaimsResponse struct {
	Claims []InsuranceClaimDetail `json:"claims"`
}

// Request DTOs

// InsurancePurchaseRequest is the request body for purchasing insurance
type InsurancePurchaseRequest struct {
	ProductID      uuid.UUID              `json:"product_id" binding:"required"`
	PaymentMethod  string                 `json:"payment_method" binding:"required,oneof=auto_save manual"`
	AdditionalData map[string]interface{} `json:"additional_data"`
}

// InsuranceClaimRequest is the request body for filing a claim
type InsuranceClaimRequest struct {
	PolicyID     uuid.UUID `json:"policy_id" binding:"required"`
	ClaimType    string    `json:"claim_type" binding:"required,oneof=kecelakaan rawat_inap kendaraan"`
	Description  string    `json:"description" binding:"required"`
	EvidenceURLs []string  `json:"evidence_urls"`
}
