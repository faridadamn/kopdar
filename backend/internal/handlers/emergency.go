package handlers

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type EmergencyHandler struct {
	emergRepo  *repository.EmergencyRepository
	driverRepo *repository.DriverRepository
}

func NewEmergencyHandler(emergRepo *repository.EmergencyRepository, driverRepo *repository.DriverRepository) *EmergencyHandler {
	return &EmergencyHandler{
		emergRepo:  emergRepo,
		driverRepo: driverRepo,
	}
}

// ==================== S7-001: Emergency Info Setup ====================

// PUT /api/v1/driver/emergency/medical
func (h *EmergencyHandler) UpdateMedicalInfo(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.MedicalInfoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	medical := &models.DriverMedical{
		DriverID:              driver.ID,
		BloodType:             req.BloodType,
		Allergies:             req.Allergies,
		ChronicConditions:     req.ChronicConditions,
		Medications:           req.Medications,
		EmergencyMedicalNotes: req.EmergencyMedicalNotes,
		LastCheckupDate:       req.LastCheckupDate,
	}

	if err := h.emergRepo.UpsertMedicalInfo(driver.ID, medical); err != nil {
		utils.InternalError(c, "Gagal menyimpan info medis: "+err.Error())
		return
	}

	utils.OK(c, "Info medis berhasil disimpan", medical)
}

// GET /api/v1/driver/emergency/medical
func (h *EmergencyHandler) GetMedicalInfo(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	medical, err := h.emergRepo.GetMedicalInfo(driver.ID)
	if err != nil {
		utils.OK(c, "Info medis belum diatur", nil)
		return
	}

	utils.OK(c, "Info medis berhasil diambil", medical)
}

// POST /api/v1/driver/emergency/contacts
func (h *EmergencyHandler) AddContact(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	var req models.EmergencyContactRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	contact := &models.EmergencyContact{
		UserID:       userID,
		Name:         req.Name,
		Phone:        req.Phone,
		Relationship: req.Relationship,
		IsPrimary:    req.IsPrimary,
	}

	if err := h.emergRepo.CreateContact(contact); err != nil {
		utils.InternalError(c, "Gagal menyimpan kontak darurat: "+err.Error())
		return
	}

	utils.Created(c, "Kontak darurat berhasil ditambahkan", contact)
}

// GET /api/v1/driver/emergency/contacts
func (h *EmergencyHandler) ListContacts(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	contacts, err := h.emergRepo.ListContacts(userID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil daftar kontak darurat")
		return
	}

	utils.OK(c, "Daftar kontak darurat berhasil diambil", contacts)
}

// DELETE /api/v1/driver/emergency/contacts/:id
func (h *EmergencyHandler) DeleteContact(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID kontak tidak valid")
		return
	}

	if err := h.emergRepo.DeleteContact(id, userID); err != nil {
		utils.InternalError(c, "Gagal menghapus kontak darurat")
		return
	}

	utils.OK(c, "Kontak darurat berhasil dihapus", gin.H{"id": id})
}

// GET /api/v1/driver/emergency/setup
func (h *EmergencyHandler) GetSetup(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	medical, _ := h.emergRepo.GetMedicalInfo(driver.ID)
	contacts, _ := h.emergRepo.ListContacts(userID)

	utils.OK(c, "Data emergency setup berhasil diambil", models.EmergencyInfoSetupResponse{
		Medical:  medical,
		Contacts: contacts,
	})
}

// ==================== S7-002 & S7-003: SOS Activation ====================

// POST /api/v1/driver/emergency/sos
func (h *EmergencyHandler) ActivateSOS(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	active, _ := h.emergRepo.GetActiveEmergency(userID)
	if active != nil {
		utils.BadRequest(c, "Kamu sudah memiliki panggilan darurat aktif")
		return
	}

	var req models.SOSActivateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	medical, _ := h.emergRepo.GetMedicalInfo(driver.ID)

	var medSnapshot interface{}
	if medical != nil {
		medSnapshot = map[string]interface{}{
			"blood_type":         medical.BloodType,
			"allergies":          medical.Allergies,
			"chronic_conditions": medical.ChronicConditions,
			"medications":        medical.Medications,
		}
	}

	nearbyDrivers, _ := h.emergRepo.FindNearbyDrivers(req.Latitude, req.Longitude, 3.0, userID, 10)

	var notifiedIDs []uuid.UUID
	for _, nd := range nearbyDrivers {
		notifiedIDs = append(notifiedIDs, nd.DriverID)
	}

	emergency := &models.Emergency{
		UserID:            userID,
		Type:              "sos",
		Description:       req.Note,
		Latitude:          &req.Latitude,
		Longitude:         &req.Longitude,
		Address:           req.Address,
		EmergencyType:     models.EmergencyTypeManual,
		NotifiedDriverIDs: notifiedIDs,
		MedicalSnapshot:   medSnapshot,
	}

	if err := h.emergRepo.CreateEmergency(emergency); err != nil {
		utils.InternalError(c, "Gagal mengaktifkan SOS: "+err.Error())
		return
	}

	for _, nd := range nearbyDrivers {
		driverID, _ := h.emergRepo.GetDriverIDByUserID(nd.DriverID)
		if driverID != uuid.Nil {
			resp := &models.EmergencyResponder{
				EmergencyID: emergency.ID,
				DriverID:    driverID,
				Response:    models.ResponderStatusPending,
			}
			h.emergRepo.CreateResponder(resp)
		}
	}

	contacts, _ := h.emergRepo.ListContacts(userID)

	utils.Created(c, "SOS berhasil diaktifkan! Mencari bantuan di sekitar...", models.SOSActivateResponse{
		Emergency:        *emergency,
		NotifiedDrivers:  len(nearbyDrivers),
		MedicalSnapshot:  medical,
		ContactsNotified: contacts,
	})
}

// POST /api/v1/driver/emergency/sos/:id/respond
func (h *EmergencyHandler) RespondSOS(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	emergencyID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID darurat tidak valid")
		return
	}

	emergency, err := h.emergRepo.FindByID(emergencyID)
	if err != nil {
		utils.NotFound(c, "Panggilan darurat tidak ditemukan")
		return
	}

	if emergency.Status != models.EmergencyStatusActive {
		utils.BadRequest(c, "Panggilan darurat sudah tidak aktif")
		return
	}

	if emergency.UserID == userID {
		utils.BadRequest(c, "Tidak bisa merespons panggilan darurat sendiri")
		return
	}

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.SOSRespondRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	now := time.Now()
	resp := &models.EmergencyResponder{
		EmergencyID: emergencyID,
		DriverID:    driver.ID,
		Response:    req.Response,
		RespondedAt: &now,
		Notes:       req.Notes,
	}

	if err := h.emergRepo.CreateResponder(resp); err != nil {
		utils.InternalError(c, "Gagal menyimpan respons: "+err.Error())
		return
	}

	message := "Respons berhasil dikirim"
	if req.Response == models.ResponderStatusAccepted {
		message = "Terima kasih! Kamu sedang menuju lokasi. Hati-hati di jalan!"
	}

	utils.OK(c, message, gin.H{
		"response":  req.Response,
		"emergency": emergencyID,
	})
}

// POST /api/v1/driver/emergency/sos/:id/arrive
func (h *EmergencyHandler) MarkArrived(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	emergencyID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID darurat tidak valid")
		return
	}

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	resp, err := h.emergRepo.FindResponder(emergencyID, driver.ID)
	if err != nil {
		utils.NotFound(c, "Kamu bukan responder untuk panggilan darurat ini")
		return
	}

	if err := h.emergRepo.UpdateResponderStatus(resp.ID, models.ResponderStatusArrived); err != nil {
		utils.InternalError(c, "Gagal mengupdate status")
		return
	}

	utils.OK(c, "Status berhasil diupdate. Terima kasih sudah sampai!", gin.H{
		"status": models.ResponderStatusArrived,
	})
}

// POST /api/v1/driver/emergency/sos/:id/resolve
func (h *EmergencyHandler) ResolveSOS(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	emergencyID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID darurat tidak valid")
		return
	}

	emergency, err := h.emergRepo.FindByID(emergencyID)
	if err != nil {
		utils.NotFound(c, "Panggilan darurat tidak ditemukan")
		return
	}

	if emergency.UserID != userID {
		utils.Forbidden(c, "Hanya pemilik panggilan darurat yang bisa menyelesaikan")
		return
	}

	if emergency.Status != models.EmergencyStatusActive {
		utils.BadRequest(c, "Panggilan darurat sudah tidak aktif")
		return
	}

	driver, _ := h.driverRepo.FindByUserID(userID)
	var resolvedBy *uuid.UUID
	if driver != nil {
		resolvedBy = &driver.ID
	}

	if err := h.emergRepo.ResolveEmergency(emergencyID, resolvedBy); err != nil {
		utils.InternalError(c, "Gagal menyelesaikan panggilan darurat")
		return
	}

	utils.OK(c, "Panggilan darurat sudah ditutup. Semoga kamu baik-baik saja!", gin.H{
		"status": models.EmergencyStatusResolved,
	})
}

// POST /api/v1/driver/emergency/sos/:id/false-alarm
func (h *EmergencyHandler) MarkFalseAlarm(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	emergencyID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID darurat tidak valid")
		return
	}

	emergency, err := h.emergRepo.FindByID(emergencyID)
	if err != nil {
		utils.NotFound(c, "Panggilan darurat tidak ditemukan")
		return
	}

	if emergency.UserID != userID {
		utils.Forbidden(c, "Hanya pemilik panggilan darurat yang bisa mengubah status")
		return
	}

	if err := h.emergRepo.MarkFalseAlarm(emergencyID); err != nil {
		utils.InternalError(c, "Gagal mengubah status")
		return
	}

	utils.OK(c, "Panggilan darurat dibatalkan (false alarm)", gin.H{
		"status": models.EmergencyStatusFalseAlarm,
	})
}

// ==================== S7-004: Crash Detection ====================

// POST /api/v1/driver/emergency/crash
func (h *EmergencyHandler) ReportCrash(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	active, _ := h.emergRepo.GetActiveEmergency(userID)
	if active != nil {
		utils.BadRequest(c, "Sudah ada panggilan darurat aktif")
		return
	}

	var req models.CrashDetectRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	medical, _ := h.emergRepo.GetMedicalInfo(driver.ID)
	var medSnapshot interface{}
	if medical != nil {
		medSnapshot = map[string]interface{}{
			"blood_type":         medical.BloodType,
			"allergies":          medical.Allergies,
			"chronic_conditions": medical.ChronicConditions,
			"medications":        medical.Medications,
		}
	}

	nearbyDrivers, _ := h.emergRepo.FindNearbyDrivers(req.Latitude, req.Longitude, 3.0, userID, 10)
	var notifiedIDs []uuid.UUID
	for _, nd := range nearbyDrivers {
		notifiedIDs = append(notifiedIDs, nd.DriverID)
	}

	desc := fmt.Sprintf("Kecelakaan terdeteksi! G-force: %.1f", req.Force)
	emergency := &models.Emergency{
		UserID:            userID,
		Type:              "sos",
		Description:       &desc,
		Latitude:          &req.Latitude,
		Longitude:         &req.Longitude,
		Address:           req.Address,
		EmergencyType:     models.EmergencyTypeCrash,
		NotifiedDriverIDs: notifiedIDs,
		MedicalSnapshot:   medSnapshot,
	}

	if err := h.emergRepo.CreateEmergency(emergency); err != nil {
		utils.InternalError(c, "Gagal melaporkan kecelakaan: "+err.Error())
		return
	}

	for _, nd := range nearbyDrivers {
		driverID, _ := h.emergRepo.GetDriverIDByUserID(nd.DriverID)
		if driverID != uuid.Nil {
			resp := &models.EmergencyResponder{
				EmergencyID: emergency.ID,
				DriverID:    driverID,
				Response:    models.ResponderStatusPending,
			}
			h.emergRepo.CreateResponder(resp)
		}
	}

	contacts, _ := h.emergRepo.ListContacts(userID)

	utils.Created(c, "Kecelakaan terdeteksi! SOS otomatis diaktifkan!", models.SOSActivateResponse{
		Emergency:        *emergency,
		NotifiedDrivers:  len(nearbyDrivers),
		MedicalSnapshot:  medical,
		ContactsNotified: contacts,
	})
}

// ==================== S7-005: Nearby Driver Response ====================

// GET /api/v1/driver/emergency/active
func (h *EmergencyHandler) GetActiveSOS(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	active, err := h.emergRepo.GetActiveEmergency(userID)
	if err != nil {
		utils.OK(c, "Tidak ada panggilan darurat aktif", models.ActiveSOSResponse{
			Active: false,
		})
		return
	}

	detail := h.buildEmergencyDetail(active)

	utils.OK(c, "Ada panggilan darurat aktif", models.ActiveSOSResponse{
		Active:    true,
		Emergency: &detail,
	})
}

// GET /api/v1/driver/emergency/:id
func (h *EmergencyHandler) GetEmergency(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID darurat tidak valid")
		return
	}

	emergency, err := h.emergRepo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "Data darurat tidak ditemukan")
		return
	}

	if emergency.UserID != userID {
		driver, _ := h.driverRepo.FindByUserID(userID)
		if driver == nil {
			utils.Forbidden(c, "Akses ditolak")
			return
		}
		_, err := h.emergRepo.FindResponder(id, driver.ID)
		if err != nil {
			utils.Forbidden(c, "Akses ditolak")
			return
		}
	}

	detail := h.buildEmergencyDetail(emergency)
	utils.OK(c, "Detail darurat berhasil diambil", detail)
}

// POST /api/v1/driver/emergency/location
func (h *EmergencyHandler) UpdateLocation(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.LocationUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	if err := h.emergRepo.UpdateDriverLocation(driver.ID, req.Latitude, req.Longitude); err != nil {
		utils.InternalError(c, "Gagal mengupdate lokasi: "+err.Error())
		return
	}

	utils.OK(c, "Lokasi berhasil diupdate", gin.H{
		"latitude":  req.Latitude,
		"longitude": req.Longitude,
	})
}

// ==================== S7-006: Emergency History ====================

// GET /api/v1/driver/emergency/history
func (h *EmergencyHandler) ListHistory(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	page := 1
	limit := 20
	if p := c.Query("page"); p != "" {
		fmt.Sscanf(p, "%d", &page)
	}
	if l := c.Query("limit"); l != "" {
		fmt.Sscanf(l, "%d", &limit)
	}
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	items, total, err := h.emergRepo.ListEmergencies(userID, limit, offset)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil riwayat darurat")
		return
	}

	utils.OK(c, "Riwayat darurat berhasil diambil", models.EmergencyListResponse{
		Emergencies: items,
		Total:       total,
	})
}

// POST /api/v1/driver/emergency/:id/feedback
func (h *EmergencyHandler) SubmitFeedback(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	emergencyID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID darurat tidak valid")
		return
	}

	emergency, err := h.emergRepo.FindByID(emergencyID)
	if err != nil {
		utils.NotFound(c, "Data darurat tidak ditemukan")
		return
	}

	if emergency.UserID != userID {
		utils.Forbidden(c, "Hanya pemilik yang bisa memberikan feedback")
		return
	}

	if emergency.Status == models.EmergencyStatusActive {
		utils.BadRequest(c, "Tidak bisa memberikan feedback untuk panggilan aktif")
		return
	}

	hasFeedback, _ := h.emergRepo.HasFeedback(emergencyID, userID)
	if hasFeedback {
		utils.BadRequest(c, "Kamu sudah memberikan feedback untuk kejadian ini")
		return
	}

	var req models.EmergencyFeedbackRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	driver, _ := h.driverRepo.FindByUserID(userID)
	if driver == nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	feedback := &models.EmergencyFeedback{
		EmergencyID: emergencyID,
		DriverID:    driver.ID,
		Rating:      req.Rating,
		Comment:     req.Comment,
	}

	if err := h.emergRepo.CreateFeedback(feedback); err != nil {
		utils.InternalError(c, "Gagal menyimpan feedback: "+err.Error())
		return
	}

	utils.Created(c, "Feedback berhasil dikirim. Terima kasih!", feedback)
}

// ==================== Helpers ====================

func (h *EmergencyHandler) buildEmergencyDetail(e *models.Emergency) models.EmergencyDetailResponse {
	detail := models.EmergencyDetailResponse{
		Emergency: *e,
	}

	name, phone, _ := h.emergRepo.GetDriverInfo(e.UserID)
	detail.DriverName = name
	detail.DriverPhone = phone
	detail.Address = e.Address

	driver, _ := h.driverRepo.FindByUserID(e.UserID)
	if driver != nil {
		medical, _ := h.emergRepo.GetMedicalInfo(driver.ID)
		detail.MedicalInfo = medical
	}

	responders, _ := h.emergRepo.GetResponders(e.ID)
	var respDetails []models.EmergencyResponderDetail
	for _, r := range responders {
		rd := models.EmergencyResponderDetail{
			EmergencyResponder: r,
		}
		rUserID, _ := h.emergRepo.GetUserByDriverID(r.DriverID)
		rName, rPhone, _ := h.emergRepo.GetDriverInfo(rUserID)
		rd.DriverName = rName
		rd.DriverPhone = rPhone
		respDetails = append(respDetails, rd)
	}
	if respDetails == nil {
		respDetails = []models.EmergencyResponderDetail{}
	}
	detail.Responders = respDetails

	return detail
}
