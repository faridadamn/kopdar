package services

import (
	"log"

	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
)

// PointsService handles point operations and level management
type PointsService struct {
	profileRepo *repository.ProfileRepository
}

// NewPointsService creates a new PointsService
func NewPointsService(profileRepo *repository.ProfileRepository) *PointsService {
	return &PointsService{
		profileRepo: profileRepo,
	}
}

// AddPoints adds points for a driver action and checks for level up
func (s *PointsService) AddPoints(driverID uuid.UUID, action string) (*models.AddPointsResponse, error) {
	pointsToAdd, ok := models.PointValues[action]
	if !ok {
		return &models.AddPointsResponse{
			PointsAdded: 0,
			NewTotal:    0,
			NewLevel:    models.LevelBronze,
			LevelUp:     false,
		}, nil
	}

	// Get current points
	dp, err := s.profileRepo.GetOrCreatePoints(driverID)
	if err != nil {
		return nil, err
	}

	oldLevel := dp.Level
	newTotal := dp.Points + pointsToAdd
	newLevel := s.calculateLevel(newTotal)
	levelUp := newLevel != oldLevel

	// Update points and level
	if err := s.profileRepo.UpdatePoints(driverID, newTotal, newLevel); err != nil {
		return nil, err
	}

	// Log history
	if err := s.profileRepo.AddPointsHistory(driverID, action, pointsToAdd); err != nil {
		log.Printf("[Points] Gagal menyimpan history points: %v", err)
	}

	// Log level up
	if levelUp {
		log.Printf("[Points] 🎉 Driver %s naik level dari %s ke %s! (%d points)",
			driverID, oldLevel, newLevel, newTotal)
	}

	return &models.AddPointsResponse{
		PointsAdded: pointsToAdd,
		NewTotal:    newTotal,
		NewLevel:    newLevel,
		LevelUp:     levelUp,
	}, nil
}

// calculateLevel determines the level based on total points
func (s *PointsService) calculateLevel(points int) string {
	if points >= models.LevelThresholds[models.LevelPlatinum] {
		return models.LevelPlatinum
	}
	if points >= models.LevelThresholds[models.LevelGold] {
		return models.LevelGold
	}
	if points >= models.LevelThresholds[models.LevelSilver] {
		return models.LevelSilver
	}
	return models.LevelBronze
}

// GetNextLevel returns the next level and points needed
func (s *PointsService) GetNextLevel(currentLevel string, currentPoints int) (string, int) {
	for i, level := range models.LevelOrder {
		if level == currentLevel && i < len(models.LevelOrder)-1 {
			next := models.LevelOrder[i+1]
			needed := models.LevelThresholds[next] - currentPoints
			if needed < 0 {
				needed = 0
			}
			return next, needed
		}
	}
	return currentLevel, 0
}
