package services

import (
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"sync"
	"time"
)

var (
	ErrOTPTooSoon = errors.New("OTP requested too soon")
	ErrOTPLocked  = errors.New("OTP verification temporarily locked")
)

const (
	otpTTL          = 5 * time.Minute
	otpResendWindow = 60 * time.Second
	otpLockDuration = 15 * time.Minute
	maxOTPAttempts  = 3
)

type OTPService struct {
	mockMode bool
	store    map[string]otpEntry
	mu       sync.Mutex
}

type otpEntry struct {
	Code        string
	ExpiresAt   time.Time
	LastSentAt  time.Time
	Attempts    int
	LockedUntil time.Time
}

func NewOTPService(mockMode bool) *OTPService {
	s := &OTPService{
		mockMode: mockMode,
		store:    make(map[string]otpEntry),
	}
	go s.cleanup()
	return s
}

func (s *OTPService) Generate(phone string) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := time.Now()
	if existing, ok := s.store[phone]; ok {
		if now.Before(existing.LockedUntil) {
			return "", ErrOTPLocked
		}
		if now.Sub(existing.LastSentAt) < otpResendWindow {
			return "", ErrOTPTooSoon
		}
	}

	code, err := s.generateCode()
	if err != nil {
		return "", err
	}

	s.store[phone] = otpEntry{
		Code:       code,
		ExpiresAt:  now.Add(otpTTL),
		LastSentAt: now,
	}
	return code, nil
}

func (s *OTPService) Verify(phone, code string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := time.Now()
	entry, exists := s.store[phone]
	if !exists || now.After(entry.ExpiresAt) {
		delete(s.store, phone)
		return false
	}

	if now.Before(entry.LockedUntil) {
		return false
	}

	if entry.Code != code {
		entry.Attempts++
		if entry.Attempts >= maxOTPAttempts {
			entry.LockedUntil = now.Add(otpLockDuration)
			entry.Attempts = 0
		}
		s.store[phone] = entry
		return false
	}

	delete(s.store, phone)
	return true
}

func (s *OTPService) IsMockMode() bool {
	return s.mockMode
}

func (s *OTPService) generateCode() (string, error) {
	if s.mockMode {
		return "123456", nil
	}

	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", fmt.Errorf("generate OTP: %w", err)
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

func (s *OTPService) cleanup() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		s.mu.Lock()
		now := time.Now()
		for phone, entry := range s.store {
			if now.After(entry.ExpiresAt) && now.After(entry.LockedUntil) {
				delete(s.store, phone)
			}
		}
		s.mu.Unlock()
	}
}
