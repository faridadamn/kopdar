package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
)

type ProfileRepository struct {
	pool *pgxpool.Pool
}

func NewProfileRepository(pool *pgxpool.Pool) *ProfileRepository {
	return &ProfileRepository{pool: pool}
}

// ==================== Driver Points ====================

// GetOrCreatePoints returns the driver's points record, creating one if it doesn't exist
func (r *ProfileRepository) GetOrCreatePoints(driverID uuid.UUID) (*models.DriverPoints, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	dp := &models.DriverPoints{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, driver_id, points, level, created_at, updated_at
		 FROM driver_points WHERE driver_id = $1`, driverID).Scan(
		&dp.ID, &dp.DriverID, &dp.Points, &dp.Level, &dp.CreatedAt, &dp.UpdatedAt,
	)
	if err != nil {
		// Create if not exists
		err = r.pool.QueryRow(ctx,
			`INSERT INTO driver_points (driver_id, points, level) VALUES ($1, 0, 'bronze')
			 RETURNING id, driver_id, points, level, created_at, updated_at`,
			driverID).Scan(
			&dp.ID, &dp.DriverID, &dp.Points, &dp.Level, &dp.CreatedAt, &dp.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
	}
	return dp, nil
}

// UpdatePoints updates points and level
func (r *ProfileRepository) UpdatePoints(driverID uuid.UUID, points int, level string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE driver_points SET points = $2, level = $3, updated_at = NOW()
		 WHERE driver_id = $1`,
		driverID, points, level,
	)
	return err
}

// AddPointsHistory logs a points transaction
func (r *ProfileRepository) AddPointsHistory(driverID uuid.UUID, action string, points int) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`INSERT INTO points_history (driver_id, action, points) VALUES ($1, $2, $3)`,
		driverID, action, points,
	)
	return err
}

// GetPointsHistory returns the points history for a driver
func (r *ProfileRepository) GetPointsHistory(driverID uuid.UUID, limit int) ([]models.PointsHistory, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, driver_id, action, points, created_at
		 FROM points_history WHERE driver_id = $1
		 ORDER BY created_at DESC LIMIT $2`,
		driverID, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var history []models.PointsHistory
	for rows.Next() {
		h := models.PointsHistory{}
		if err := rows.Scan(&h.ID, &h.DriverID, &h.Action, &h.Points, &h.CreatedAt); err != nil {
			return nil, err
		}
		history = append(history, h)
	}
	return history, nil
}

// ==================== Driver Settings ====================

// GetOrCreateSettings returns settings, creating defaults if not exists
func (r *ProfileRepository) GetOrCreateSettings(driverID uuid.UUID) (*models.DriverSettings, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	s := &models.DriverSettings{}
	var notifBytes, quietBytes []byte

	err := r.pool.QueryRow(ctx,
		`SELECT id, driver_id, language, zone_id, auto_save_enabled, auto_save_amount,
		 notifications, quiet_hours, biometric_enabled, created_at, updated_at
		 FROM driver_settings WHERE driver_id = $1`, driverID).Scan(
		&s.ID, &s.DriverID, &s.Language, &s.ZoneID,
		&s.AutoSaveEnabled, &s.AutoSaveAmount,
		&notifBytes, &quietBytes, &s.BiometricEnabled,
		&s.CreatedAt, &s.UpdatedAt,
	)
	if err != nil {
		// Create defaults
		defaultNotif := models.Notifications{
			Community:  true,
			Savings:    true,
			Insurance:  true,
			Advocacy:   true,
			Promotions: false,
		}
		defaultQuiet := models.QuietHours{
			Enabled: false,
			Start:   "23:00",
			End:     "07:00",
		}
		notifJSON, _ := json.Marshal(defaultNotif)
		quietJSON, _ := json.Marshal(defaultQuiet)

		err = r.pool.QueryRow(ctx,
			`INSERT INTO driver_settings (driver_id, language, zone_id, auto_save_enabled, auto_save_amount,
			 notifications, quiet_hours, biometric_enabled)
			 VALUES ($1, 'id', '', true, 10000, $2, $3, false)
			 RETURNING id, driver_id, language, zone_id, auto_save_enabled, auto_save_amount,
			 notifications, quiet_hours, biometric_enabled, created_at, updated_at`,
			driverID, notifJSON, quietJSON).Scan(
			&s.ID, &s.DriverID, &s.Language, &s.ZoneID,
			&s.AutoSaveEnabled, &s.AutoSaveAmount,
			&notifBytes, &quietBytes, &s.BiometricEnabled,
			&s.CreatedAt, &s.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
	}

	if notifBytes != nil {
		json.Unmarshal(notifBytes, &s.Notifications)
	}
	if quietBytes != nil {
		json.Unmarshal(quietBytes, &s.QuietHours)
	}

	return s, nil
}

// UpdateSettings updates driver settings
func (r *ProfileRepository) UpdateSettings(s *models.DriverSettings) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	notifJSON, _ := json.Marshal(s.Notifications)
	quietJSON, _ := json.Marshal(s.QuietHours)

	_, err := r.pool.Exec(ctx,
		`UPDATE driver_settings SET
			language = $2, zone_id = $3, auto_save_enabled = $4, auto_save_amount = $5,
			notifications = $6, quiet_hours = $7, biometric_enabled = $8, updated_at = NOW()
		 WHERE driver_id = $1`,
		s.DriverID, s.Language, s.ZoneID,
		s.AutoSaveEnabled, s.AutoSaveAmount,
		notifJSON, quietJSON, s.BiometricEnabled,
	)
	return err
}

// ==================== Referrals ====================

// GetReferralByCode finds a driver by their referral code
func (r *ProfileRepository) GetDriverByReferralCode(code string) (*models.Driver, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	d := &models.Driver{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, nik, date_of_birth, address, city, province, postal_code,
		 ktp_photo_url, selfie_photo_url, vehicle_type, vehicle_plate, vehicle_year,
		 stnk_photo_url, verification_status, rejection_reason, verified_at, verified_by,
		 referral_code, emergency_contact_name, emergency_contact_phone, created_at, updated_at
		 FROM drivers WHERE referral_code = $1`, code).Scan(
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

// CreateReferral creates a referral record
func (r *ProfileRepository) CreateReferral(ref *models.Referral) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`INSERT INTO referrals (referrer_id, referred_id, referral_code, bonus_amount, status)
		 VALUES ($1, $2, $3, $4, $5)`,
		ref.ReferrerID, ref.ReferredID, ref.ReferralCode, ref.Bonus, ref.Status,
	)
	return err
}

// GetReferralsByReferrer returns all referrals made by a driver
func (r *ProfileRepository) GetReferralsByReferrer(referrerID uuid.UUID) ([]models.Referral, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, referrer_id, referred_id, referral_code, bonus_amount, status, created_at
		 FROM referrals WHERE referrer_id = $1
		 ORDER BY created_at DESC`, referrerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var referrals []models.Referral
	for rows.Next() {
		ref := models.Referral{}
		if err := rows.Scan(&ref.ID, &ref.ReferrerID, &ref.ReferredID,
			&ref.ReferralCode, &ref.Bonus, &ref.Status, &ref.CreatedAt); err != nil {
			return nil, err
		}
		referrals = append(referrals, ref)
	}
	return referrals, nil
}

// HasReferral checks if a user was already referred
func (r *ProfileRepository) HasReferral(referredID uuid.UUID) (bool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var count int
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM referrals WHERE referred_id = $1`, referredID).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// GetUserName returns the full name of a user
func (r *ProfileRepository) GetUserName(userID uuid.UUID) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var name *string
	err := r.pool.QueryRow(ctx,
		`SELECT full_name FROM users WHERE id = $1`, userID).Scan(&name)
	if err != nil {
		return "", err
	}
	if name == nil {
		return "Driver KopDar", nil
	}
	return *name, nil
}

// ==================== Profile Stats ====================

// GetDriverStats returns aggregated stats for a driver
func (r *ProfileRepository) GetDriverStats(driverID uuid.UUID) (*models.ProfileStats, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	stats := &models.ProfileStats{}

	// Total orders (transactions)
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM driver_transactions WHERE driver_id = $1`, driverID).Scan(&stats.TotalOrders)
	if err != nil {
		stats.TotalOrders = 0
	}

	// Total earnings
	err = r.pool.QueryRow(ctx,
		`SELECT COALESCE(SUM(amount), 0) FROM driver_transactions WHERE driver_id = $1 AND type = 'income'`,
		driverID).Scan(&stats.TotalEarnings)
	if err != nil {
		stats.TotalEarnings = 0
	}

	// Active days (distinct dates with transactions)
	err = r.pool.QueryRow(ctx,
		`SELECT COUNT(DISTINCT DATE(created_at)) FROM driver_transactions WHERE driver_id = $1`,
		driverID).Scan(&stats.ActiveDays)
	if err != nil {
		stats.ActiveDays = 0
	}

	// Rating (placeholder - can be connected to real rating system)
	stats.Rating = 4.9

	return stats, nil
}

// GetDriverPlatforms returns platforms for a driver
func (r *ProfileRepository) GetDriverPlatforms(driverID uuid.UUID) ([]models.DriverPlatform, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, driver_id, platform, platform_driver_id, is_active, joined_at, created_at
		 FROM driver_platforms WHERE driver_id = $1`, driverID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var platforms []models.DriverPlatform
	for rows.Next() {
		p := models.DriverPlatform{}
		if err := rows.Scan(&p.ID, &p.DriverID, &p.Platform,
			&p.PlatformDriverID, &p.IsActive, &p.JoinedAt, &p.CreatedAt); err != nil {
			return nil, err
		}
		platforms = append(platforms, p)
	}
	return platforms, nil
}

// UpdateDriverPhoto updates the selfie photo URL
func (r *ProfileRepository) UpdateDriverPhoto(driverID uuid.UUID, photoURL string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE drivers SET selfie_photo_url = $2, updated_at = NOW() WHERE id = $1`,
		driverID, photoURL,
	)
	return err
}

// UpdateUserAvatar updates the user's avatar URL
func (r *ProfileRepository) UpdateUserAvatar(userID uuid.UUID, avatarURL string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE users SET avatar_url = $2, updated_at = NOW() WHERE id = $1`,
		userID, avatarURL,
	)
	return err
}

// SoftDeleteAccount soft deletes a user account
func (r *ProfileRepository) SoftDeleteAccount(userID uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE users SET status = 'suspended', updated_at = NOW() WHERE id = $1`,
		userID,
	)
	return err
}
