package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
)

type SavingRepository struct {
	pool *pgxpool.Pool
}

func NewSavingRepository(pool *pgxpool.Pool) *SavingRepository {
	return &SavingRepository{pool: pool}
}

func (r *SavingRepository) Create(s *models.Savings) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO savings (
			driver_id, goal_name, goal_icon, target_amount, current_amount,
			daily_amount, auto_save, status
		) VALUES ($1,$2,$3,$4,0,$5,$6,$7)
		RETURNING id, created_at, updated_at`,
		s.DriverID, s.GoalName, s.GoalIcon, s.TargetAmount,
		s.DailyAmount, s.AutoSave, models.SavingsStatusActive,
	).Scan(&s.ID, &s.CreatedAt, &s.UpdatedAt)
}

func (r *SavingRepository) FindByID(id uuid.UUID) (*models.Savings, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	s := &models.Savings{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, driver_id, goal_name, goal_icon, target_amount, current_amount,
		 daily_amount, auto_save, status, created_at, updated_at
		 FROM savings WHERE id = $1`, id,
	).Scan(&s.ID, &s.DriverID, &s.GoalName, &s.GoalIcon,
		&s.TargetAmount, &s.CurrentAmount, &s.DailyAmount,
		&s.AutoSave, &s.Status, &s.CreatedAt, &s.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return s, nil
}

func (r *SavingRepository) ListByDriver(driverID uuid.UUID) ([]models.Savings, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, driver_id, goal_name, goal_icon, target_amount, current_amount,
		 daily_amount, auto_save, status, created_at, updated_at
		 FROM savings WHERE driver_id = $1 ORDER BY created_at DESC`,
		driverID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var savings []models.Savings
	for rows.Next() {
		s := models.Savings{}
		if err := rows.Scan(
			&s.ID, &s.DriverID, &s.GoalName, &s.GoalIcon,
			&s.TargetAmount, &s.CurrentAmount, &s.DailyAmount,
			&s.AutoSave, &s.Status, &s.CreatedAt, &s.UpdatedAt,
		); err != nil {
			return nil, err
		}
		savings = append(savings, s)
	}
	return savings, nil
}

func (r *SavingRepository) Update(s *models.Savings) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE savings SET
			daily_amount=$2, auto_save=$3, target_amount=$4, status=$5, updated_at=NOW()
		 WHERE id=$1`,
		s.ID, s.DailyAmount, s.AutoSave, s.TargetAmount, s.Status,
	)
	return err
}

func (r *SavingRepository) UpdateAmount(id uuid.UUID, newAmount float64) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE savings SET current_amount=$2, updated_at=NOW() WHERE id=$1`,
		id, newAmount,
	)
	return err
}

func (r *SavingRepository) CreateTransaction(txn *models.SavingsTransaction) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO savings_transactions (
			savings_id, type, amount, method, status, notes
		) VALUES ($1,$2,$3,$4,$5,$6)
		RETURNING id, created_at`,
		txn.SavingsID, txn.Type, txn.Amount, txn.Method, txn.Status, txn.Notes,
	).Scan(&txn.ID, &txn.CreatedAt)
}

func (r *SavingRepository) ListTransactions(savingsID uuid.UUID, limit, offset int) ([]models.SavingsTransaction, int, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if limit < 1 || limit > 100 {
		limit = 20
	}
	if offset < 0 {
		offset = 0
	}

	var total int
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM savings_transactions WHERE savings_id = $1`,
		savingsID,
	).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	rows, err := r.pool.Query(ctx,
		`SELECT id, savings_id, type, amount, method, status, notes, created_at
		 FROM savings_transactions WHERE savings_id = $1
		 ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
		savingsID, limit, offset,
	)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var txns []models.SavingsTransaction
	for rows.Next() {
		t := models.SavingsTransaction{}
		if err := rows.Scan(
			&t.ID, &t.SavingsID, &t.Type, &t.Amount,
			&t.Method, &t.Status, &t.Notes, &t.CreatedAt,
		); err != nil {
			return nil, 0, err
		}
		txns = append(txns, t)
	}
	return txns, total, nil
}

func (r *SavingRepository) GetRecentTransactions(savingsID uuid.UUID, limit int) ([]models.SavingsTransaction, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, savings_id, type, amount, method, status, notes, created_at
		 FROM savings_transactions WHERE savings_id = $1 AND type = 'deposit'
		 ORDER BY created_at DESC LIMIT $2`,
		savingsID, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var txns []models.SavingsTransaction
	for rows.Next() {
		t := models.SavingsTransaction{}
		if err := rows.Scan(
			&t.ID, &t.SavingsID, &t.Type, &t.Amount,
			&t.Method, &t.Status, &t.Notes, &t.CreatedAt,
		); err != nil {
			return nil, err
		}
		txns = append(txns, t)
	}
	return txns, nil
}

// GetAutoSaveSavings returns all active savings with auto_save enabled
func (r *SavingRepository) GetAutoSaveSavings() ([]models.Savings, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, driver_id, goal_name, goal_icon, target_amount, current_amount,
		 daily_amount, auto_save, status, created_at, updated_at
		 FROM savings WHERE auto_save = true AND status = 'active'`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var savings []models.Savings
	for rows.Next() {
		s := models.Savings{}
		if err := rows.Scan(
			&s.ID, &s.DriverID, &s.GoalName, &s.GoalIcon,
			&s.TargetAmount, &s.CurrentAmount, &s.DailyAmount,
			&s.AutoSave, &s.Status, &s.CreatedAt, &s.UpdatedAt,
		); err != nil {
			return nil, err
		}
		savings = append(savings, s)
	}
	return savings, nil
}

// WithTx runs a function within a database transaction
func (r *SavingRepository) WithTx(fn func(tx pgx.Tx) error) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	if err := fn(tx); err != nil {
		return err
	}

	return tx.Commit(ctx)
}

// GetDriverAvgMonthlyIncome returns the average monthly income for a driver
func (r *SavingRepository) GetDriverAvgMonthlyIncome(driverID uuid.UUID) (float64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var avgIncome float64
	err := r.pool.QueryRow(ctx,
		`SELECT COALESCE(AVG(monthly_total), 0) FROM (
			SELECT SUM(amount) as monthly_total
			FROM driver_transactions
			WHERE driver_id = $1 AND type = 'income' AND deleted_at IS NULL
			GROUP BY TO_CHAR(created_at, 'YYYY-MM')
		) monthly`,
		driverID,
	).Scan(&avgIncome)
	if err != nil {
		return 0, err
	}
	return avgIncome, nil
}
