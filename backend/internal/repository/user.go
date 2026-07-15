package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
)

type UserRepository struct {
	pool *pgxpool.Pool
}

func NewUserRepository(pool *pgxpool.Pool) *UserRepository {
	return &UserRepository{pool: pool}
}

func (r *UserRepository) FindByPhone(phone string) (*models.User, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	user := &models.User{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, phone, full_name, role, status, avatar_url, created_at, updated_at
		 FROM users WHERE phone = $1`, phone).Scan(
		&user.ID, &user.Phone, &user.FullName, &user.Role,
		&user.Status, &user.AvatarURL, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (r *UserRepository) Create(phone string) (*models.User, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	user := &models.User{}
	err := r.pool.QueryRow(ctx,
		`INSERT INTO users (phone, role) VALUES ($1, $2)
		 RETURNING id, phone, full_name, role, status, avatar_url, created_at, updated_at`,
		phone, models.RoleDriver).Scan(
		&user.ID, &user.Phone, &user.FullName, &user.Role,
		&user.Status, &user.AvatarURL, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (r *UserRepository) FindByID(id uuid.UUID) (*models.User, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	user := &models.User{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, phone, full_name, role, status, avatar_url, created_at, updated_at
		 FROM users WHERE id = $1`, id).Scan(
		&user.ID, &user.Phone, &user.FullName, &user.Role,
		&user.Status, &user.AvatarURL, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (r *UserRepository) Update(user *models.User) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE users SET full_name = $2, role = $3, status = $4, avatar_url = $5
		 WHERE id = $1`,
		user.ID, user.FullName, user.Role, user.Status, user.AvatarURL,
	)
	return err
}

// Token repository

type TokenRepository struct {
	pool *pgxpool.Pool
}

func NewTokenRepository(pool *pgxpool.Pool) *TokenRepository {
	return &TokenRepository{pool: pool}
}

func (r *TokenRepository) SaveRefreshToken(userID uuid.UUID, tokenHash string, expiresAt time.Time) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)`,
		userID, tokenHash, expiresAt,
	)
	return err
}

func (r *TokenRepository) FindRefreshToken(tokenHash string) (*models.RefreshToken, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	rt := &models.RefreshToken{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, token_hash, expires_at, revoked, created_at
		 FROM refresh_tokens WHERE token_hash = $1`, tokenHash).Scan(
		&rt.ID, &rt.UserID, &rt.TokenHash, &rt.ExpiresAt, &rt.Revoked, &rt.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return rt, nil
}

func (r *TokenRepository) RevokeRefreshToken(tokenHash string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE refresh_tokens SET revoked = TRUE WHERE token_hash = $1`, tokenHash)
	return err
}

// Find user by ID with pgx (used by admin handlers)
func (r *UserRepository) FindByIDWithPgx(id uuid.UUID) (*models.User, error) {
	return r.FindByID(id)
}

// Count users
func (r *UserRepository) CountUsers() (int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var count int64
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM users`).Scan(&count)
	return count, err
}

// Scan a user row from pgx.Row or pgx.Rows
func scanUser(row pgx.Row) (*models.User, error) {
	u := &models.User{}
	err := row.Scan(&u.ID, &u.Phone, &u.FullName, &u.Role, &u.Status, &u.AvatarURL, &u.CreatedAt, &u.UpdatedAt)
	return u, err
}
