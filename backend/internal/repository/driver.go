package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
)

type DriverRepository struct {
	pool *pgxpool.Pool
}

func NewDriverRepository(pool *pgxpool.Pool) *DriverRepository {
	return &DriverRepository{pool: pool}
}

const driverColumns = `id, user_id, nik, date_of_birth, address, city, province, postal_code,
	ktp_photo_url, selfie_photo_url, vehicle_type, vehicle_brand, vehicle_model, vehicle_color,
	vehicle_plate, vehicle_year, stnk_photo_url, bank_name, bank_account_number, bank_account_name,
	verification_status, rejection_reason, verified_at, verified_by, referral_code,
	emergency_contact_name, emergency_contact_phone, created_at, updated_at`

func scanDriver(row interface{ Scan(...any) error }, d *models.Driver) error {
	return row.Scan(
		&d.ID, &d.UserID, &d.NIK, &d.DateOfBirth, &d.Address, &d.City, &d.Province, &d.PostalCode,
		&d.KTPPhotoURL, &d.SelfiePhotoURL, &d.VehicleType, &d.VehicleBrand, &d.VehicleModel, &d.VehicleColor,
		&d.VehiclePlate, &d.VehicleYear, &d.STNKPhotoURL, &d.BankName, &d.BankAccountNumber, &d.BankAccountName,
		&d.VerificationStatus, &d.RejectionReason, &d.VerifiedAt, &d.VerifiedBy, &d.ReferralCode,
		&d.EmergencyContactName, &d.EmergencyContactPhone, &d.CreatedAt, &d.UpdatedAt,
	)
}

func (r *DriverRepository) Create(driver *models.Driver) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO drivers (
			user_id, nik, date_of_birth, address, city, province, postal_code,
			ktp_photo_url, selfie_photo_url, vehicle_type, vehicle_brand, vehicle_model, vehicle_color,
			vehicle_plate, vehicle_year, stnk_photo_url, bank_name, bank_account_number, bank_account_name,
			emergency_contact_name, emergency_contact_phone
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21)
		RETURNING id, created_at, updated_at`,
		driver.UserID, driver.NIK, driver.DateOfBirth, driver.Address, driver.City, driver.Province,
		driver.PostalCode, driver.KTPPhotoURL, driver.SelfiePhotoURL, driver.VehicleType,
		driver.VehicleBrand, driver.VehicleModel, driver.VehicleColor, driver.VehiclePlate,
		driver.VehicleYear, driver.STNKPhotoURL, driver.BankName, driver.BankAccountNumber,
		driver.BankAccountName, driver.EmergencyContactName, driver.EmergencyContactPhone,
	).Scan(&driver.ID, &driver.CreatedAt, &driver.UpdatedAt)
}

func (r *DriverRepository) FindByUserID(userID uuid.UUID) (*models.Driver, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	d := &models.Driver{}
	if err := scanDriver(r.pool.QueryRow(ctx, `SELECT `+driverColumns+` FROM drivers WHERE user_id=$1`, userID), d); err != nil {
		return nil, err
	}
	return d, nil
}

func (r *DriverRepository) FindByID(id uuid.UUID) (*models.Driver, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	d := &models.Driver{}
	if err := scanDriver(r.pool.QueryRow(ctx, `SELECT `+driverColumns+` FROM drivers WHERE id=$1`, id), d); err != nil {
		return nil, err
	}
	return d, nil
}

func (r *DriverRepository) Update(driver *models.Driver) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, err := r.pool.Exec(ctx,
		`UPDATE drivers SET
			nik=$2, date_of_birth=$3, address=$4, city=$5, province=$6, postal_code=$7,
			vehicle_type=$8, vehicle_brand=$9, vehicle_model=$10, vehicle_color=$11,
			vehicle_plate=$12, vehicle_year=$13, bank_name=$14, bank_account_number=$15,
			bank_account_name=$16, emergency_contact_name=$17, emergency_contact_phone=$18,
			updated_at=NOW()
		 WHERE id=$1`,
		driver.ID, driver.NIK, driver.DateOfBirth, driver.Address, driver.City, driver.Province,
		driver.PostalCode, driver.VehicleType, driver.VehicleBrand, driver.VehicleModel,
		driver.VehicleColor, driver.VehiclePlate, driver.VehicleYear, driver.BankName,
		driver.BankAccountNumber, driver.BankAccountName, driver.EmergencyContactName,
		driver.EmergencyContactPhone,
	)
	return err
}

func (r *DriverRepository) UpdateVerificationStatus(id uuid.UUID, status string, reason *string, verifiedBy uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, err := r.pool.Exec(ctx,
		`UPDATE drivers SET verification_status=$2, rejection_reason=$3, verified_at=NOW(), verified_by=$4, updated_at=NOW() WHERE id=$1`,
		id, status, reason, verifiedBy,
	)
	return err
}

func (r *DriverRepository) ListPending(page, pageSize int, search string) ([]models.Driver, int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	offset := (page - 1) * pageSize
	baseQuery := `FROM drivers d JOIN users u ON d.user_id=u.id WHERE d.verification_status='pending'`
	args := []interface{}{}
	argIdx := 1
	if search != "" {
		baseQuery += ` AND (u.full_name ILIKE $` + itoa(argIdx) + ` OR d.nik ILIKE $` + itoa(argIdx) + ` OR u.phone ILIKE $` + itoa(argIdx) + `)`
		args = append(args, "%"+search+"%")
		argIdx++
	}
	var total int64
	if err := r.pool.QueryRow(ctx, `SELECT COUNT(*) `+baseQuery, args...).Scan(&total); err != nil {
		return nil, 0, err
	}
	args = append(args, pageSize, offset)
	rows, err := r.pool.Query(ctx,
		`SELECT d.id, d.user_id, d.nik, d.date_of_birth, d.address, d.city, d.province, d.postal_code,
		d.ktp_photo_url, d.selfie_photo_url, d.vehicle_type, d.vehicle_brand, d.vehicle_model, d.vehicle_color,
		d.vehicle_plate, d.vehicle_year, d.stnk_photo_url, d.bank_name, d.bank_account_number, d.bank_account_name,
		d.verification_status, d.rejection_reason, d.verified_at, d.verified_by, d.referral_code,
		d.emergency_contact_name, d.emergency_contact_phone, d.created_at, d.updated_at `+
			baseQuery+` ORDER BY d.created_at DESC LIMIT $`+itoa(argIdx)+` OFFSET $`+itoa(argIdx+1), args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	var drivers []models.Driver
	for rows.Next() {
		d := models.Driver{}
		if err := scanDriver(rows, &d); err != nil {
			return nil, 0, err
		}
		drivers = append(drivers, d)
	}
	return drivers, total, rows.Err()
}

func (r *DriverRepository) CountByStatus(status string) (int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	var count int64
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM drivers WHERE verification_status=$1`, status).Scan(&count)
	return count, err
}

func (r *DriverRepository) CountTotal() (int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	var count int64
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM drivers`).Scan(&count)
	return count, err
}

func (r *DriverRepository) AddPlatform(driverID uuid.UUID, platform string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, err := r.pool.Exec(ctx,
		`INSERT INTO driver_platforms (driver_id, platform) VALUES ($1,$2) ON CONFLICT DO NOTHING`,
		driverID, platform,
	)
	return err
}

func (r *DriverRepository) CountActiveEmergencies() (int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	var count int64
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM emergencies WHERE status='active'`).Scan(&count)
	return count, err
}
