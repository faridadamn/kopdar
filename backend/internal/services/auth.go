package services

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/models"
)

var (
	ErrInvalidOTP       = errors.New("invalid or expired OTP")
	ErrInvalidToken     = errors.New("invalid or expired token")
	ErrTokenRevoked     = errors.New("token has been revoked")
	ErrUserNotFound     = errors.New("user not found")
	ErrDriverNotFound   = errors.New("driver profile not found")
)

// Claims for JWT
type Claims struct {
	UserID uuid.UUID `json:"user_id"`
	Phone  string    `json:"phone"`
	Role   string    `json:"role"`
	jwt.RegisteredClaims
}

// UserRepository interface
type UserRepository interface {
	FindByPhone(phone string) (*models.User, error)
	Create(phone string) (*models.User, error)
	FindByID(id uuid.UUID) (*models.User, error)
	Update(user *models.User) error
}

// TokenRepository interface
type TokenRepository interface {
	SaveRefreshToken(userID uuid.UUID, tokenHash string, expiresAt time.Time) error
	FindRefreshToken(tokenHash string) (*models.RefreshToken, error)
	RevokeRefreshToken(tokenHash string) error
}

// AuthService handles authentication logic
type AuthService struct {
	userRepo  UserRepository
	tokenRepo TokenRepository
	otpSvc    *OTPService
	jwtSecret []byte
}

func NewAuthService(userRepo UserRepository, tokenRepo TokenRepository, otpSvc *OTPService, jwtSecret string) *AuthService {
	return &AuthService{
		userRepo:  userRepo,
		tokenRepo: tokenRepo,
		otpSvc:    otpSvc,
		jwtSecret: []byte(jwtSecret),
	}
}

func (s *AuthService) RequestOTP(phone string) (string, error) {
	code := s.otpSvc.Generate(phone)
	// In production, send via SMS gateway
	// For mock mode, return the code
	return code, nil
}

func (s *AuthService) VerifyOTP(phone, otp string) (*models.TokenResponse, error) {
	if !s.otpSvc.Verify(phone, otp) {
		return nil, ErrInvalidOTP
	}

	// Find or create user
	user, err := s.userRepo.FindByPhone(phone)
	if err != nil {
		// User doesn't exist, create one
		user, err = s.userRepo.Create(phone)
		if err != nil {
			return nil, err
		}
	}

	return s.generateTokenPair(user)
}

func (s *AuthService) Login(phone, otp string) (*models.TokenResponse, error) {
	return s.VerifyOTP(phone, otp)
}

func (s *AuthService) Refresh(refreshToken string) (*models.TokenResponse, error) {
	tokenHash := hashToken(refreshToken)

	stored, err := s.tokenRepo.FindRefreshToken(tokenHash)
	if err != nil {
		return nil, ErrInvalidToken
	}

	if stored.Revoked {
		return nil, ErrTokenRevoked
	}

	if time.Now().After(stored.ExpiresAt) {
		return nil, ErrInvalidToken
	}

	user, err := s.userRepo.FindByID(stored.UserID)
	if err != nil {
		return nil, ErrUserNotFound
	}

	// Revoke old refresh token
	_ = s.tokenRepo.RevokeRefreshToken(tokenHash)

	return s.generateTokenPair(user)
}

func (s *AuthService) Logout(refreshToken string) error {
	tokenHash := hashToken(refreshToken)
	return s.tokenRepo.RevokeRefreshToken(tokenHash)
}

func (s *AuthService) ValidateAccessToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		return s.jwtSecret, nil
	})
	if err != nil {
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, ErrInvalidToken
	}

	return claims, nil
}

func (s *AuthService) generateTokenPair(user *models.User) (*models.TokenResponse, error) {
	now := time.Now()

	// Access token: 15 minutes
	accessClaims := &Claims{
		UserID: user.ID,
		Phone:  user.Phone,
		Role:   user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(now),
			Subject:   user.ID.String(),
		},
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessTokenStr, err := accessToken.SignedString(s.jwtSecret)
	if err != nil {
		return nil, err
	}

	// Refresh token: 30 days
	refreshToken := uuid.New().String()
	refreshExpiry := now.Add(30 * 24 * time.Hour)
	tokenHash := hashToken(refreshToken)

	if err := s.tokenRepo.SaveRefreshToken(user.ID, tokenHash, refreshExpiry); err != nil {
		return nil, err
	}

	return &models.TokenResponse{
		AccessToken:  accessTokenStr,
		RefreshToken: refreshToken,
		ExpiresIn:    900, // 15 minutes in seconds
		TokenType:    "Bearer",
	}, nil
}

func hashToken(token string) string {
	h := sha256.Sum256([]byte(token))
	return hex.EncodeToString(h[:])
}
