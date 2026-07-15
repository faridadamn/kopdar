package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/kopdar/backend/internal/config"
	"github.com/kopdar/backend/internal/handlers"
	"github.com/kopdar/backend/internal/middleware"
	"github.com/kopdar/backend/internal/repository"
	"github.com/kopdar/backend/internal/services"
)

func main() {
	cfg := config.Load()

	// Database connection
	pool, err := pgxpool.New(context.Background(), cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer pool.Close()

	// Verify connection
	if err := pool.Ping(context.Background()); err != nil {
		log.Fatalf("Unable to ping database: %v", err)
	}
	log.Println("Connected to database")

	// Repositories
	userRepo := repository.NewUserRepository(pool)
	tokenRepo := repository.NewTokenRepository(pool)
	driverRepo := repository.NewDriverRepository(pool)
	txnRepo := repository.NewTransactionRepository(pool)
	savingRepo := repository.NewSavingRepository(pool)
	pinjolRepo := repository.NewPinjolRepository(pool)
	insuranceRepo := repository.NewInsuranceRepository(pool)
	commRepo := repository.NewCommunityRepository(pool)
	emergRepo := repository.NewEmergencyRepository(pool)
	profileRepo := repository.NewProfileRepository(pool)

	// Services
	otpSvc := services.NewOTPService(cfg.OTPMode == "true")
	authSvc := services.NewAuthService(userRepo, tokenRepo, otpSvc, cfg.JWTSecret)
	pointsSvc := services.NewPointsService(profileRepo)

	// Handlers
	authHandler := handlers.NewAuthHandler(authSvc, otpSvc)
	driverHandler := handlers.NewDriverHandler(driverRepo, userRepo, cfg.UploadDir)
	adminHandler := handlers.NewAdminHandler(driverRepo, userRepo)
	transactionHandler := handlers.NewTransactionHandler(txnRepo, driverRepo)
	dashboardHandler := handlers.NewDashboardHandler(txnRepo, driverRepo)
	hourlyRateHandler := handlers.NewHourlyRateHandler(pool, driverRepo)
	expenseHandler := handlers.NewExpenseHandler(pool, driverRepo)
	exportHandler := handlers.NewExportHandler(pool, driverRepo)
	insightsHandler := handlers.NewInsightsHandler(pool, driverRepo)
	savingHandler := handlers.NewSavingHandler(savingRepo, driverRepo)
	pinjolHandler := handlers.NewPinjolHandler(pinjolRepo, savingRepo, driverRepo)
	insuranceHandler := handlers.NewInsuranceHandler(insuranceRepo, driverRepo)
	commHandler := handlers.NewCommunityHandler(commRepo, driverRepo)
	emergHandler := handlers.NewEmergencyHandler(emergRepo, driverRepo)
	profileHandler := handlers.NewProfileHandler(profileRepo, driverRepo, userRepo, pointsSvc, cfg.UploadDir)
	referralHandler := handlers.NewReferralHandler(profileRepo, driverRepo, pointsSvc)
	settingsHandler := handlers.NewSettingsHandler(profileRepo, driverRepo)

	// Router
	router := gin.Default()
	router.Use(middleware.CORS())

	// Ensure upload dir exists
	os.MkdirAll(cfg.UploadDir, 0755)

	// Health
	router.GET("/api/v1/health", handlers.HealthCheck)

	// Auth routes (public)
	auth := router.Group("/api/v1/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/verify-otp", authHandler.VerifyOTP)
		auth.POST("/login", authHandler.Login)
		auth.POST("/refresh", authHandler.Refresh)
		auth.DELETE("/logout", authHandler.Logout)
	}

	// Driver routes (authenticated)
	driver := router.Group("/api/v1/driver")
	driver.Use(middleware.AuthMiddleware(authSvc))
	{
		driver.POST("/register", driverHandler.Register)
		driver.GET("/profile", profileHandler.GetProfile)
		driver.PUT("/profile", driverHandler.UpdateProfile)
		driver.GET("/status", driverHandler.GetStatus)

		// Transaction routes
		transaction := driver.Group("/transactions")
		{
			transaction.POST("", transactionHandler.Create)
			transaction.GET("", transactionHandler.List)
			transaction.GET("/summary", transactionHandler.Summary)
			transaction.GET("/:id", transactionHandler.Get)
			transaction.PUT("/:id", transactionHandler.Update)
			transaction.DELETE("/:id", transactionHandler.Delete)
		}

		// Dashboard
		driver.GET("/dashboard", dashboardHandler.Get)

		// Sprint 3: Hourly Rate, Expenses, Export, Insights
		driver.GET("/hourly-rate", hourlyRateHandler.Get)
		driver.GET("/expenses", expenseHandler.List)
		driver.GET("/expenses/summary", expenseHandler.Summary)
		driver.GET("/export", exportHandler.CSV)
		driver.GET("/insights", insightsHandler.Get)

		// Sprint 4: Savings
		driver.POST("/savings", savingHandler.Create)
		driver.GET("/savings", savingHandler.List)
		driver.GET("/savings/:id", savingHandler.Get)
		driver.PUT("/savings/:id", savingHandler.Update)
		driver.POST("/savings/:id/deposit", savingHandler.Deposit)
		driver.POST("/savings/:id/withdraw", savingHandler.Withdraw)
		driver.PUT("/savings/:id/pause", savingHandler.Pause)
		driver.PUT("/savings/:id/resume", savingHandler.Resume)

		// Sprint 4: Pinjol
		driver.POST("/pinjol", pinjolHandler.Create)
		driver.GET("/pinjol", pinjolHandler.List)
		driver.GET("/pinjol/:id", pinjolHandler.Get)
		driver.PUT("/pinjol/:id", pinjolHandler.Update)
		driver.DELETE("/pinjol/:id", pinjolHandler.Delete)
		driver.GET("/pinjol/:id/simulate", pinjolHandler.Simulate)

		// Sprint 6: Community & Forum
		comm := driver.Group("/community")
		{
			comm.POST("/posts", commHandler.CreatePost)
			comm.GET("/posts", commHandler.ListPosts)
			comm.GET("/posts/:id", commHandler.GetPost)
			comm.PUT("/posts/:id", commHandler.UpdatePost)
			comm.DELETE("/posts/:id", commHandler.DeletePost)
			comm.POST("/posts/:id/like", commHandler.ToggleLike)
			comm.POST("/posts/:id/comments", commHandler.AddComment)
			comm.PUT("/comments/:id", commHandler.UpdateComment)
			comm.DELETE("/comments/:id", commHandler.DeleteComment)
			comm.POST("/posts/:id/report", commHandler.ReportPost)
			comm.GET("/zone", commHandler.ZoneInfo)
			comm.GET("/advocacy", commHandler.AdvocacyData)
		}

		// Sprint 7: SOS & Emergency
		emerg := driver.Group("/emergency")
		{
			emerg.GET("/setup", emergHandler.GetSetup)
			emerg.PUT("/medical", emergHandler.UpdateMedicalInfo)
			emerg.GET("/medical", emergHandler.GetMedicalInfo)
			emerg.POST("/contacts", emergHandler.AddContact)
			emerg.GET("/contacts", emergHandler.ListContacts)
			emerg.DELETE("/contacts/:id", emergHandler.DeleteContact)
			emerg.POST("/sos", emergHandler.ActivateSOS)
			emerg.GET("/active", emergHandler.GetActiveSOS)
			emerg.GET("/:id", emergHandler.GetEmergency)
			emerg.POST("/sos/:id/respond", emergHandler.RespondSOS)
			emerg.POST("/sos/:id/arrive", emergHandler.MarkArrived)
			emerg.POST("/sos/:id/resolve", emergHandler.ResolveSOS)
			emerg.POST("/sos/:id/false-alarm", emergHandler.MarkFalseAlarm)
			emerg.POST("/crash", emergHandler.ReportCrash)
			emerg.POST("/location", emergHandler.UpdateLocation)
			emerg.GET("/history", emergHandler.ListHistory)
			emerg.POST("/:id/feedback", emergHandler.SubmitFeedback)
		}

		// Sprint 8: Profile, Level, Referral, Settings
		driver.PUT("/profile/photo", profileHandler.UpdatePhoto)
		driver.GET("/level", profileHandler.GetLevel)
		driver.POST("/level/add-points", profileHandler.AddPoints)

		driver.GET("/referral", referralHandler.GetInfo)
		driver.POST("/referral/apply", referralHandler.ApplyCode)
		driver.GET("/referral/share", referralHandler.ShareContent)

		driver.GET("/settings", settingsHandler.Get)
		driver.PUT("/settings", settingsHandler.Update)
		driver.POST("/settings/test-notification", settingsHandler.TestNotification)
		driver.DELETE("/account", settingsHandler.DeleteAccount)

		// Sprint 5: Insurance
		insurance := driver.Group("/insurance")
		{
			insurance.GET("/products", insuranceHandler.ListProducts)
			insurance.GET("/products/:id", insuranceHandler.GetProduct)
			insurance.POST("/policies", insuranceHandler.PurchasePolicy)
			insurance.GET("/policies", insuranceHandler.ListPolicies)
			insurance.GET("/policies/:id", insuranceHandler.GetPolicy)
			insurance.PUT("/policies/:id/renew", insuranceHandler.RenewPolicy)
			insurance.POST("/claims", insuranceHandler.FileClaim)
			insurance.GET("/claims", insuranceHandler.ListClaims)
			insurance.GET("/claims/:id", insuranceHandler.GetClaim)
		}
	}

	// Admin routes (authenticated + admin role)
	admin := router.Group("/api/v1/admin")
	admin.Use(middleware.AuthMiddleware(authSvc))
	admin.Use(middleware.AdminMiddleware())
	{
		admin.GET("/drivers/pending", adminHandler.ListPendingDrivers)
		admin.GET("/drivers/:id", adminHandler.GetDriverDetail)
		admin.PUT("/drivers/:id/approve", adminHandler.ApproveDriver)
		admin.PUT("/drivers/:id/reject", adminHandler.RejectDriver)
		admin.GET("/stats", adminHandler.GetStats)
	}

	// Start server with graceful shutdown
	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: router,
	}

	// Seed insurance products
	services.SeedInsuranceProducts(context.Background(), pool)

	go func() {
		log.Printf("Starting KopDar backend on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err)
		}
	}()

	// Wait for interrupt
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}
	log.Println("Server exited")
}
