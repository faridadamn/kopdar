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

func (r *DriverRepository) Create(driver *models.Driver) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO drivers (
			user_id, nik, date_of_birth, address, city, province, postal_code,
			ktp_photo_url, selfie_photo_url, vehicle_type, vehicle_plate, vehicle_year,
			stnk_photo_url, emergency_contact_name, emergency_contact_phone
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
		RETURNING id, created_at, updated_at`,
		driver.UserID, driver.NIK, driver.DateOfBirth, driver.Address,
		driver.City, driver.Province, driver.PostalCode,
		driver.KTPPhotoURL, driver.SelfiePhotoURL,
		driver.VehicleType, driver.VehiclePlate, driver.VehicleYear,
		driver.STNKPhotoURL, driver.EmergencyContactName, driver.EmergencyContactPhone,
	).Scan(&driver.ID, &driver.CreatedAt, &driver.UpdatedAt)
}

func (r *DriverRepository) FindByUserID(userID uuid.UUID) (*models.Driver, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	d := &models.Driver{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, nik, date_of_birth, address, city, province, postal_code,
		 ktp_photo_url, selfie_photo_url, vehicle_type, vehicle_plate, vehicle_year,
		 stnk_photo_url, verification_status, rejection_reason, verified_at, verified_by,
		 referral_code, emergency_contact_name, emergency_contact_phone, created_at, updated_at
		 FROM drivers WHERE user_id = $1`, userID).Scan(
		&d.ID, &d.UserID, &d.NIK, &d.DateOfBirth, &d.Address, &d.City, &d.Province, &d.PostalCode,
		&d.KTPPhotoURL, &d.SelfiePhotoURL, &d.VehicleType, &d.VehiclePlate, &d.VehicleYear,
		&d.STNKPhotoURL, &d.VerificationStatus, &d.RejectionReason, &d.VerifiedAt, &d.VerifiedBy,
		&d.ReferralCode, &d.EmergencyContactName, &d.EmergencyContactPhone, &d.CreatedAt, &d.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return d, nil
}

func (r *DriverRepository) FindByID(id uuid.UUID) (*models.Driver, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	d := &models.Driver{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, nik, date_of_birth, address, city, province, postal_code,
		 ktp_photo_url, selfie_photo_url, vehicle_type, vehicle_plate, vehicle_year,
		 stnk_photo_url, verification_status, rejection_reason, verified_at, verified_by,
		 referral_code, emergency_contact_name, emergency_contact_phone, created_at, updated_at
		 FROM drivers WHERE id = $1`, id).Scan(
		&d.ID, &d.UserID, &d.NIK, &d.DateOfBirth, &d.Address, &d.City, &d.Province, &d.PostalCode,
		&d.KTPPhotoURL, &d.SelfiePhotoURL, &d.VehicleType, &d.VehiclePlate, &d.VehicleYear,
		&d.STNKPhotoURL, &d.VerificationStatus, &d.RejectionReason, &d.VerifiedAt, &d.VerifiedBy,
		&d.ReferralCode, &d.EmergencyContactName, &d.EmergencyContactPhone, &d.CreatedAt, &d.UpdatedAt,
	)
	if err != nil {
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
			vehicle_type=$8, vehicle_plate=$9, vehicle_year=$10,
			emergency_contact_name=$11, emergency_contact_phone=$12
		 WHERE id=$1`,
		driver.ID, driver.NIK, driver.DateOfBirth, driver.Address,
		driver.City, driver.Province, driver.PostalCode,
		driver.VehicleType, driver.VehiclePlate, driver.VehicleYear,
		driver.EmergencyContactName, driver.EmergencyContactPhone,
	)
	return err
}

func (r *DriverRepository) UpdateVerificationStatus(id uuid.UUID, status string, reason *string, verifiedBy uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	now := time.Now()
	_, err := r.pool.Exec(ctx,
		`UPDATE drivers SET verification_status=$2, rejection_reason=$3, verified_at=$4, verified_by=$5
		 WHERE id=$1`,
		id, status, reason, now, verifiedBy,
	)
	return err
}

// ListPending returns paginated pending drivers with optional search
func (r *DriverRepository) ListPending(page, pageSize int, search string) ([]models.Driver, int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	offset := (page - 1) * pageSize

	// Build query
	baseQuery := `FROM drivers d JOIN users u ON d.user_id = u.id WHERE d.verification_status = 'pending'`
	args := []interface{}{}
	argIdx := 1

	if search != "" {
		baseQuery += ` AND (u.full_name ILIKE $` + itoa(argIdx) + ` OR d.nik ILIKE $` + itoa(argIdx) + ` OR u.phone ILIKE $` + itoa(argIdx) + `)`
		args = append(args, "%"+search+"%")
		argIdx++
	}

	// Count
	var total int64
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) `+baseQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Fetch
	args = append(args, pageSize, offset)
	rows, err := r.pool.Query(ctx,
		`SELECT d.id, d.user_id, d.nik, d.date_of_birth, d.address, d.city, d.province, d.postal_code,
		 d.ktp_photo_url, d.selfie_photo_url, d.vehicle_type, d.vehicle_plate, d.vehicle_year,
		 d.stnk_photo_url, d.verification_status, d.rejection_reason, d.verified_at, d.verified_by,
		 d.referral_code, d.emergency_contact_name, d.emergency_contact_phone, d.created_at, d.updated_at
		 `+baseQuery+` ORDER BY d.created_at DESC LIMIT $`+itoa(argIdx)+` OFFSET $`+itoa(argIdx+1),
		args...,
	)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var drivers []models.Driver
	for rows.Next() {
		d := models.Driver{}
		err := rows.Scan(
			&d.ID, &d.UserID, &d.NIK, &d.DateOfBirth, &d.Address, &d.City, &d.Province, &d.PostalCode,
			&d.KTPPhotoURL, &d.SelfiePhotoURL, &d.VehicleType, &d.VehiclePlate, &d.VehicleYear,
			&d.STNKPhotoURL, &d.VerificationStatus, &d.RejectionReason, &d.VerifiedAt, &d.VerifiedBy,
			&d.ReferralCode, &d.EmergencyContactName, &d.EmergencyContactPhone, &d.CreatedAt, &d.UpdatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		drivers = append(drivers, d)
	}

	return drivers, total, nil
}

// CountByStatus counts drivers by verification status
func (r *DriverRepository) CountByStatus(status string) (int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var count int64
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM drivers WHERE verification_status = $1`, status).Scan(&count)
	return count, err
}

// CountTotal counts all drivers
func (r *DriverRepository) CountTotal() (int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var count int64
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM drivers`).Scan(&count)
	return count, err
}

// AddPlatform adds a platform association for a driver
func (r *DriverRepository) AddPlatform(driverID uuid.UUID, platform string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`INSERT INTO driver_platforms (driver_id, platform) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
		driverID, platform,
	)
	return err
}

// CountActiveEmergencies counts active emergencies
func (r *DriverRepository) CountActiveEmergencies() (int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var count int64
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM emergencies WHERE status = 'active'`).Scan(&count)
	return count, err
}


