package services

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

// OTPService handles OTP generation and verification
type OTPService struct {
	mockMode bool
	store    map[string]otpEntry
	mu       sync.RWMutex
}

type otpEntry struct {
	Code      string
	ExpiresAt time.Time
}

func NewOTPService(mockMode bool) *OTPService {
	s := &OTPService{
		mockMode: mockMode,
		store:    make(map[string]otpEntry),
	}
	// Cleanup expired entries every 5 minutes
	go s.cleanup()
	return s
}

func (s *OTPService) Generate(phone string) string {
	s.mu.Lock()
	defer s.mu.Unlock()

	code := s.generateCode()
	s.store[phone] = otpEntry{
		Code:      code,
		ExpiresAt: time.Now().Add(5 * time.Minute),
	}
	return code
}

func (s *OTPService) Verify(phone, code string) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()

	entry, exists := s.store[phone]
	if !exists {
		return false
	}

	if time.Now().After(entry.ExpiresAt) {
		delete(s.store, phone)
		return false
	}

	if entry.Code != code {
		return false
	}

	// Valid — delete so it can't be reused
	delete(s.store, phone)
	return true
}

func (s *OTPService) IsMockMode() bool {
	return s.mockMode
}

func (s *OTPService) generateCode() string {
	if s.mockMode {
		return "123456"
	}
	return fmt.Sprintf("%06d", rand.Intn(1000000))
}

func (s *OTPService) cleanup() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		s.mu.Lock()
		now := time.Now()
		for phone, entry := range s.store {
			if now.After(entry.ExpiresAt) {
				delete(s.store, phone)
			}
		}
		s.mu.Unlock()
	}
}
