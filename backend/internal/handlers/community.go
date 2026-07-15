package handlers

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/models"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/utils"
)

type CommunityHandler struct {
	commRepo   *repository.CommunityRepository
	driverRepo *repository.DriverRepository
}

func NewCommunityHandler(commRepo *repository.CommunityRepository, driverRepo *repository.DriverRepository) *CommunityHandler {
	return &CommunityHandler{
		commRepo:   commRepo,
		driverRepo: driverRepo,
	}
}

// POST /api/v1/community/posts
func (h *CommunityHandler) CreatePost(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	var req models.CommunityPostCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	// Default visibility
	visibility := req.Visibility
	if visibility == "" {
		visibility = models.VisibilityAll
	}

	// Set zone_id if visibility is zone
	var zoneID *uuid.UUID
	if visibility == models.VisibilityZone {
		// Use driver's city to find matching zone
		if driver.City != nil {
			zones, err := h.commRepo.GetZones()
			if err == nil {
				for _, z := range zones {
					if z.Name == *driver.City {
						zoneID = &z.ID
						break
					}
				}
			}
		}
	}

	post := &models.CommunityPost{
		UserID:     userID,
		Content:    req.Content,
		ImageURLs:  req.ImageURLs,
		Category:   req.Category,
		Visibility: visibility,
		ZoneID:     zoneID,
	}

	if err := h.commRepo.CreatePost(post); err != nil {
		utils.InternalError(c, "Gagal membuat postingan: "+err.Error())
		return
	}

	// Build response
	name, avatar, _ := h.commRepo.GetDriverNameAndAvatar(userID)
	resp := models.CommunityPostResponse{
		CommunityPost: *post,
		DriverName:    name,
		DriverAvatar:  avatar,
		IsLiked:       false,
	}

	utils.Created(c, "Postingan berhasil dibuat", resp)
}

// GET /api/v1/community/posts
func (h *CommunityHandler) ListPosts(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	// Parse pagination
	page := 1
	limit := 20
	if p := c.Query("page"); p != "" {
		fmt.Sscanf(p, "%d", &page)
	}
	if l := c.Query("limit"); l != "" {
		fmt.Sscanf(l, "%d", &limit)
	}
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	filter := c.DefaultQuery("filter", "all")
	category := c.Query("category")

	// For zone filter, find driver's zone
	var driverZoneID *uuid.UUID
	if filter == "zone" && driver.City != nil {
		zones, err := h.commRepo.GetZones()
		if err == nil {
			for _, z := range zones {
				if z.Name == *driver.City {
					driverZoneID = &z.ID
					break
				}
			}
		}
	}

	posts, total, err := h.commRepo.ListPosts(filter, category, &userID, driverZoneID, limit, offset)
	if err != nil {
		utils.InternalError(c, "Gagal mengambil daftar postingan")
		return
	}

	totalPages := total / limit
	if total%limit > 0 {
		totalPages++
	}

	utils.OK(c, "Daftar postingan berhasil diambil", models.CommunityPostListResponse{
		Posts:      posts,
		Page:       page,
		Limit:      limit,
		TotalCount: total,
		TotalPages: totalPages,
	})
}

// GET /api/v1/community/posts/:id
func (h *CommunityHandler) GetPost(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID postingan tidak valid")
		return
	}

	post, err := h.commRepo.FindPostByID(id)
	if err != nil {
		utils.NotFound(c, "Postingan tidak ditemukan")
		return
	}

	// Get driver info
	name, avatar, _ := h.commRepo.GetDriverNameAndAvatar(post.UserID)

	// Check if current user liked
	isLiked := false
	_, likeErr := h.commRepo.FindLike(post.ID, userID)
	if likeErr == nil {
		isLiked = true
	}

	// Get comments (nested)
	comments, err := h.commRepo.GetCommentsByPostID(post.ID)
	if err != nil {
		comments = []models.CommunityCommentTree{}
	}

	resp := models.CommunityPostDetailResponse{
		CommunityPostResponse: models.CommunityPostResponse{
			CommunityPost: *post,
			DriverName:    name,
			DriverAvatar:  avatar,
			IsLiked:       isLiked,
		},
		Comments: comments,
	}

	utils.OK(c, "Detail postingan berhasil diambil", resp)
}

// PUT /api/v1/community/posts/:id
func (h *CommunityHandler) UpdatePost(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID postingan tidak valid")
		return
	}

	post, err := h.commRepo.FindPostByID(id)
	if err != nil {
		utils.NotFound(c, "Postingan tidak ditemukan")
		return
	}

	// Only author can update
	if post.UserID != userID {
		utils.Forbidden(c, "Anda bukan pemilik postingan ini")
		return
	}

	// Only within 1 hour
	if time.Since(post.CreatedAt) > time.Hour {
		utils.BadRequest(c, "Postingan hanya bisa diubah dalam 1 jam setelah dibuat")
		return
	}

	var req models.CommunityPostUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	if req.Content != nil {
		post.Content = *req.Content
	}
	if req.Category != nil {
		post.Category = *req.Category
	}

	if err := h.commRepo.UpdatePost(post); err != nil {
		utils.InternalError(c, "Gagal mengupdate postingan")
		return
	}

	utils.OK(c, "Postingan berhasil diupdate", post)
}

// DELETE /api/v1/community/posts/:id
func (h *CommunityHandler) DeletePost(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID postingan tidak valid")
		return
	}

	post, err := h.commRepo.FindPostByID(id)
	if err != nil {
		utils.NotFound(c, "Postingan tidak ditemukan")
		return
	}

	// Check if author or admin
	if post.UserID != userID {
		isAdmin, _ := h.commRepo.IsAdmin(userID)
		if !isAdmin {
			utils.Forbidden(c, "Anda tidak memiliki akses untuk menghapus postingan ini")
			return
		}
	}

	if err := h.commRepo.SoftDeletePost(id); err != nil {
		utils.InternalError(c, "Gagal menghapus postingan")
		return
	}

	utils.OK(c, "Postingan berhasil dihapus", gin.H{
		"id":      id,
		"message": "Postingan berhasil dihapus",
	})
}

// POST /api/v1/community/posts/:id/like
func (h *CommunityHandler) ToggleLike(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	postID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID postingan tidak valid")
		return
	}

	// Check post exists
	_, err = h.commRepo.FindPostByID(postID)
	if err != nil {
		utils.NotFound(c, "Postingan tidak ditemukan")
		return
	}

	// Check if already liked
	existingLike, _ := h.commRepo.FindLike(postID, userID)

	if existingLike != nil {
		// Unlike
		if err := h.commRepo.DeleteLike(postID, userID); err != nil {
			utils.InternalError(c, "Gagal menghapus like")
			return
		}
		if err := h.commRepo.DecrementLikesCount(postID); err != nil {
			utils.InternalError(c, "Gagal mengupdate jumlah like")
			return
		}
		count, _ := h.commRepo.GetLikesCount(postID)
		utils.OK(c, "Like berhasil dihapus", models.CommunityToggleLikeResponse{
			Liked:      false,
			LikesCount: count,
		})
	} else {
		// Like
		if err := h.commRepo.CreateLike(postID, userID); err != nil {
			utils.InternalError(c, "Gagal menyimpan like")
			return
		}
		if err := h.commRepo.IncrementLikesCount(postID); err != nil {
			utils.InternalError(c, "Gagal mengupdate jumlah like")
			return
		}
		count, _ := h.commRepo.GetLikesCount(postID)
		utils.OK(c, "Postingan berhasil di-like", models.CommunityToggleLikeResponse{
			Liked:      true,
			LikesCount: count,
		})
	}
}

// POST /api/v1/community/posts/:id/comments
func (h *CommunityHandler) AddComment(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	postID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID postingan tidak valid")
		return
	}

	// Check post exists
	_, err = h.commRepo.FindPostByID(postID)
	if err != nil {
		utils.NotFound(c, "Postingan tidak ditemukan")
		return
	}

	var req models.CommunityCommentCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	// If replying, check parent comment exists and belongs to same post
	if req.ParentID != nil {
		parentComment, err := h.commRepo.FindCommentByID(*req.ParentID)
		if err != nil {
			utils.NotFound(c, "Komentar induk tidak ditemukan")
			return
		}
		if parentComment.PostID != postID {
			utils.BadRequest(c, "Komentar induk bukan dari postingan ini")
			return
		}
	}

	comment := &models.CommunityComment{
		PostID:   postID,
		UserID:   userID,
		ParentID: req.ParentID,
		Content:  req.Content,
	}

	if err := h.commRepo.CreateComment(comment); err != nil {
		utils.InternalError(c, "Gagal menyimpan komentar: "+err.Error())
		return
	}

	// Increment comments count
	if err := h.commRepo.IncrementCommentsCount(postID); err != nil {
		// Non-critical, log but don't fail
		_ = err
	}

	// Build response
	name, avatar, _ := h.commRepo.GetDriverNameAndAvatar(userID)
	resp := models.CommunityCommentResponse{
		CommunityComment: *comment,
		DriverName:       name,
		DriverAvatar:     avatar,
	}

	utils.Created(c, "Komentar berhasil ditambahkan", resp)
}

// PUT /api/v1/community/comments/:id
func (h *CommunityHandler) UpdateComment(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID komentar tidak valid")
		return
	}

	comment, err := h.commRepo.FindCommentByID(id)
	if err != nil {
		utils.NotFound(c, "Komentar tidak ditemukan")
		return
	}

	// Only author can update
	if comment.UserID != userID {
		utils.Forbidden(c, "Anda bukan pemilik komentar ini")
		return
	}

	// Only within 30 minutes
	if time.Since(comment.CreatedAt) > 30*time.Minute {
		utils.BadRequest(c, "Komentar hanya bisa diubah dalam 30 menit setelah dibuat")
		return
	}

	var req models.CommunityCommentUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	comment.Content = req.Content
	if err := h.commRepo.UpdateComment(comment); err != nil {
		utils.InternalError(c, "Gagal mengupdate komentar")
		return
	}

	utils.OK(c, "Komentar berhasil diupdate", comment)
}

// DELETE /api/v1/community/comments/:id
func (h *CommunityHandler) DeleteComment(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID komentar tidak valid")
		return
	}

	comment, err := h.commRepo.FindCommentByID(id)
	if err != nil {
		utils.NotFound(c, "Komentar tidak ditemukan")
		return
	}

	// Only author can delete
	if comment.UserID != userID {
		utils.Forbidden(c, "Anda bukan pemilik komentar ini")
		return
	}

	if err := h.commRepo.SoftDeleteComment(id); err != nil {
		utils.InternalError(c, "Gagal menghapus komentar")
		return
	}

	// Decrement comments count
	if err := h.commRepo.DecrementCommentsCount(comment.PostID); err != nil {
		_ = err
	}

	utils.OK(c, "Komentar berhasil dihapus", gin.H{
		"id":      id,
		"message": "Komentar berhasil dihapus",
	})
}

// POST /api/v1/community/posts/:id/report
func (h *CommunityHandler) ReportPost(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	idStr := c.Param("id")
	postID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequest(c, "ID postingan tidak valid")
		return
	}

	// Check post exists
	_, err = h.commRepo.FindPostByID(postID)
	if err != nil {
		utils.NotFound(c, "Postingan tidak ditemukan")
		return
	}

	var req models.CommunityReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Data tidak valid: "+err.Error())
		return
	}

	report := &models.CommunityReport{
		PostID:     &postID,
		ReporterID: userID,
		Reason:     req.Reason,
	}

	if err := h.commRepo.CreateReport(report); err != nil {
		utils.InternalError(c, "Gagal mengirim laporan: "+err.Error())
		return
	}

	utils.Created(c, "Laporan berhasil dikirim", gin.H{
		"id":      report.ID,
		"message": "Laporan Anda akan kami tinjau. Terima kasih.",
	})
}

// GET /api/v1/community/zone
func (h *CommunityHandler) ZoneInfo(c *gin.Context) {
	userID := c.MustGet(middleware.ContextUserID).(uuid.UUID)

	driver, err := h.driverRepo.FindByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Profil driver tidak ditemukan")
		return
	}

	// Find driver's zone by city
	var zoneName string
	var totalMembers, activeToday int

	if driver.City != nil {
		zones, err := h.commRepo.GetZones()
		if err == nil {
			for _, z := range zones {
				if z.Name == *driver.City {
					zoneName, totalMembers, activeToday, _ = h.commRepo.GetZoneInfo(z.ID)
					break
				}
			}
		}
	}

	if zoneName == "" {
		zoneName = "Tidak diketahui"
	}

	// Default tips and events (could be enhanced with real data later)
	tips := []string{
		fmt.Sprintf("Zona %s ramai di jam 7-9 pagi", zoneName),
		"Hindari jalan utama saat jam pulang kantor",
		"Cek aplikasi sebelum mulai narik untuk lihat order rate",
	}
	events := []string{
		fmt.Sprintf("Kopdar offline minggu ini di zona %s", zoneName),
		"Webinar manajemen keuangan driver — daftar di menu Pelatihan",
	}

	utils.OK(c, "Info zona berhasil diambil", models.CommunityZoneInfo{
		ZoneName:     zoneName,
		TotalMembers: totalMembers,
		ActiveToday:  activeToday,
		Tips:         tips,
		Events:       events,
	})
}

// GET /api/v1/community/advocacy
func (h *CommunityHandler) AdvocacyData(c *gin.Context) {
	// Return seed/mock data for now
	now := time.Now()

	stats := models.AdvocacyStats{
		TotalMembers:     2340,
		AvgProfit:        2100000,
		AvgHours:         10.5,
		PinjolPercentage: 65,
	}

	petitions := []models.AdvocacyItem{
		{
			ID:        uuid.New(),
			Title:     "Tuntutan Tarif Minimum Per KM",
			Content:   "Kami mendesak platform ride-hailing untuk menerapkan tarif minimum Rp 2.500 per km agar penghasilan driver layak.",
			Status:    "active",
			CreatedAt: now.AddDate(0, 0, -7),
		},
		{
			ID:        uuid.New(),
			Title:     "Perlindungan Asuransi dari Platform",
			Content:   "Meminta setiap platform menyediakan asuransi kecelakaan kerja gratis untuk semua driver aktif.",
			Status:    "active",
			CreatedAt: now.AddDate(0, -1, 0),
		},
	}

	updates := []models.AdvocacyItem{
		{
			ID:        uuid.New(),
			Title:     "Hasil Negosiasi Tarif Q2 2026",
			Content:   "Alhamdulillah, tarif per km naik 8% berdasarkan negosiasi bersama. Berlaku mulai Juli 2026.",
			Status:    "completed",
			CreatedAt: now.AddDate(0, 0, -3),
		},
		{
			ID:        uuid.New(),
			Title:     "Program Subsidi Bensin Driver Aktif",
			Content:   "KopDar bekerja sama dengan Pertamina untuk memberikan diskon Rp 500/liter bagi driver dengan rating > 4.5.",
			Status:    "active",
			CreatedAt: now.AddDate(0, 0, -14),
		},
	}

	polls := []models.AdvocacyPoll{
		{
			ID:       uuid.New(),
			Question: "Apakah Anda setuju dengan usulan tarif minimum Rp 2.500/km?",
			Options: []models.AdvocacyPollOption{
				{Label: "Setuju", Votes: 1820},
				{Label: "Tidak Setuju", Votes: 230},
				{Label: "Perlu Kajian Lagi", Votes: 290},
			},
			TotalVotes: 2340,
			EndsAt:     now.AddDate(0, 0, 7),
		},
		{
			ID:       uuid.New(),
			Question: "Prioritas utama KopDar untuk kuartal depan?",
			Options: []models.AdvocacyPollOption{
				{Label: "Kenaikan Tarif", Votes: 980},
				{Label: "Asuransi Kecelakaan", Votes: 760},
				{Label: "Subsidi Bensin", Votes: 600},
			},
			TotalVotes: 2340,
			EndsAt:     now.AddDate(0, 0, 14),
		},
	}

	utils.OK(c, "Data advokasi berhasil diambil", models.CommunityAdvocacyResponse{
		CollectiveStats: stats,
		Petitions:       petitions,
		Updates:         updates,
		Polls:           polls,
	})
}
