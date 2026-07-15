package models

import (
	"time"

	"github.com/google/uuid"
)

// Emergency statuses (extends existing enum)
const (
	EmergencyStatusActive      = "active"
	EmergencyStatusResolved    = "resolved"
	EmergencyStatusFalseAlarm  = "false_alarm"
)

// Emergency types
const (
	EmergencyTypeManual = "manual"
	EmergencyTypeCrash  = "crash_detected"
)

// Responder response statuses
const (
	ResponderStatusPending  = "pending"
	ResponderStatusAccepted = "accepted"
	ResponderStatusDeclined = "declined"
	ResponderStatusArrived  = "arrived"
)

// Emergency represents an active emergency/SOS event
type Emergency struct {
	ID                uuid.UUID   `json:"id" db:"id"`
	UserID            uuid.UUID   `json:"user_id" db:"user_id"`
	Type              string      `json:"type" db:"type"`
	Description       *string     `json:"description,omitempty" db:"description"`
	Latitude          *float64    `json:"latitude,omitempty" db:"latitude"`
	Longitude         *float64    `json:"longitude,omitempty" db:"longitude"`
	Address           *string     `json:"address,omitempty" db:"address"`
	Status            string      `json:"status" db:"status"`
	EmergencyType     string      `json:"emergency_type" db:"emergency_type"`
	NotifiedDriverIDs []uuid.UUID `json:"notified_driver_ids" db:"notified_driver_ids"`
	MedicalSnapshot   interface{} `json:"medical_snapshot,omitempty" db:"medical_snapshot"`
	ResolvedAt        *time.Time  `json:"resolved_at,omitempty" db:"resolved_at"`
	ResolvedBy        *uuid.UUID  `json:"resolved_by,omitempty" db:"resolved_by"`
	EndedAt           *time.Time  `json:"ended_at,omitempty" db:"ended_at"`
	CreatedAt         time.Time   `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time   `json:"updated_at" db:"updated_at"`
}

// EmergencyContact represents an emergency contact for a driver
type EmergencyContact struct {
	ID           uuid.UUID `json:"id" db:"id"`
	UserID       uuid.UUID `json:"user_id" db:"user_id"`
	Name         string    `json:"name" db:"name"`
	Phone        string    `json:"phone" db:"phone"`
	Relationship *string   `json:"relationship,omitempty" db:"relationship"`
	IsPrimary    bool      `json:"is_primary" db:"is_primary"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

// DriverMedical represents a driver's medical information
type DriverMedical struct {
	ID                   uuid.UUID  `json:"id" db:"id"`
	DriverID             uuid.UUID  `json:"driver_id" db:"driver_id"`
	BloodType            *string    `json:"blood_type,omitempty" db:"blood_type"`
	Allergies            *string    `json:"allergies,omitempty" db:"allergies"`
	ChronicConditions    *string    `json:"chronic_conditions,omitempty" db:"chronic_conditions"`
	Medications          *string    `json:"medications,omitempty" db:"medications"`
	EmergencyMedicalNotes *string   `json:"emergency_medical_notes,omitempty" db:"emergency_medical_notes"`
	LastCheckupDate      *string    `json:"last_checkup_date,omitempty" db:"last_checkup_date"`
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at" db:"updated_at"`
}

// EmergencyResponder tracks a nearby driver's response to an SOS
type EmergencyResponder struct {
	ID          uuid.UUID  `json:"id" db:"id"`
	EmergencyID uuid.UUID  `json:"emergency_id" db:"emergency_id"`
	DriverID    uuid.UUID  `json:"driver_id" db:"driver_id"`
	Response    string     `json:"response" db:"response"`
	RespondedAt *time.Time `json:"responded_at,omitempty" db:"responded_at"`
	ArrivedAt   *time.Time `json:"arrived_at,omitempty" db:"arrived_at"`
	Notes       *string    `json:"notes,omitempty" db:"notes"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
}

// EmergencyFeedback represents feedback after an emergency is resolved
type EmergencyFeedback struct {
	ID          uuid.UUID `json:"id" db:"id"`
	EmergencyID uuid.UUID `json:"emergency_id" db:"emergency_id"`
	DriverID    uuid.UUID `json:"driver_id" db:"driver_id"`
	Rating      int       `json:"rating" db:"rating"`
	Comment     *string   `json:"comment,omitempty" db:"comment"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// DriverLocation stores the last known location of a driver
type DriverLocation struct {
	DriverID  uuid.UUID `json:"driver_id" db:"driver_id"`
	Latitude  float64   `json:"latitude" db:"latitude"`
	Longitude float64   `json:"longitude" db:"longitude"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// ==================== Request DTOs ====================

type MedicalInfoRequest struct {
	BloodType             *string `json:"blood_type"`
	Allergies             *string `json:"allergies"`
	ChronicConditions     *string `json:"chronic_conditions"`
	Medications           *string `json:"medications"`
	EmergencyMedicalNotes *string `json:"emergency_medical_notes"`
	LastCheckupDate       *string `json:"last_checkup_date"`
}

type EmergencyContactRequest struct {
	Name         string  `json:"name" binding:"required"`
	Phone        string  `json:"phone" binding:"required"`
	Relationship *string `json:"relationship"`
	IsPrimary    bool    `json:"is_primary"`
}

type SOSActivateRequest struct {
	Latitude  float64 `json:"latitude" binding:"required"`
	Longitude float64 `json:"longitude" binding:"required"`
	Address   *string `json:"address"`
	Note      *string `json:"note"`
}

type SOSRespondRequest struct {
	Response string  `json:"response" binding:"required,oneof=accepted declined"`
	Notes    *string `json:"notes"`
}

type EmergencyFeedbackRequest struct {
	Rating  int     `json:"rating" binding:"required,min=1,max=5"`
	Comment *string `json:"comment"`
}

type CrashDetectRequest struct {
	Latitude  float64 `json:"latitude" binding:"required"`
	Longitude float64 `json:"longitude" binding:"required"`
	Address   *string `json:"address"`
	Force     float64 `json:"force"` // G-force of impact
}

type LocationUpdateRequest struct {
	Latitude  float64 `json:"latitude" binding:"required"`
	Longitude float64 `json:"longitude" binding:"required"`
}

// ==================== Response DTOs ====================

type EmergencyInfoSetupResponse struct {
	Medical  *DriverMedical      `json:"medical"`
	Contacts []EmergencyContact  `json:"contacts"`
}

type SOSActivateResponse struct {
	Emergency       Emergency               `json:"emergency"`
	NotifiedDrivers int                     `json:"notified_drivers"`
	MedicalSnapshot *DriverMedical           `json:"medical_snapshot"`
	ContactsNotified []EmergencyContact      `json:"contacts_notified"`
}

type EmergencyDetailResponse struct {
	Emergency
	DriverName      string                `json:"driver_name"`
	DriverPhone     string                `json:"driver_phone,omitempty"`
	MedicalInfo     *DriverMedical        `json:"medical_info,omitempty"`
	Responders      []EmergencyResponderDetail `json:"responders"`
	Address         *string               `json:"address"`
}

type EmergencyResponderDetail struct {
	EmergencyResponder
	DriverName   string  `json:"driver_name"`
	DriverPhone  string  `json:"driver_phone,omitempty"`
	Distance     float64 `json:"distance_km"`
}

type NearbyDriver struct {
	DriverID   uuid.UUID `json:"driver_id"`
	DriverName string    `json:"driver_name"`
	Distance   float64   `json:"distance_km"`
	Phone      string    `json:"phone,omitempty"`
}

type EmergencyListResponse struct {
	Emergencies []EmergencyListItem `json:"emergencies"`
	Total       int                 `json:"total"`
}

type EmergencyListItem struct {
	ID            uuid.UUID  `json:"id"`
	EmergencyType string     `json:"emergency_type"`
	Status        string     `json:"status"`
	Latitude      *float64   `json:"latitude,omitempty"`
	Longitude     *float64   `json:"longitude,omitempty"`
	Address       *string    `json:"address,omitempty"`
	ResponderCount int       `json:"responders_count"`
	Duration      *string    `json:"duration,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	EndedAt       *time.Time `json:"ended_at,omitempty"`
}

type ActiveSOSResponse struct {
	Active    bool                   `json:"active"`
	Emergency *EmergencyDetailResponse `json:"emergency,omitempty"`
}
