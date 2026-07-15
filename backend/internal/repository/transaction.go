package repository

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
)

type TransactionRepository struct {
	pool *pgxpool.Pool
}

func NewTransactionRepository(pool *pgxpool.Pool) *TransactionRepository {
	return &TransactionRepository{pool: pool}
}

func (r *TransactionRepository) Create(txn *models.DriverTransaction) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO driver_transactions (
			driver_id, type, category, platform, amount, commission, net_amount,
			notes, receipt_url, order_count
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
		RETURNING id, created_at, updated_at`,
		txn.DriverID, txn.Type, txn.Category, txn.Platform,
		txn.Amount, txn.Commission, txn.NetAmount,
		txn.Notes, txn.ReceiptURL, txn.OrderCount,
	).Scan(&txn.ID, &txn.CreatedAt, &txn.UpdatedAt)
}

func (r *TransactionRepository) FindByID(id uuid.UUID) (*models.DriverTransaction, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	txn := &models.DriverTransaction{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, driver_id, type, category, platform, amount, commission, net_amount,
		 notes, receipt_url, order_count, created_at, updated_at
		 FROM driver_transactions WHERE id = $1 AND deleted_at IS NULL`, id).Scan(
		&txn.ID, &txn.DriverID, &txn.Type, &txn.Category, &txn.Platform,
		&txn.Amount, &txn.Commission, &txn.NetAmount,
		&txn.Notes, &txn.ReceiptURL, &txn.OrderCount,
		&txn.CreatedAt, &txn.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return txn, nil
}

func (r *TransactionRepository) Update(txn *models.DriverTransaction) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE driver_transactions SET
			amount=$2, commission=$3, net_amount=$4, notes=$5, category=$6, updated_at=NOW()
		 WHERE id=$1 AND deleted_at IS NULL`,
		txn.ID, txn.Amount, txn.Commission, txn.NetAmount, txn.Notes, txn.Category,
	)
	return err
}

func (r *TransactionRepository) SoftDelete(id uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE driver_transactions SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL`, id)
	return err
}

func (r *TransactionRepository) List(driverID uuid.UUID, f models.TransactionFilter) ([]models.DriverTransaction, int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if f.Page < 1 {
		f.Page = 1
	}
	if f.Limit < 1 || f.Limit > 100 {
		f.Limit = 20
	}
	offset := (f.Page - 1) * f.Limit

	// Build WHERE clause
	where := []string{"driver_id = $1", "deleted_at IS NULL"}
	args := []interface{}{driverID}
	argIdx := 2

	if f.Type != "" {
		where = append(where, fmt.Sprintf("type = $%d", argIdx))
		args = append(args, f.Type)
		argIdx++
	}
	if f.Platform != "" {
		where = append(where, fmt.Sprintf("platform = $%d", argIdx))
		args = append(args, f.Platform)
		argIdx++
	}
	if f.DateFrom != "" {
		where = append(where, fmt.Sprintf("created_at >= $%d", argIdx))
		args = append(args, f.DateFrom)
		argIdx++
	}
	if f.DateTo != "" {
		where = append(where, fmt.Sprintf("created_at <= $%d", argIdx))
		// Add one day to include the full "to" date
		args = append(args, f.DateTo+" 23:59:59")
		argIdx++
	}

	whereClause := strings.Join(where, " AND ")

	// Count
	var total int64
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM driver_transactions WHERE `+whereClause, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Fetch with pagination
	args = append(args, f.Limit, offset)
	rows, err := r.pool.Query(ctx,
		`SELECT id, driver_id, type, category, platform, amount, commission, net_amount,
		 notes, receipt_url, order_count, created_at, updated_at
		 FROM driver_transactions WHERE `+whereClause+
			` ORDER BY created_at DESC LIMIT $`+fmt.Sprint(argIdx)+` OFFSET $`+fmt.Sprint(argIdx+1),
		args...,
	)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var txns []models.DriverTransaction
	for rows.Next() {
		t := models.DriverTransaction{}
		err := rows.Scan(
			&t.ID, &t.DriverID, &t.Type, &t.Category, &t.Platform,
			&t.Amount, &t.Commission, &t.NetAmount,
			&t.Notes, &t.ReceiptURL, &t.OrderCount,
			&t.CreatedAt, &t.UpdatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		txns = append(txns, t)
	}

	return txns, total, nil
}

func (r *TransactionRepository) GetSummary(driverID uuid.UUID, dateFrom, dateTo string) (*models.TransactionSummary, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	summary := &models.TransactionSummary{}

	// Totals
	err := r.pool.QueryRow(ctx,
		`SELECT
			COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END), 0),
			COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END), 0),
			COALESCE(SUM(CASE WHEN type='income' THEN net_amount ELSE -amount END), 0),
			COALESCE(SUM(CASE WHEN type='income' THEN order_count ELSE 0 END), 0)
		 FROM driver_transactions
		 WHERE driver_id = $1 AND deleted_at IS NULL AND created_at >= $2 AND created_at <= $3`,
		driverID, dateFrom, dateTo+" 23:59:59",
	).Scan(&summary.TotalIncome, &summary.TotalExpense, &summary.Profit, &summary.TotalOrders)
	if err != nil {
		return nil, err
	}

	if summary.TotalOrders > 0 {
		summary.AvgPerOrder = summary.TotalIncome / float64(summary.TotalOrders)
	}

	// Income by platform
	platformRows, err := r.pool.Query(ctx,
		`SELECT COALESCE(platform, 'unknown'), SUM(amount), SUM(order_count)
		 FROM driver_transactions
		 WHERE driver_id = $1 AND type = 'income' AND deleted_at IS NULL
		   AND created_at >= $2 AND created_at <= $3
		 GROUP BY platform ORDER BY SUM(amount) DESC`,
		driverID, dateFrom, dateTo+" 23:59:59",
	)
	if err != nil {
		return nil, err
	}
	defer platformRows.Close()

	for platformRows.Next() {
		var ps models.PlatformSummary
		if err := platformRows.Scan(&ps.Platform, &ps.Total, &ps.Count); err != nil {
			return nil, err
		}
		summary.IncomeByPlatform = append(summary.IncomeByPlatform, ps)
	}

	// Expense by category
	categoryRows, err := r.pool.Query(ctx,
		`SELECT category, SUM(amount), COUNT(*)
		 FROM driver_transactions
		 WHERE driver_id = $1 AND type = 'expense' AND deleted_at IS NULL
		   AND created_at >= $2 AND created_at <= $3
		 GROUP BY category ORDER BY SUM(amount) DESC`,
		driverID, dateFrom, dateTo+" 23:59:59",
	)
	if err != nil {
		return nil, err
	}
	defer categoryRows.Close()

	for categoryRows.Next() {
		var cs models.CategorySummary
		if err := categoryRows.Scan(&cs.Category, &cs.Total, &cs.Count); err != nil {
			return nil, err
		}
		summary.ExpenseByCategory = append(summary.ExpenseByCategory, cs)
	}

	// Daily breakdown
	dailyRows, err := r.pool.Query(ctx,
		`SELECT
			TO_CHAR(created_at, 'YYYY-MM-DD') AS date,
			COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END), 0) AS income,
			COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END), 0) AS expense,
			COALESCE(SUM(CASE WHEN type='income' THEN net_amount ELSE -amount END), 0) AS profit
		 FROM driver_transactions
		 WHERE driver_id = $1 AND deleted_at IS NULL
		   AND created_at >= $2 AND created_at <= $3
		 GROUP BY TO_CHAR(created_at, 'YYYY-MM-DD')
		 ORDER BY date DESC`,
		driverID, dateFrom, dateTo+" 23:59:59",
	)
	if err != nil {
		return nil, err
	}
	defer dailyRows.Close()

	for dailyRows.Next() {
		var ds models.DailySummary
		if err := dailyRows.Scan(&ds.Date, &ds.Income, &ds.Expense, &ds.Profit); err != nil {
			return nil, err
		}
		summary.DailyBreakdown = append(summary.DailyBreakdown, ds)
	}

	return summary, nil
}

// Dashboard-specific queries

func (r *TransactionRepository) GetDailyIncome(driverID uuid.UUID, date string) (float64, int, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var amount float64
	var orderCount int
	err := r.pool.QueryRow(ctx,
		`SELECT COALESCE(SUM(amount), 0), COALESCE(SUM(order_count), 0)
		 FROM driver_transactions
		 WHERE driver_id = $1 AND type = 'income' AND deleted_at IS NULL
		   AND created_at::date = $2::date`,
		driverID, date,
	).Scan(&amount, &orderCount)
	return amount, orderCount, err
}

func (r *TransactionRepository) GetDailyHours(driverID uuid.UUID, date string) (float64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var hours *float64
	err := r.pool.QueryRow(ctx,
		`SELECT EXTRACT(EPOCH FROM (MAX(created_at) - MIN(created_at))) / 3600.0
		 FROM driver_transactions
		 WHERE driver_id = $1 AND type = 'income' AND deleted_at IS NULL
		   AND created_at::date = $2::date`,
		driverID, date,
	).Scan(&hours)
	if err != nil {
		return 0, err
	}
	if hours == nil {
		return 0, nil
	}
	return *hours, nil
}

func (r *TransactionRepository) GetRecentTransactions(driverID uuid.UUID, limit int) ([]models.DriverTransaction, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, driver_id, type, category, platform, amount, commission, net_amount,
		 notes, receipt_url, order_count, created_at, updated_at
		 FROM driver_transactions
		 WHERE driver_id = $1 AND deleted_at IS NULL
		 ORDER BY created_at DESC LIMIT $2`,
		driverID, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var txns []models.DriverTransaction
	for rows.Next() {
		t := models.DriverTransaction{}
		if err := rows.Scan(
			&t.ID, &t.DriverID, &t.Type, &t.Category, &t.Platform,
			&t.Amount, &t.Commission, &t.NetAmount,
			&t.Notes, &t.ReceiptURL, &t.OrderCount,
			&t.CreatedAt, &t.UpdatedAt,
		); err != nil {
			return nil, err
		}
		txns = append(txns, t)
	}
	return txns, nil
}

func (r *TransactionRepository) GetEmergencyFund(driverID uuid.UUID) (current float64, err error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err = r.pool.QueryRow(ctx,
		`SELECT COALESCE(balance, 0) FROM savings
		 WHERE user_id = (SELECT user_id FROM drivers WHERE id = $1) AND type = 'emergency'`,
		driverID,
	).Scan(&current)
	return
}
