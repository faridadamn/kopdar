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

type InsuranceHandler struct {
	insuranceRepo *repository.InsuranceRepository
	driverRepo    *repository.DriverRepository
}

func NewInsuranceHandler(insuranceRepo *repository.InsuranceRepository, driverRepo *repository.DriverRepository) *InsuranceHandler {
	return &InsuranceHandler{
		insuranceRepo: insuranceRepo,
		driverRepo:    driverRepo,
	}
}

// GET /api/v1/driver/insurance/products
func (h *InsuranceHandler) ListProducts(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	products, err := h.insuranceRepo.ListProducts()
	if err != nil {
		utils.InternalError(c, "Gagal mengambil daftar produk asuransi")
		return
	}

	if products == nil {
		products = []models.InsuranceProduct{}
	}

	details := make([]models.InsuranceProductDetail, 0, len(products))
	for _, p := range products {
		hasActive, _ := h.insuranceRepo.HasActivePolicy(driver.ID, p.ID)
		details = append(details, models.InsuranceProductDetail{
			InsuranceProduct: p,
			HasActivePolicy:  hasActive,
		})
	}

	utils.OK(c, "Daftar produk asuransi berhasil diambil", models.InsuranceListProductsResponse{
		Products: details,
	})
}

// GET /api/v1/driver/insurance/products/:id
func (h *InsuranceHandler) GetProduct(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID produk tidak valid")
		return
	}

	product, err := h.insuranceRepo.FindProductByID(id)
	if err != nil {
		utils.NotFound(c, "Produk asuransi tidak ditemukan")
		return
	}

	hasActive, _ := h.insuranceRepo.HasActivePolicy(driver.ID, product.ID)

	detail := models.InsuranceProductDetail{
		InsuranceProduct: *product,
		HasActivePolicy:  hasActive,
	}

	utils.OK(c, "Detail produk asuransi berhasil diambil", detail)
}

// POST /api/v1/driver/insurance/policies
func (h *InsuranceHandler) PurchasePolicy(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.InsurancePurchaseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	// Validate product exists and is active
	product, err := h.insuranceRepo.FindProductByID(req.ProductID)
	if err != nil {
		utils.NotFound(c, "Produk asuransi tidak ditemukan")
		return
	}

	if product.Status != "active" {
		utils.BadRequest(c, "Produk asuransi tidak tersedia")
		return
	}

	// Check if driver already has active policy for this product
	hasActive, _ := h.insuranceRepo.HasActivePolicy(driver.ID, product.ID)
	if hasActive {
		utils.BadRequest(c, "Kamu sudah memiliki polis aktif untuk produk ini")
		return
	}

	// Generate policy number
	policyNumber, err := h.insuranceRepo.GeneratePolicyNumber()
	if err != nil {
		utils.InternalError(c, "Gagal membuat nomor polis")
		return
	}

	// Set premium based on membership (simplified: use price_member by default)
	premium := product.PriceMember

	now := time.Now()
	policy := &models.InsurancePolicy{
		DriverID:      driver.ID,
		ProductID:     req.ProductID,
		PolicyNumber:  policyNumber,
		Premium:       premium,
		PaymentMethod: req.PaymentMethod,
		Status:        models.InsurancePolicyStatusActive,
		StartDate:     now,
		EndDate:       now.AddDate(0, 1, 0), // 1 month from now
	}

	if err := h.insuranceRepo.CreatePolicy(policy); err != nil {
		utils.InternalError(c, "Gagal membuat polis asuransi: "+err.Error())
		return
	}

	utils.Created(c, "Polis asuransi berhasil dibuat", policy)
}

// GET /api/v1/driver/insurance/policies
func (h *InsuranceHandler) ListPolicies(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	policies, err := h.insuranceRepo.ListPoliciesByDriver(driver.ID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil daftar polis")
		return
	}

	if policies == nil {
		policies = []models.InsurancePolicy{}
	}

	details := make([]models.InsurancePolicyDetail, 0, len(policies))
	for _, p := range policies {
		product, err := h.insuranceRepo.FindProductByID(p.ProductID)
		if err != nil {
			continue
		}

		daysUntil := int(time.Until(p.EndDate).Hours() / 24)
		if daysUntil < 0 {
			daysUntil = 0
		}

		details = append(details, models.InsurancePolicyDetail{
			InsurancePolicy: p,
			Product:         *product,
			DaysUntilExpiry: daysUntil,
		})
	}

	utils.OK(c, "Daftar polis berhasil diambil", models.InsuranceListPoliciesResponse{
		Policies: details,
	})
}

// GET /api/v1/driver/insurance/policies/:id
func (h *InsuranceHandler) GetPolicy(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID polis tidak valid")
		return
	}

	policy, err := h.insuranceRepo.FindPolicyByID(id)
	if err != nil {
		utils.NotFound(c, "Polis tidak ditemukan")
		return
	}

	if policy.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke polis ini")
		return
	}

	product, err := h.insuranceRepo.FindProductByID(policy.ProductID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil detail produk")
		return
	}

	daysUntil := int(time.Until(policy.EndDate).Hours() / 24)
	if daysUntil < 0 {
		daysUntil = 0
	}

	detail := models.InsurancePolicyDetail{
		InsurancePolicy: *policy,
		Product:         *product,
		DaysUntilExpiry: daysUntil,
	}

	utils.OK(c, "Detail polis berhasil diambil", detail)
}

// PUT /api/v1/driver/insurance/policies/:id/renew
func (h *InsuranceHandler) RenewPolicy(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID polis tidak valid")
		return
	}

	policy, err := h.insuranceRepo.FindPolicyByID(id)
	if err != nil {
		utils.NotFound(c, "Polis tidak ditemukan")
		return
	}

	if policy.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke polis ini")
		return
	}

	if policy.Status != models.InsurancePolicyStatusActive {
		utils.BadRequest(c, "Hanya polis aktif yang bisa diperpanjang")
		return
	}

	// Extend end_date by 1 month
	policy.EndDate = policy.EndDate.AddDate(0, 1, 0)

	if err := h.insuranceRepo.UpdatePolicy(policy); err != nil {
		utils.InternalError(c, "Gagal memperpanjang polis")
		return
	}

	product, err := h.insuranceRepo.FindProductByID(policy.ProductID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil detail produk")
		return
	}

	daysUntil := int(time.Until(policy.EndDate).Hours() / 24)
	if daysUntil < 0 {
		daysUntil = 0
	}

	detail := models.InsurancePolicyDetail{
		InsurancePolicy: *policy,
		Product:         *product,
		DaysUntilExpiry: daysUntil,
	}

	utils.OK(c, "Polis berhasil diperpanjang", detail)
}

// POST /api/v1/driver/insurance/claims
func (h *InsuranceHandler) FileClaim(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.InsuranceClaimRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	// Validate policy exists and belongs to driver
	policy, err := h.insuranceRepo.FindPolicyByID(req.PolicyID)
	if err != nil {
		utils.NotFound(c, "Polis tidak ditemukan")
		return
	}

	if policy.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke polis ini")
		return
	}

	if policy.Status != models.InsurancePolicyStatusActive {
		utils.BadRequest(c, "Klaim hanya bisa diajukan untuk polis aktif")
		return
	}

	// Validate claim type
	validClaimTypes := map[string]bool{
		models.InsuranceClaimTypeKecelakaan: true,
		models.InsuranceClaimTypeRawatInap:  true,
		models.InsuranceClaimTypeKendaraan:  true,
	}
	if !validClaimTypes[req.ClaimType] {
		utils.BadRequest(c, "Jenis klaim tidak valid. Pilihan: kecelakaan, rawat_inap, kendaraan")
		return
	}

	evidenceURLs := req.EvidenceURLs
	if evidenceURLs == nil {
		evidenceURLs = []string{}
	}

	claim := &models.InsuranceClaim{
		PolicyID:     req.PolicyID,
		DriverID:     driver.ID,
		ClaimType:    req.ClaimType,
		Description:  req.Description,
		EvidenceURLs: evidenceURLs,
		Status:       models.InsuranceClaimStatusPending,
	}

	if err := h.insuranceRepo.CreateClaim(claim); err != nil {
		utils.InternalError(c, "Gagal mengajukan klaim: "+err.Error())
		return
	}

	utils.Created(c, "Klaim berhasil diajukan", claim)
}

// GET /api/v1/driver/insurance/claims
func (h *InsuranceHandler) ListClaims(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	claims, err := h.insuranceRepo.ListClaimsByDriver(driver.ID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil daftar klaim")
		return
	}

	if claims == nil {
		claims = []models.InsuranceClaim{}
	}

	details := make([]models.InsuranceClaimDetail, 0, len(claims))
	for _, claim := range claims {
		policy, err := h.insuranceRepo.FindPolicyByID(claim.PolicyID)
		if err != nil {
			continue
		}
		product, err := h.insuranceRepo.FindProductByID(policy.ProductID)
		if err != nil {
			continue
		}

		details = append(details, models.InsuranceClaimDetail{
			InsuranceClaim: claim,
			Policy:         *policy,
			Product:        *product,
		})
	}

	utils.OK(c, "Daftar klaim berhasil diambil", models.InsuranceListClaimsResponse{
		Claims: details,
	})
}

// GET /api/v1/driver/insurance/claims/:id
func (h *InsuranceHandler) GetClaim(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID klaim tidak valid")
		return
	}

	claim, err := h.insuranceRepo.FindClaimByID(id)
	if err != nil {
		utils.NotFound(c, "Klaim tidak ditemukan")
		return
	}

	if claim.DriverID != driver.ID {
		utils.Forbidden(c, "Anda tidak memiliki akses ke klaim ini")
		return
	}

	policy, err := h.insuranceRepo.FindPolicyByID(claim.PolicyID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil detail polis")
		return
	}

	product, err := h.insuranceRepo.FindProductByID(policy.ProductID)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil detail produk")
		return
	}

	detail := models.InsuranceClaimDetail{
		InsuranceClaim: *claim,
		Policy:         *policy,
		Product:        *product,
	}

	utils.OK(c, "Detail klaim berhasil diambil", detail)
}
