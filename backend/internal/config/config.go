package config

import (
	"fmt"
	"os"
	"strings"
)

type Config struct {
	AppEnv      string
	Port        string
	DatabaseURL string
	JWTSecret   string
	OTPMode     string // "true" only for local development/test
	UploadDir   string
}

func Load() (*Config, error) {
	cfg := &Config{
		AppEnv:      strings.ToLower(getEnv("APP_ENV", "development")),
		Port:        getEnv("PORT", "8080"),
		DatabaseURL: getEnv("DATABASE_URL", "postgres://kopdar:kopdar@localhost:5432/kopdar?sslmode=disable"),
		JWTSecret:   os.Getenv("JWT_SECRET"),
		OTPMode:     strings.ToLower(getEnv("OTP_MOCK_MODE", "false")),
		UploadDir:   getEnv("UPLOAD_DIR", "./uploads"),
	}

	if len(cfg.JWTSecret) < 32 {
		return nil, fmt.Errorf("JWT_SECRET must be configured with at least 32 characters")
	}

	if cfg.AppEnv == "production" {
		if cfg.OTPMode == "true" {
			return nil, fmt.Errorf("OTP_MOCK_MODE must be false in production")
		}
		if strings.Contains(cfg.DatabaseURL, "sslmode=disable") {
			return nil, fmt.Errorf("DATABASE_URL must use TLS in production")
		}
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
