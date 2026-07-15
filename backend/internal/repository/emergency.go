package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
)

type EmergencyRepository struct {
	pool *pgxpool.Pool
}

func NewEmergencyRepository(pool *pgxpool.Pool) *EmergencyRepository {
	return &EmergencyRepository{pool: pool}
}

// ==================== Medical Info ====================

func (r *EmergencyRepository) UpsertMedicalInfo(driverID uuid.UUID, m *models.DriverMedical) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO driver_medical (driver_id, blood_type, allergies, chronic_conditions, medications, emergency_medical_notes, last_checkup_date)
		 VALUES ($1, $2, $3, $4, $5, $6, $7)
		 ON CONFLICT (driver_id) DO UPDATE SET
			blood_type = EXCLUDED.blood_type,
			allergies = EXCLUDED.allergies,
			chronic_conditions = EXCLUDED.chronic_conditions,
			medications = EXCLUDED.medications,
			emergency_medical_notes = EXCLUDED.emergency_medical_notes,
			last_checkup_date = EXCLUDED.last_checkup_date,
			updated_at = NOW()
		 RETURNING id, created_at, updated_at`,
		driverID, m.BloodType, m.Allergies, m.ChronicConditions,
		m.Medications, m.EmergencyMedicalNotes, m.LastCheckupDate,
	).Scan(&m.ID, &m.CreatedAt, &m.UpdatedAt)
}

func (r *EmergencyRepository) GetMedicalInfo(driverID uuid.UUID) (*models.DriverMedical, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	m := &models.DriverMedical{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, driver_id, blood_type, allergies, chronic_conditions, medications,
		 emergency_medical_notes, last_checkup_date, created_at, updated_at
		 FROM driver_medical WHERE driver_id = $1`,
		driverID,
	).Scan(&m.ID, &m.DriverID, &m.BloodType, &m.Allergies, &m.ChronicConditions,
		&m.Medications, &m.EmergencyMedicalNotes, &m.LastCheckupDate,
		&m.CreatedAt, &m.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return m, nil
}

// ==================== Emergency Contacts ====================

func (r *EmergencyRepository) CreateContact(c *models.EmergencyContact) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO emergency_contacts (user_id, name, phone, relationship, is_primary)
		 VALUES ($1, $2, $3, $4, $5)
		 RETURNING id, created_at`,
		c.UserID, c.Name, c.Phone, c.Relationship, c.IsPrimary,
	).Scan(&c.ID, &c.CreatedAt)
}

func (r *EmergencyRepository) ListContacts(userID uuid.UUID) ([]models.EmergencyContact, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, user_id, name, phone, relationship, is_primary, created_at
		 FROM emergency_contacts WHERE user_id = $1 ORDER BY is_primary DESC, created_at ASC`,
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var contacts []models.EmergencyContact
	for rows.Next() {
		var c models.EmergencyContact
		if err := rows.Scan(&c.ID, &c.UserID, &c.Name, &c.Phone,
			&c.Relationship, &c.IsPrimary, &c.CreatedAt); err != nil {
			return nil, err
		}
		contacts = append(contacts, c)
	}
	if contacts == nil {
		contacts = []models.EmergencyContact{}
	}
	return contacts, nil
}

func (r *EmergencyRepository) DeleteContact(id, userID uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`DELETE FROM emergency_contacts WHERE id = $1 AND user_id = $2`,
		id, userID,
	)
	return err
}

func (r *EmergencyRepository) GetPrimaryContact(userID uuid.UUID) (*models.EmergencyContact, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	c := &models.EmergencyContact{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, name, phone, relationship, is_primary, created_at
		 FROM emergency_contacts WHERE user_id = $1 AND is_primary = TRUE LIMIT 1`,
		userID,
	).Scan(&c.ID, &c.UserID, &c.Name, &c.Phone, &c.Relationship, &c.IsPrimary, &c.CreatedAt)
	if err != nil {
		return nil, err
	}
	return c, nil
}

// ==================== Emergencies ====================

func (r *EmergencyRepository) CreateEmergency(e *models.Emergency) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO emergencies (
			user_id, type, description, latitude, longitude, address,
			status, emergency_type, notified_driver_ids, medical_snapshot
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, created_at, updated_at`,
		e.UserID, e.Type, e.Description, e.Latitude, e.Longitude, e.Address,
		models.EmergencyStatusActive, e.EmergencyType, e.NotifiedDriverIDs, e.MedicalSnapshot,
	).Scan(&e.ID, &e.CreatedAt, &e.UpdatedAt)
}

func (r *EmergencyRepository) FindByID(id uuid.UUID) (*models.Emergency, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	e := &models.Emergency{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, type, description, latitude, longitude, address,
		 status, emergency_type, notified_driver_ids, medical_snapshot,
		 resolved_at, resolved_by, ended_at, created_at, updated_at
		 FROM emergencies WHERE id = $1`, id,
	).Scan(&e.ID, &e.UserID, &e.Type, &e.Description, &e.Latitude, &e.Longitude,
		&e.Address, &e.Status, &e.EmergencyType, &e.NotifiedDriverIDs,
		&e.MedicalSnapshot, &e.ResolvedAt, &e.ResolvedBy, &e.EndedAt,
		&e.CreatedAt, &e.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return e, nil
}

func (r *EmergencyRepository) GetActiveEmergency(userID uuid.UUID) (*models.Emergency, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	e := &models.Emergency{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, type, description, latitude, longitude, address,
		 status, emergency_type, notified_driver_ids, medical_snapshot,
		 resolved_at, resolved_by, ended_at, created_at, updated_at
		 FROM emergencies WHERE user_id = $1 AND status = 'active'
		 ORDER BY created_at DESC LIMIT 1`, userID,
	).Scan(&e.ID, &e.UserID, &e.Type, &e.Description, &e.Latitude, &e.Longitude,
		&e.Address, &e.Status, &e.EmergencyType, &e.NotifiedDriverIDs,
		&e.MedicalSnapshot, &e.ResolvedAt, &e.ResolvedBy, &e.EndedAt,
		&e.CreatedAt, &e.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return e, nil
}

func (r *EmergencyRepository) ResolveEmergency(id uuid.UUID, resolvedBy *uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	now := time.Now()
	_, err := r.pool.Exec(ctx,
		`UPDATE emergencies SET status = 'resolved', resolved_at = $2, resolved_by = $3, ended_at = $2, updated_at = NOW()
		 WHERE id = $1`,
		id, now, resolvedBy,
	)
	return err
}

func (r *EmergencyRepository) MarkFalseAlarm(id uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	now := time.Now()
	_, err := r.pool.Exec(ctx,
		`UPDATE emergencies SET status = 'false_alarm', ended_at = $2, updated_at = NOW() WHERE id = $1`,
		id, now,
	)
	return err
}

func (r *EmergencyRepository) ListEmergencies(userID uuid.UUID, limit, offset int) ([]models.EmergencyListItem, int, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if limit < 1 || limit > 100 {
		limit = 20
	}

	var total int
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM emergencies WHERE user_id = $1`,
		userID,
	).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	rows, err := r.pool.Query(ctx,
		`SELECT e.id, e.emergency_type, e.status, e.latitude, e.longitude, e.address,
			e.created_at, e.ended_at,
			(SELECT COUNT(*) FROM emergency_responders er WHERE er.emergency_id = e.id) as responder_count
		 FROM emergencies e
		 WHERE e.user_id = $1
		 ORDER BY e.created_at DESC LIMIT $2 OFFSET $3`,
		userID, limit, offset,
	)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var items []models.EmergencyListItem
	for rows.Next() {
		var item models.EmergencyListItem
		if err := rows.Scan(&item.ID, &item.EmergencyType, &item.Status,
			&item.Latitude, &item.Longitude, &item.Address,
			&item.CreatedAt, &item.EndedAt, &item.ResponderCount); err != nil {
			return nil, 0, err
		}

		// Calculate duration
		if item.EndedAt != nil {
			dur := item.EndedAt.Sub(item.CreatedAt)
			durStr := formatDuration(dur)
			item.Duration = &durStr
		}

		items = append(items, item)
	}
	if items == nil {
		items = []models.EmergencyListItem{}
	}
	return items, total, nil
}

// ==================== Responders ====================

func (r *EmergencyRepository) CreateResponder(resp *models.EmergencyResponder) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO emergency_responders (emergency_id, driver_id, response, responded_at)
		 VALUES ($1, $2, $3, $4)
		 ON CONFLICT (emergency_id, driver_id) DO UPDATE SET
			response = EXCLUDED.response, responded_at = EXCLUDED.responded_at
		 RETURNING id, created_at`,
		resp.EmergencyID, resp.DriverID, resp.Response, resp.RespondedAt,
	).Scan(&resp.ID, &resp.CreatedAt)
}

func (r *EmergencyRepository) UpdateResponderStatus(id uuid.UUID, response string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	now := time.Now()
	var err error
	if response == models.ResponderStatusArrived {
		_, err = r.pool.Exec(ctx,
			`UPDATE emergency_responders SET response = $2, arrived_at = $3 WHERE id = $1`,
			id, response, now,
		)
	} else {
		_, err = r.pool.Exec(ctx,
			`UPDATE emergency_responders SET response = $2, responded_at = $3 WHERE id = $1`,
			id, response, now,
		)
	}
	return err
}

func (r *EmergencyRepository) GetResponders(emergencyID uuid.UUID) ([]models.EmergencyResponder, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, emergency_id, driver_id, response, responded_at, arrived_at, notes, created_at
		 FROM emergency_responders WHERE emergency_id = $1 ORDER BY created_at ASC`,
		emergencyID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var responders []models.EmergencyResponder
	for rows.Next() {
		var r models.EmergencyResponder
		if err := rows.Scan(&r.ID, &r.EmergencyID, &r.DriverID, &r.Response,
			&r.RespondedAt, &r.ArrivedAt, &r.Notes, &r.CreatedAt); err != nil {
			return nil, err
		}
		responders = append(responders, r)
	}
	if responders == nil {
		responders = []models.EmergencyResponder{}
	}
	return responders, nil
}

func (r *EmergencyRepository) FindResponder(emergencyID, driverID uuid.UUID) (*models.EmergencyResponder, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	resp := &models.EmergencyResponder{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, emergency_id, driver_id, response, responded_at, arrived_at, notes, created_at
		 FROM emergency_responders WHERE emergency_id = $1 AND driver_id = $2`,
		emergencyID, driverID,
	).Scan(&resp.ID, &resp.EmergencyID, &resp.DriverID, &resp.Response,
		&resp.RespondedAt, &resp.ArrivedAt, &resp.Notes, &resp.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return resp, nil
}

// ==================== Feedback ====================

func (r *EmergencyRepository) CreateFeedback(f *models.EmergencyFeedback) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO emergency_feedback (emergency_id, driver_id, rating, comment)
		 VALUES ($1, $2, $3, $4)
		 RETURNING id, created_at`,
		f.EmergencyID, f.DriverID, f.Rating, f.Comment,
	).Scan(&f.ID, &f.CreatedAt)
}

func (r *EmergencyRepository) HasFeedback(emergencyID, driverID uuid.UUID) (bool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var exists bool
	err := r.pool.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM emergency_feedback WHERE emergency_id = $1 AND driver_id = $2)`,
		emergencyID, driverID,
	).Scan(&exists)
	return exists, err
}

// ==================== Driver Location ====================

func (r *EmergencyRepository) UpdateDriverLocation(driverID uuid.UUID, lat, lng float64) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`INSERT INTO driver_locations (driver_id, latitude, longitude, updated_at)
		 VALUES ($1, $2, $3, NOW())
		 ON CONFLICT (driver_id) DO UPDATE SET
			latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, updated_at = NOW()`,
		driverID, lat, lng,
	)
	return err
}

func (r *EmergencyRepository) FindNearbyDrivers(lat, lng, radiusKm float64, excludeUserID uuid.UUID, limit int) ([]models.NearbyDriver, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if limit < 1 || limit > 50 {
		limit = 10
	}

	// Haversine distance calculation in SQL using subquery
	rows, err := r.pool.Query(ctx,
		`SELECT driver_id, driver_name, phone, distance_km FROM (
			SELECT dl.driver_id, COALESCE(u.full_name, '') as driver_name, u.phone,
				(6371 * acos(cos(radians($1)) * cos(radians(dl.latitude)) *
				 cos(radians(dl.longitude) - radians($2)) +
				 sin(radians($1)) * sin(radians(dl.latitude)))) AS distance_km
			 FROM driver_locations dl
			 JOIN drivers d ON dl.driver_id = d.id
			 JOIN users u ON d.user_id = u.id
			 WHERE d.user_id != $3
			 AND dl.updated_at > NOW() - INTERVAL '1 hour'
		) sub
		 WHERE distance_km < $4
		 ORDER BY distance_km ASC
		 LIMIT $5`,
		lat, lng, excludeUserID, radiusKm, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var drivers []models.NearbyDriver
	for rows.Next() {
		var d models.NearbyDriver
		if err := rows.Scan(&d.DriverID, &d.DriverName, &d.Phone, &d.Distance); err != nil {
			return nil, err
		}
		drivers = append(drivers, d)
	}
	if drivers == nil {
		drivers = []models.NearbyDriver{}
	}
	return drivers, nil
}

// GetUserByDriverID returns the user_id for a given driver_id
func (r *EmergencyRepository) GetUserByDriverID(driverID uuid.UUID) (uuid.UUID, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var userID uuid.UUID
	err := r.pool.QueryRow(ctx,
		`SELECT user_id FROM drivers WHERE id = $1`,
		driverID,
	).Scan(&userID)
	return userID, err
}

// GetDriverIDByUserID returns the driver_id for a given user_id
func (r *EmergencyRepository) GetDriverIDByUserID(userID uuid.UUID) (uuid.UUID, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var driverID uuid.UUID
	err := r.pool.QueryRow(ctx,
		`SELECT id FROM drivers WHERE user_id = $1`,
		userID,
	).Scan(&driverID)
	return driverID, err
}

// GetDriverInfo returns driver name and phone by user_id
func (r *EmergencyRepository) GetDriverInfo(userID uuid.UUID) (string, string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var name, phone string
	err := r.pool.QueryRow(ctx,
		`SELECT COALESCE(u.full_name, ''), u.phone
		 FROM users u WHERE u.id = $1`,
		userID,
	).Scan(&name, &phone)
	return name, phone, err
}

// ==================== Helpers ====================

func formatDuration(d time.Duration) string {
	if d < time.Minute {
		return "< 1 menit"
	}
	if d < time.Hour {
		mins := int(d.Minutes())
		return fmt.Sprintf("%d menit", mins)
	}
	hours := int(d.Hours())
	mins := int(d.Minutes()) % 60
	if mins == 0 {
		return fmt.Sprintf("%d jam", hours)
	}
	return fmt.Sprintf("%d jam %d menit", hours, mins)
}
