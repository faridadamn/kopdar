package services

import (
	"context"
	"fmt"
	"log"
	"math"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
)

// AutoSaveService handles automatic daily savings deposits
type AutoSaveService struct {
	pool       *pgxpool.Pool
	savingRepo *repository.SavingRepository
}

// NewAutoSaveService creates a new AutoSaveService
func NewAutoSaveService(pool *pgxpool.Pool, savingRepo *repository.SavingRepository) *AutoSaveService {
	return &AutoSaveService{
		pool:       pool,
		savingRepo: savingRepo,
	}
}

// RunDailyAutoSave processes all active savings goals with auto_save enabled.
// This should be called by a cron/scheduler once per day.
//
// For each active auto-save goal:
// 1. Check if goal has not already reached target
// 2. Calculate daily deposit amount (min of daily_amount and remaining to target)
// 3. Create a savings_transaction(type=deposit, method=auto)
// 4. Update current_amount
// 5. Mark as 'reached' if target is met
func (s *AutoSaveService) RunDailyAutoSave(ctx context.Context) error {
	savings, err := s.savingRepo.GetAutoSaveSavings()
	if err != nil {
		log.Printf("[AutoSave] Gagal mengambil daftar tabungan auto: %v", err)
		return err
	}

	if len(savings) == 0 {
		log.Println("[AutoSave] Tidak ada tabungan auto-save aktif")
		return nil
	}

	log.Printf("[AutoSave] Memproses %d tabungan auto-save", len(savings))

	for _, sv := range savings {
		if err := s.processAutoSave(ctx, sv); err != nil {
			log.Printf("[AutoSave] Gagal memproses tabungan %s (driver %s): %v",
				sv.GoalName, sv.DriverID, err)
			continue // Don't fail the whole batch for one error
		}
	}

	log.Println("[AutoSave] Selesai memproses auto-save")
	return nil
}

func (s *AutoSaveService) processAutoSave(ctx context.Context, sv models.Savings) error {
	// Skip if already reached target
	if sv.CurrentAmount >= sv.TargetAmount {
		log.Printf("[AutoSave] Tabungan '%s' sudah mencapai target, skip", sv.GoalName)
		return nil
	}

	// Calculate deposit amount: min of daily_amount and remaining to target
	remaining := sv.TargetAmount - sv.CurrentAmount
	depositAmount := sv.DailyAmount
	if depositAmount > remaining {
		depositAmount = remaining
	}

	// In a real system, we would check driver's balance here.
	// For now, we assume sufficient balance (simplified).
	// TODO: Integrate with driver balance/wallet system
	hasSufficientBalance := true

	if !hasSufficientBalance {
		log.Printf("[AutoSave] Saldo tidak cukup untuk driver %s, skip tabungan '%s'",
			sv.DriverID, sv.GoalName)
		// TODO: Create notification for insufficient balance
		return nil
	}

	// Create deposit transaction
	notes := "Setoran otomatis harian"
	txn := &models.SavingsTransaction{
		SavingsID: sv.ID,
		Type:      models.SavingsTxnTypeDeposit,
		Amount:    depositAmount,
		Method:    models.SavingsTxnMethodAuto,
		Status:    "completed",
		Notes:     &notes,
	}

	if err := s.savingRepo.CreateTransaction(txn); err != nil {
		return err
	}

	// Update current amount
	newAmount := sv.CurrentAmount + depositAmount
	if err := s.savingRepo.UpdateAmount(sv.ID, newAmount); err != nil {
		return err
	}

	// Check if goal reached
	if newAmount >= sv.TargetAmount {
		sv.CurrentAmount = newAmount
		sv.Status = models.SavingsStatusReached
		if err := s.savingRepo.Update(&sv); err != nil {
			log.Printf("[AutoSave] Gagal update status tabungan '%s' ke reached: %v", sv.GoalName, err)
		}
		log.Printf("[AutoSave] Tabungan '%s' telah mencapai target! 🎉", sv.GoalName)
		// TODO: Create celebration notification
	} else {
		log.Printf("[AutoSave] Setoran Rp %.0f untuk '%s' (total: Rp %.0f / Rp %.0f)",
			depositAmount, sv.GoalName, newAmount, sv.TargetAmount)
	}

	return nil
}

// CalculateEstimatedDays returns the number of days to reach the target
func CalculateEstimatedDays(current, target, dailyAmount float64) int {
	if dailyAmount <= 0 {
		return 0
	}
	remaining := target - current
	if remaining <= 0 {
		return 0
	}
	return int(math.Ceil(remaining / dailyAmount))
}

// FormatEstimatedTime returns a human-readable estimated time string
func FormatEstimatedTime(days int) string {
	if days <= 0 {
		return "Target tercapai"
	}
	if days <= 30 {
		return "~1 bulan lagi"
	}
	months := days / 30
	if months < 12 {
		return fmt.Sprintf("~%d bulan lagi", months)
	}
	years := months / 12
	remainingMonths := months % 12
	if remainingMonths == 0 {
		return fmt.Sprintf("~%d tahun lagi", years)
	}
	return fmt.Sprintf("~%d tahun %d bulan lagi", years, remainingMonths)
}
