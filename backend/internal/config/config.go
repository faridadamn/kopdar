package config

import (
	"os"
)

type Config struct {
	Port        string
	DatabaseURL string
	JWTSecret   string
	OTPMode     string // "true" for mock mode
	UploadDir   string
}

func Load() *Config {
	return &Config{
		Port:        getEnv("PORT", "8080"),
		DatabaseURL: getEnv("DATABASE_URL", "postgres://kopdar:kopdar@localhost:5432/kopdar?sslmode=disable"),
		JWTSecret:   getEnv("JWT_SECRET", "default-secret-change-me"),
		OTPMode:     getEnv("OTP_MOCK_MODE", "true"),
		UploadDir:   getEnv("UPLOAD_DIR", "./uploads"),
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
