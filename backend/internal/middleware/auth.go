package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/kopdar/backend/internal/services"
	"github.com/kopdar/backend/internal/utils"
)

const (
	ContextUserID = "user_id"
	ContextPhone  = "phone"
	ContextRole   = "role"
)

// AuthMiddleware validates JWT and sets user context
func AuthMiddleware(authSvc *services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			utils.Unauthorized(c, "Authorization header required")
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			utils.Unauthorized(c, "Invalid authorization format")
			c.Abort()
			return
		}

		claims, err := authSvc.ValidateAccessToken(parts[1])
		if err != nil {
			utils.Unauthorized(c, "Invalid or expired token")
			c.Abort()
			return
		}

		c.Set(ContextUserID, claims.UserID)
		c.Set(ContextPhone, claims.Phone)
		c.Set(ContextRole, claims.Role)
		c.Next()
	}
}

// AdminMiddleware requires admin or superadmin role
func AdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, exists := c.Get(ContextRole)
		if !exists {
			utils.Forbidden(c, "Access denied")
			c.Abort()
			return
		}

		roleStr, ok := role.(string)
		if !ok || (roleStr != "admin" && roleStr != "superadmin") {
			utils.Forbidden(c, "Admin access required")
			c.Abort()
			return
		}

		c.Next()
	}
}
