package repository

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/kopdar/backend/internal/models"
)

// RegisterDriver atomically updates the user name, creates the driver profile,
// and stores all selected platform associations. Any failure rolls back the
// complete registration so the account cannot be left partially registered.
func (r *DriverRepository) RegisterDriver(fullName string, driver *models.Driver, platforms []string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin registration transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	result, err := tx.Exec(ctx,
		`UPDATE users SET full_name=$2, updated_at=NOW() WHERE id=$1 AND status <> 'deleted'`,
		driver.UserID, fullName,
	)
	if err != nil {
		return fmt.Errorf("update user profile: %w", err)
	}
	if result.RowsAffected() != 1 {
		return fmt.Errorf("user not found or unavailable")
	}

	err = tx.QueryRow(ctx,
		`INSERT INTO drivers (
			user_id, nik, date_of_birth, address, city, province, postal_code,
			ktp_photo_url, selfie_photo_url, vehicle_type, vehicle_brand, vehicle_model, vehicle_color,
			vehicle_plate, vehicle_year, stnk_photo_url, bank_name, bank_account_number, bank_account_name,
			emergency_contact_name, emergency_contact_phone, referral_code, verification_status
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23)
		RETURNING id, created_at, updated_at`,
		driver.UserID, driver.NIK, driver.DateOfBirth, driver.Address, driver.City, driver.Province,
		driver.PostalCode, driver.KTPPhotoURL, driver.SelfiePhotoURL, driver.VehicleType,
		driver.VehicleBrand, driver.VehicleModel, driver.VehicleColor, driver.VehiclePlate,
		driver.VehicleYear, driver.STNKPhotoURL, driver.BankName, driver.BankAccountNumber,
		driver.BankAccountName, driver.EmergencyContactName, driver.EmergencyContactPhone,
		driver.ReferralCode, driver.VerificationStatus,
	).Scan(&driver.ID, &driver.CreatedAt, &driver.UpdatedAt)
	if err != nil {
		return fmt.Errorf("create driver profile: %w", err)
	}

	seen := make(map[string]struct{}, len(platforms))
	for _, platform := range platforms {
		platform = strings.TrimSpace(platform)
		if platform == "" {
			continue
		}
		key := strings.ToLower(platform)
		if _, duplicate := seen[key]; duplicate {
			continue
		}
		seen[key] = struct{}{}

		if _, err := tx.Exec(ctx,
			`INSERT INTO driver_platforms (driver_id, platform) VALUES ($1,$2) ON CONFLICT DO NOTHING`,
			driver.ID, platform,
		); err != nil {
			return fmt.Errorf("add driver platform: %w", err)
		}
	}
	if len(seen) == 0 {
		return fmt.Errorf("at least one platform is required")
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit registration transaction: %w", err)
	}
	return nil
}
