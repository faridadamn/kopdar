package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
)

type InsuranceRepository struct {
	pool *pgxpool.Pool
}

func NewInsuranceRepository(pool *pgxpool.Pool) *InsuranceRepository {
	return &InsuranceRepository{pool: pool}
}

// ========== Products ==========

func (r *InsuranceRepository) ListProducts() ([]models.InsuranceProduct, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, name, description, product_type, icon, coverage_details,
		 price_member, price_non_member, partner_name, status, created_at
		 FROM insurance_products WHERE status = 'active' ORDER BY created_at DESC`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var products []models.InsuranceProduct
	for rows.Next() {
		p := models.InsuranceProduct{}
		var coverageJSON []byte
		if err := rows.Scan(
			&p.ID, &p.Name, &p.Description, &p.ProductType, &p.Icon,
			&coverageJSON, &p.PriceMember, &p.PriceNonMember,
			&p.PartnerName, &p.Status, &p.CreatedAt,
		); err != nil {
			return nil, err
		}
		if coverageJSON != nil {
			json.Unmarshal(coverageJSON, &p.CoverageDetails)
		}
		if p.CoverageDetails == nil {
			p.CoverageDetails = map[string]interface{}{}
		}
		products = append(products, p)
	}
	return products, nil
}

func (r *InsuranceRepository) FindProductByID(id uuid.UUID) (*models.InsuranceProduct, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	p := &models.InsuranceProduct{}
	var coverageJSON []byte
	err := r.pool.QueryRow(ctx,
		`SELECT id, name, description, product_type, icon, coverage_details,
		 price_member, price_non_member, partner_name, status, created_at
		 FROM insurance_products WHERE id = $1`, id,
	).Scan(
		&p.ID, &p.Name, &p.Description, &p.ProductType, &p.Icon,
		&coverageJSON, &p.PriceMember, &p.PriceNonMember,
		&p.PartnerName, &p.Status, &p.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	if coverageJSON != nil {
		json.Unmarshal(coverageJSON, &p.CoverageDetails)
	}
	if p.CoverageDetails == nil {
		p.CoverageDetails = map[string]interface{}{}
	}
	return p, nil
}

func (r *InsuranceRepository) HasActivePolicy(driverID, productID uuid.UUID) (bool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var count int
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM insurance_policies
		 WHERE driver_id = $1 AND product_id = $2 AND status = 'active' AND end_date > NOW()`,
		driverID, productID,
	).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// ========== Policies ==========

func (r *InsuranceRepository) CreatePolicy(policy *models.InsurancePolicy) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO insurance_policies (
			driver_id, product_id, policy_number, premium, payment_method, status, start_date, end_date
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
		RETURNING id, created_at`,
		policy.DriverID, policy.ProductID, policy.PolicyNumber,
		policy.Premium, policy.PaymentMethod, policy.Status,
		policy.StartDate, policy.EndDate,
	).Scan(&policy.ID, &policy.CreatedAt)
}

func (r *InsuranceRepository) FindPolicyByID(id uuid.UUID) (*models.InsurancePolicy, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	p := &models.InsurancePolicy{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, driver_id, product_id, policy_number, premium, payment_method,
		 status, start_date, end_date, created_at
		 FROM insurance_policies WHERE id = $1`, id,
	).Scan(
		&p.ID, &p.DriverID, &p.ProductID, &p.PolicyNumber,
		&p.Premium, &p.PaymentMethod, &p.Status,
		&p.StartDate, &p.EndDate, &p.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (r *InsuranceRepository) ListPoliciesByDriver(driverID uuid.UUID) ([]models.InsurancePolicy, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, driver_id, product_id, policy_number, premium, payment_method,
		 status, start_date, end_date, created_at
		 FROM insurance_policies WHERE driver_id = $1 ORDER BY created_at DESC`,
		driverID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var policies []models.InsurancePolicy
	for rows.Next() {
		p := models.InsurancePolicy{}
		if err := rows.Scan(
			&p.ID, &p.DriverID, &p.ProductID, &p.PolicyNumber,
			&p.Premium, &p.PaymentMethod, &p.Status,
			&p.StartDate, &p.EndDate, &p.CreatedAt,
		); err != nil {
			return nil, err
		}
		policies = append(policies, p)
	}
	return policies, nil
}

func (r *InsuranceRepository) UpdatePolicy(policy *models.InsurancePolicy) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE insurance_policies SET
			status=$2, end_date=$3
		 WHERE id=$1`,
		policy.ID, policy.Status, policy.EndDate,
	)
	return err
}

func (r *InsuranceRepository) GeneratePolicyNumber() (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Format: KOP-YYYYMM-XXXXX
	yearMonth := time.Now().Format("200601")
	prefix := fmt.Sprintf("KOP-%s-", yearMonth)

	var maxNum int
	err := r.pool.QueryRow(ctx,
		`SELECT COALESCE(MAX(CAST(SUBSTRING(policy_number FROM $1) AS INTEGER)), 0)
		 FROM insurance_policies WHERE policy_number LIKE $2`,
		len(prefix)+1, prefix+"%",
	).Scan(&maxNum)
	if err != nil {
		// If no rows or error, start from 1
		maxNum = 0
	}

	return fmt.Sprintf("%s%05d", prefix, maxNum+1), nil
}

// ========== Claims ==========

func (r *InsuranceRepository) CreateClaim(claim *models.InsuranceClaim) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO insurance_claims (
			policy_id, driver_id, claim_type, description, evidence_urls, status
		) VALUES ($1,$2,$3,$4,$5,$6)
		RETURNING id, created_at`,
		claim.PolicyID, claim.DriverID, claim.ClaimType,
		claim.Description, claim.EvidenceURLs, claim.Status,
	).Scan(&claim.ID, &claim.CreatedAt)
}

func (r *InsuranceRepository) FindClaimByID(id uuid.UUID) (*models.InsuranceClaim, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	c := &models.InsuranceClaim{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, policy_id, driver_id, claim_type, description, evidence_urls,
		 status, admin_notes, resolved_at, created_at
		 FROM insurance_claims WHERE id = $1`, id,
	).Scan(
		&c.ID, &c.PolicyID, &c.DriverID, &c.ClaimType,
		&c.Description, &c.EvidenceURLs, &c.Status,
		&c.AdminNotes, &c.ResolvedAt, &c.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return c, nil
}

func (r *InsuranceRepository) ListClaimsByDriver(driverID uuid.UUID) ([]models.InsuranceClaim, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, policy_id, driver_id, claim_type, description, evidence_urls,
		 status, admin_notes, resolved_at, created_at
		 FROM insurance_claims WHERE driver_id = $1 ORDER BY created_at DESC`,
		driverID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var claims []models.InsuranceClaim
	for rows.Next() {
		c := models.InsuranceClaim{}
		if err := rows.Scan(
			&c.ID, &c.PolicyID, &c.DriverID, &c.ClaimType,
			&c.Description, &c.EvidenceURLs, &c.Status,
			&c.AdminNotes, &c.ResolvedAt, &c.CreatedAt,
		); err != nil {
			return nil, err
		}
		claims = append(claims, c)
	}
	return claims, nil
}

// ========== Seed ==========

func (r *InsuranceRepository) SeedProducts(products []models.InsuranceProduct) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	for _, p := range products {
		coverageJSON, err := json.Marshal(p.CoverageDetails)
		if err != nil {
			return fmt.Errorf("marshal coverage_details for %s: %w", p.Name, err)
		}

		_, err = r.pool.Exec(ctx,
			`INSERT INTO insurance_products (name, description, product_type, icon, coverage_details, price_member, price_non_member, partner_name, status)
			 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
			 ON CONFLICT (name) DO NOTHING`,
			p.Name, p.Description, p.ProductType, p.Icon,
			coverageJSON, p.PriceMember, p.PriceNonMember,
			p.PartnerName, p.Status,
		)
		if err != nil {
			return fmt.Errorf("seed product %s: %w", p.Name, err)
		}
	}
	return nil
}
