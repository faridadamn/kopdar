package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
)

type PinjolRepository struct {
	pool *pgxpool.Pool
}

func NewPinjolRepository(pool *pgxpool.Pool) *PinjolRepository {
	return &PinjolRepository{pool: pool}
}

func (r *PinjolRepository) Create(p *models.PinjolRecord) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO pinjol_records (
			driver_id, app_name, principal, interest_rate, monthly_installment,
			outstanding_amount, total_paid_interest, start_date, end_date, risk_level
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
		RETURNING id, created_at, updated_at`,
		p.DriverID, p.AppName, p.Principal, p.InterestRate, p.MonthlyInstallment,
		p.OutstandingAmount, p.TotalPaidInterest, p.StartDate, p.EndDate, p.RiskLevel,
	).Scan(&p.ID, &p.CreatedAt, &p.UpdatedAt)
}

func (r *PinjolRepository) FindByID(id uuid.UUID) (*models.PinjolRecord, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	p := &models.PinjolRecord{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, driver_id, app_name, principal, interest_rate, monthly_installment,
		 outstanding_amount, total_paid_interest, start_date, end_date, risk_level,
		 created_at, updated_at
		 FROM pinjol_records WHERE id = $1`, id,
	).Scan(&p.ID, &p.DriverID, &p.AppName, &p.Principal, &p.InterestRate,
		&p.MonthlyInstallment, &p.OutstandingAmount, &p.TotalPaidInterest,
		&p.StartDate, &p.EndDate, &p.RiskLevel,
		&p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (r *PinjolRepository) ListByDriver(driverID uuid.UUID) ([]models.PinjolRecord, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, driver_id, app_name, principal, interest_rate, monthly_installment,
		 outstanding_amount, total_paid_interest, start_date, end_date, risk_level,
		 created_at, updated_at
		 FROM pinjol_records WHERE driver_id = $1 ORDER BY created_at DESC`,
		driverID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var records []models.PinjolRecord
	for rows.Next() {
		p := models.PinjolRecord{}
		if err := rows.Scan(
			&p.ID, &p.DriverID, &p.AppName, &p.Principal, &p.InterestRate,
			&p.MonthlyInstallment, &p.OutstandingAmount, &p.TotalPaidInterest,
			&p.StartDate, &p.EndDate, &p.RiskLevel,
			&p.CreatedAt, &p.UpdatedAt,
		); err != nil {
			return nil, err
		}
		records = append(records, p)
	}
	return records, nil
}

func (r *PinjolRepository) Update(p *models.PinjolRecord) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE pinjol_records SET
			outstanding_amount=$2, interest_rate=$3, risk_level=$4, updated_at=NOW()
		 WHERE id=$1`,
		p.ID, p.OutstandingAmount, p.InterestRate, p.RiskLevel,
	)
	return err
}

func (r *PinjolRepository) Delete(id uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`DELETE FROM pinjol_records WHERE id = $1`, id,
	)
	return err
}
