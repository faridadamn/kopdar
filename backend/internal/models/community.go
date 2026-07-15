package models

import (
	"time"

	"github.com/google/uuid"
)

// Community post categories
const (
	PostCategoryTips      = "tips"
	PostCategoryQuestion  = "question"
	PostCategoryComplaint = "complaint"
	PostCategoryInfo      = "info"
	PostCategoryAdvocacy  = "advocacy"
)

// Community post visibility
const (
	VisibilityZone = "zone"
	VisibilityAll  = "all"
)

// Community report statuses
const (
	ReportStatusPending   = "pending"
	ReportStatusResolved  = "resolved"
	ReportStatusDismissed = "dismissed"
)

// CommunityPost represents a community forum post
type CommunityPost struct {
	ID            uuid.UUID  `json:"id" db:"id"`
	UserID        uuid.UUID  `json:"user_id" db:"user_id"`
	Content       string     `json:"content" db:"content"`
	ImageURLs     []string   `json:"image_urls" db:"image_urls"`
	Category      string     `json:"category" db:"category"`
	Visibility    string     `json:"visibility" db:"visibility"`
	ZoneID        *uuid.UUID `json:"zone_id,omitempty" db:"zone_id"`
	LikesCount    int        `json:"likes_count" db:"likes_count"`
	CommentsCount int        `json:"comments_count" db:"comments_count"`
	IsPinned      bool       `json:"is_pinned" db:"is_pinned"`
	IsDeleted     bool       `json:"-" db:"is_deleted"`
	CreatedAt     time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at" db:"updated_at"`
}

// CommunityComment represents a comment on a community post
type CommunityComment struct {
	ID        uuid.UUID  `json:"id" db:"id"`
	PostID    uuid.UUID  `json:"post_id" db:"post_id"`
	UserID    uuid.UUID  `json:"user_id" db:"user_id"`
	ParentID  *uuid.UUID `json:"parent_id,omitempty" db:"parent_id"`
	Content   string     `json:"content" db:"content"`
	IsDeleted bool       `json:"-" db:"is_deleted"`
	CreatedAt time.Time  `json:"created_at" db:"created_at"`
}

// CommunityLike represents a like on a post
type CommunityLike struct {
	ID        uuid.UUID `json:"id" db:"id"`
	PostID    uuid.UUID `json:"post_id" db:"post_id"`
	UserID    uuid.UUID `json:"user_id" db:"user_id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// CommunityReport represents a report on a post
type CommunityReport struct {
	ID          uuid.UUID  `json:"id" db:"id"`
	PostID      *uuid.UUID `json:"post_id,omitempty" db:"post_id"`
	CommentID   *uuid.UUID `json:"comment_id,omitempty" db:"comment_id"`
	ReporterID  uuid.UUID  `json:"reporter_id" db:"reporter_id"`
	Reason      string     `json:"reason" db:"reason"`
	Description *string    `json:"description,omitempty" db:"description"`
	Status      string     `json:"status" db:"status"`
	ReviewedBy  *uuid.UUID `json:"reviewed_by,omitempty" db:"reviewed_by"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
}

// Request DTOs

type CommunityPostCreateRequest struct {
	Content    string   `json:"content" binding:"required,max=500"`
	ImageURLs  []string `json:"image_urls"`
	Category   string   `json:"category" binding:"required,oneof=tips question complaint info advocacy"`
	Visibility string   `json:"visibility" binding:"omitempty,oneof=zone all"`
}

type CommunityPostUpdateRequest struct {
	Content  *string `json:"content" binding:"omitempty,max=500"`
	Category *string `json:"category" binding:"omitempty,oneof=tips question complaint info advocacy"`
}

type CommunityCommentCreateRequest struct {
	Content  string     `json:"content" binding:"required,max=200"`
	ParentID *uuid.UUID `json:"parent_id"`
}

type CommunityCommentUpdateRequest struct {
	Content string `json:"content" binding:"required,max=200"`
}

type CommunityReportRequest struct {
	Reason string `json:"reason" binding:"required"`
}

// Response DTOs

type CommunityPostResponse struct {
	CommunityPost
	DriverName  string  `json:"driver_name"`
	DriverAvatar *string `json:"driver_avatar,omitempty"`
	IsLiked     bool    `json:"is_liked"`
}

type CommunityPostListResponse struct {
	Posts      []CommunityPostResponse `json:"posts"`
	Page       int                     `json:"page"`
	Limit      int                     `json:"limit"`
	TotalCount int                     `json:"total_count"`
	TotalPages int                     `json:"total_pages"`
}

type CommunityPostDetailResponse struct {
	CommunityPostResponse
	Comments []CommunityCommentTree `json:"comments"`
}

type CommunityCommentResponse struct {
	CommunityComment
	DriverName   string  `json:"driver_name"`
	DriverAvatar *string `json:"driver_avatar,omitempty"`
}

type CommunityCommentTree struct {
	CommunityCommentResponse
	Replies []CommunityCommentResponse `json:"replies"`
}

type CommunityLikeResponse struct {
	Liked      bool `json:"liked"`
	LikesCount int  `json:"likes_count"`
}

type CommunityToggleLikeResponse struct {
	Liked      bool `json:"liked"`
	LikesCount int  `json:"likes_count"`
}

type CommunityZoneInfo struct {
	ZoneName     string   `json:"zone_name"`
	TotalMembers int      `json:"total_members"`
	ActiveToday  int      `json:"active_today"`
	Tips         []string `json:"tips"`
	Events       []string `json:"events"`
}

type CommunityAdvocacyResponse struct {
	CollectiveStats AdvocacyStats    `json:"collective_stats"`
	Petitions       []AdvocacyItem   `json:"petitions"`
	Updates         []AdvocacyItem   `json:"updates"`
	Polls           []AdvocacyPoll   `json:"polls"`
}

type AdvocacyStats struct {
	TotalMembers      int     `json:"total_members"`
	AvgProfit         float64 `json:"avg_profit"`
	AvgHours          float64 `json:"avg_hours"`
	PinjolPercentage  int     `json:"pinjol_percentage"`
}

type AdvocacyItem struct {
	ID        uuid.UUID `json:"id"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

type AdvocacyPoll struct {
	ID        uuid.UUID      `json:"id"`
	Question  string         `json:"question"`
	Options   []AdvocacyPollOption `json:"options"`
	TotalVotes int           `json:"total_votes"`
	EndsAt    time.Time      `json:"ends_at"`
}

type AdvocacyPollOption struct {
	Label string `json:"label"`
	Votes int    `json:"votes"`
}
