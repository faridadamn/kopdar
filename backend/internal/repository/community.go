package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/models"
)

type CommunityRepository struct {
	pool *pgxpool.Pool
}

func NewCommunityRepository(pool *pgxpool.Pool) *CommunityRepository {
	return &CommunityRepository{pool: pool}
}

// ==================== Posts ====================

func (r *CommunityRepository) CreatePost(p *models.CommunityPost) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO community_posts (
			user_id, content, image_urls, category, visibility, zone_id
		) VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, likes_count, comments_count, is_pinned, created_at, updated_at`,
		p.UserID, p.Content, p.ImageURLs, p.Category, p.Visibility, p.ZoneID,
	).Scan(&p.ID, &p.LikesCount, &p.CommentsCount, &p.IsPinned, &p.CreatedAt, &p.UpdatedAt)
}

func (r *CommunityRepository) FindPostByID(id uuid.UUID) (*models.CommunityPost, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	p := &models.CommunityPost{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, content, image_urls, category, visibility, zone_id,
		 likes_count, comments_count, is_pinned, is_deleted, created_at, updated_at
		 FROM community_posts WHERE id = $1 AND is_deleted = FALSE`, id,
	).Scan(&p.ID, &p.UserID, &p.Content, &p.ImageURLs, &p.Category, &p.Visibility,
		&p.ZoneID, &p.LikesCount, &p.CommentsCount, &p.IsPinned, &p.IsDeleted,
		&p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (r *CommunityRepository) ListPosts(filter, category string, driverID *uuid.UUID, driverZoneID *uuid.UUID, limit, offset int) ([]models.CommunityPostResponse, int, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if limit < 1 || limit > 100 {
		limit = 20
	}

	baseQuery := `FROM community_posts p
		JOIN users u ON p.user_id = u.id
		WHERE p.is_deleted = FALSE`
	args := []interface{}{}
	argIdx := 1

	// Apply filters
	switch filter {
	case "zone":
		if driverZoneID != nil {
			baseQuery += ` AND p.zone_id = $` + itoa(argIdx)
			args = append(args, *driverZoneID)
			argIdx++
		}
	case "advocacy":
		baseQuery += ` AND p.category = 'advocacy'`
	}

	if category != "" {
		baseQuery += ` AND p.category = $` + itoa(argIdx)
		args = append(args, category)
		argIdx++
	}

	// Count total
	var total int
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) `+baseQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Fetch posts with driver info
	selectQuery := `SELECT p.id, p.user_id, p.content, p.image_urls, p.category, p.visibility,
		p.zone_id, p.likes_count, p.comments_count, p.is_pinned, p.created_at, p.updated_at,
		COALESCE(u.full_name, ''), u.avatar_url`

	// If driverID provided, check if each post is liked
	if driverID != nil {
		selectQuery += `,
			EXISTS(SELECT 1 FROM community_likes cl WHERE cl.post_id = p.id AND cl.user_id = $` + itoa(argIdx) + `) as is_liked`
		args = append(args, *driverID)
		argIdx++
	}

	query := selectQuery + ` ` + baseQuery + ` ORDER BY p.is_pinned DESC, p.created_at DESC LIMIT $` + itoa(argIdx) + ` OFFSET $` + itoa(argIdx+1)
	args = append(args, limit, offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var posts []models.CommunityPostResponse
	for rows.Next() {
		var pr models.CommunityPostResponse
		var imageURLs []string

		if driverID != nil {
			if err := rows.Scan(
				&pr.ID, &pr.UserID, &pr.Content, &imageURLs, &pr.Category, &pr.Visibility,
				&pr.ZoneID, &pr.LikesCount, &pr.CommentsCount, &pr.IsPinned,
				&pr.CreatedAt, &pr.UpdatedAt,
				&pr.DriverName, &pr.DriverAvatar, &pr.IsLiked,
			); err != nil {
				return nil, 0, err
			}
		} else {
			if err := rows.Scan(
				&pr.ID, &pr.UserID, &pr.Content, &imageURLs, &pr.Category, &pr.Visibility,
				&pr.ZoneID, &pr.LikesCount, &pr.CommentsCount, &pr.IsPinned,
				&pr.CreatedAt, &pr.UpdatedAt,
				&pr.DriverName, &pr.DriverAvatar,
			); err != nil {
				return nil, 0, err
			}
		}

		pr.ImageURLs = imageURLs
		posts = append(posts, pr)
	}

	if posts == nil {
		posts = []models.CommunityPostResponse{}
	}

	return posts, total, nil
}

func (r *CommunityRepository) UpdatePost(p *models.CommunityPost) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE community_posts SET content=$2, category=$3, updated_at=NOW() WHERE id=$1`,
		p.ID, p.Content, p.Category,
	)
	return err
}

func (r *CommunityRepository) SoftDeletePost(id uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE community_posts SET is_deleted=TRUE, updated_at=NOW() WHERE id=$1`,
		id,
	)
	return err
}

// ==================== Comments ====================

func (r *CommunityRepository) CreateComment(c *models.CommunityComment) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO community_comments (post_id, user_id, parent_id, content)
		 VALUES ($1, $2, $3, $4)
		 RETURNING id, created_at`,
		c.PostID, c.UserID, c.ParentID, c.Content,
	).Scan(&c.ID, &c.CreatedAt)
}

func (r *CommunityRepository) FindCommentByID(id uuid.UUID) (*models.CommunityComment, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	c := &models.CommunityComment{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, post_id, user_id, parent_id, content, is_deleted, created_at
		 FROM community_comments WHERE id = $1 AND is_deleted = FALSE`, id,
	).Scan(&c.ID, &c.PostID, &c.UserID, &c.ParentID, &c.Content, &c.IsDeleted, &c.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return c, nil
}

func (r *CommunityRepository) GetCommentsByPostID(postID uuid.UUID) ([]models.CommunityCommentTree, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT c.id, c.post_id, c.user_id, c.parent_id, c.content, c.created_at,
			COALESCE(u.full_name, ''), u.avatar_url
		 FROM community_comments c
		 JOIN users u ON c.user_id = u.id
		 WHERE c.post_id = $1 AND c.is_deleted = FALSE
		 ORDER BY c.created_at ASC`,
		postID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Collect all comments
	type commentWithInfo struct {
		models.CommunityCommentResponse
		parentID *uuid.UUID
	}

	var allComments []commentWithInfo
	for rows.Next() {
		var ci commentWithInfo
		if err := rows.Scan(
			&ci.ID, &ci.PostID, &ci.UserID, &ci.ParentID, &ci.Content, &ci.CreatedAt,
			&ci.DriverName, &ci.DriverAvatar,
		); err != nil {
			return nil, err
		}
		allComments = append(allComments, ci)
	}

	// Build tree: 1 level nesting (parent_id nil = top-level, else = reply)
	replyMap := make(map[uuid.UUID][]models.CommunityCommentResponse)
	var topLevel []models.CommunityCommentResponse

	for _, ci := range allComments {
		if ci.ParentID == nil {
			topLevel = append(topLevel, ci.CommunityCommentResponse)
		} else {
			replyMap[*ci.ParentID] = append(replyMap[*ci.ParentID], ci.CommunityCommentResponse)
		}
	}

	var trees []models.CommunityCommentTree
	for _, parent := range topLevel {
		tree := models.CommunityCommentTree{
			CommunityCommentResponse: parent,
			Replies:                  replyMap[parent.ID],
		}
		if tree.Replies == nil {
			tree.Replies = []models.CommunityCommentResponse{}
		}
		trees = append(trees, tree)
	}

	if trees == nil {
		trees = []models.CommunityCommentTree{}
	}

	return trees, nil
}

func (r *CommunityRepository) UpdateComment(c *models.CommunityComment) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE community_comments SET content=$2 WHERE id=$1`,
		c.ID, c.Content,
	)
	return err
}

func (r *CommunityRepository) SoftDeleteComment(id uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE community_comments SET is_deleted=TRUE WHERE id=$1`,
		id,
	)
	return err
}

// ==================== Likes ====================

func (r *CommunityRepository) FindLike(postID, userID uuid.UUID) (*models.CommunityLike, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	l := &models.CommunityLike{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, post_id, user_id, created_at
		 FROM community_likes WHERE post_id = $1 AND user_id = $2`,
		postID, userID,
	).Scan(&l.ID, &l.PostID, &l.UserID, &l.CreatedAt)
	if err != nil {
		return nil, err
	}
	return l, nil
}

func (r *CommunityRepository) CreateLike(postID, userID uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`INSERT INTO community_likes (post_id, user_id) VALUES ($1, $2)`,
		postID, userID,
	)
	return err
}

func (r *CommunityRepository) DeleteLike(postID, userID uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`DELETE FROM community_likes WHERE post_id = $1 AND user_id = $2`,
		postID, userID,
	)
	return err
}

func (r *CommunityRepository) IncrementLikesCount(postID uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE community_posts SET likes_count = likes_count + 1 WHERE id = $1`,
		postID,
	)
	return err
}

func (r *CommunityRepository) DecrementLikesCount(postID uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE community_posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = $1`,
		postID,
	)
	return err
}

func (r *CommunityRepository) GetLikesCount(postID uuid.UUID) (int, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var count int
	err := r.pool.QueryRow(ctx,
		`SELECT likes_count FROM community_posts WHERE id = $1`,
		postID,
	).Scan(&count)
	return count, err
}

// ==================== Comments Count ====================

func (r *CommunityRepository) IncrementCommentsCount(postID uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE community_posts SET comments_count = comments_count + 1 WHERE id = $1`,
		postID,
	)
	return err
}

func (r *CommunityRepository) DecrementCommentsCount(postID uuid.UUID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := r.pool.Exec(ctx,
		`UPDATE community_posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = $1`,
		postID,
	)
	return err
}

// ==================== Reports ====================

func (r *CommunityRepository) CreateReport(report *models.CommunityReport) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return r.pool.QueryRow(ctx,
		`INSERT INTO community_reports (post_id, reporter_id, reason, description, status)
		 VALUES ($1, $2, $3, $4, $5)
		 RETURNING id, created_at`,
		report.PostID, report.ReporterID, report.Reason, report.Description, models.ReportStatusPending,
	).Scan(&report.ID, &report.CreatedAt)
}

// ==================== Driver Info ====================

// GetDriverNameAndAvatar returns the driver's full name and avatar URL
func (r *CommunityRepository) GetDriverNameAndAvatar(userID uuid.UUID) (string, *string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var name string
	var avatar *string
	err := r.pool.QueryRow(ctx,
		`SELECT COALESCE(full_name, ''), avatar_url FROM users WHERE id = $1`,
		userID,
	).Scan(&name, &avatar)
	if err != nil {
		return "", nil, err
	}
	return name, avatar, nil
}

// ==================== Admin Check ====================

func (r *CommunityRepository) IsAdmin(userID uuid.UUID) (bool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var role string
	err := r.pool.QueryRow(ctx,
		`SELECT role FROM users WHERE id = $1`,
		userID,
	).Scan(&role)
	if err != nil {
		return false, err
	}
	return role == "admin" || role == "superadmin", nil
}

// ==================== Zone Info ====================

func (r *CommunityRepository) GetZoneInfo(zoneID uuid.UUID) (string, int, int, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Get zone name
	var zoneName string
	err := r.pool.QueryRow(ctx,
		`SELECT name FROM zones WHERE id = $1`,
		zoneID,
	).Scan(&zoneName)
	if err != nil {
		return "", 0, 0, err
	}

	// Count drivers whose city matches zone name (approximation)
	var totalMembers int
	err = r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM drivers d
		 JOIN users u ON d.user_id = u.id
		 WHERE d.city ILIKE $1 AND d.verification_status = 'approved'`,
		zoneName,
	).Scan(&totalMembers)
	if err != nil {
		totalMembers = 0
	}

	// Count active today (users who posted today in this zone)
	var activeToday int
	err = r.pool.QueryRow(ctx,
		`SELECT COUNT(DISTINCT user_id) FROM community_posts
		 WHERE zone_id = $1 AND is_deleted = FALSE AND created_at >= CURRENT_DATE`,
		zoneID,
	).Scan(&activeToday)
	if err != nil {
		activeToday = 0
	}

	return zoneName, totalMembers, activeToday, nil
}

// GetZones returns all active zones
func (r *CommunityRepository) GetZones() ([]struct {
	ID   uuid.UUID
	Name string
}, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	rows, err := r.pool.Query(ctx,
		`SELECT id, name FROM zones WHERE is_active = TRUE ORDER BY name`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var zones []struct {
		ID   uuid.UUID
		Name string
	}
	for rows.Next() {
		var z struct {
			ID   uuid.UUID
			Name string
		}
		if err := rows.Scan(&z.ID, &z.Name); err != nil {
			return nil, err
		}
		zones = append(zones, z)
	}
	return zones, nil
}

// ==================== Helper ====================

// WithTx runs a function within a database transaction
func (r *CommunityRepository) WithTx(fn func(tx pgx.Tx) error) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	if err := fn(tx); err != nil {
		return err
	}
	return tx.Commit(ctx)
}
