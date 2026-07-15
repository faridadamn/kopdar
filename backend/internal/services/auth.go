package services

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/models"
)

const jwtIssuer = "kopdar-api"

var (
	ErrInvalidOTP     = errors.New("invalid or expired OTP")
	ErrInvalidToken   = errors.New("invalid or expired token")
	ErrTokenRevoked   = errors.New("token has been revoked")
	ErrUserNotFound   = errors.New("user not found")
	ErrDriverNotFound = errors.New("driver profile not found")
)

type Claims struct {
	UserID uuid.UUID `json:"user_id"`
	Phone  string    `json:"phone"`
	Role   string    `json:"role"`
	jwt.RegisteredClaims
}

type UserRepository interface {
	FindByPhone(phone string) (*models.User, error)
	Create(phone string) (*models.User, error)
	FindByID(id uuid.UUID) (*models.User, error)
	Update(user *models.User) error
}

type TokenRepository interface {
	SaveRefreshToken(userID uuid.UUID, tokenHash string, expiresAt time.Time) error
	FindRefreshToken(tokenHash string) (*models.RefreshToken, error)
	RevokeRefreshToken(tokenHash string) error
}

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
	code, err := s.otpSvc.Generate(phone)
	if err != nil {
		return "", err
	}
	// TODO: send code through the configured SMS provider in non-mock mode.
	return code, nil
}

func (s *AuthService) VerifyOTP(phone, otp string) (*models.TokenResponse, error) {
	if !s.otpSvc.Verify(phone, otp) {
		return nil, ErrInvalidOTP
	}

	user, err := s.userRepo.FindByPhone(phone)
	if err != nil {
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

	if err := s.tokenRepo.RevokeRefreshToken(tokenHash); err != nil {
		return nil, fmt.Errorf("revoke refresh token: %w", err)
	}
	return s.generateTokenPair(user)
}

func (s *AuthService) Logout(refreshToken string) error {
	return s.tokenRepo.RevokeRefreshToken(hashToken(refreshToken))
}

func (s *AuthService) ValidateAccessToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(
		tokenString,
		&Claims{},
		func(t *jwt.Token) (interface{}, error) {
			if t.Method != jwt.SigningMethodHS256 {
				return nil, fmt.Errorf("unexpected JWT signing method: %s", t.Method.Alg())
			}
			return s.jwtSecret, nil
		},
		jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}),
		jwt.WithIssuer(jwtIssuer),
	)
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
	accessClaims := &Claims{
		UserID: user.ID,
		Phone:  user.Phone,
		Role:   user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    jwtIssuer,
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			Subject:   user.ID.String(),
		},
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessTokenStr, err := accessToken.SignedString(s.jwtSecret)
	if err != nil {
		return nil, err
	}

	refreshToken := uuid.New().String()
	refreshExpiry := now.Add(30 * 24 * time.Hour)
	if err := s.tokenRepo.SaveRefreshToken(user.ID, hashToken(refreshToken), refreshExpiry); err != nil {
		return nil, err
	}

	return &models.TokenResponse{
		AccessToken:  accessTokenStr,
		RefreshToken: refreshToken,
		ExpiresIn:    900,
		TokenType:    "Bearer",
	}, nil
}

func hashToken(token string) string {
	h := sha256.Sum256([]byte(token))
	return hex.EncodeToString(h[:])
}
