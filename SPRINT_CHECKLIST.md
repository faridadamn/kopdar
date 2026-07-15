# KopDar Frontend — Sprint Tracker

## App: kopdar_driver (Flutter)

---

## ✅ Sprint 1–2: Auth & Dashboard
- [x] Phone input + OTP login
- [x] Personal data registration (nama, NIK, alamat, provinsi, kota)
- [x] Vehicle data registration (tipe, merek, model, tahun, plat, warna)
- [x] Platform selection (Grab, Gojek, etc)
- [x] Bank info registration
- [x] Waiting verification page
- [x] Splash screen with auto-routing
- [x] Main scaffold with bottom nav (4 tabs)
- [x] Home dashboard with income card, quick actions, alerts

## ✅ Sprint 3: Finance
- [x] Income tracker (add income, add expense)
- [x] Income history with filters
- [x] Income detail page
- [x] Keuangan page (overview)
- [x] Hourly rate calculator
- [x] Financial insights page
- [x] Export data page

## ✅ Sprint 4: Savings & Pinjol
- [x] Savings dashboard with goals list
- [x] Create savings goal (name, icon, target, daily amount, auto-save)
- [x] Savings detail page with progress
- [x] Pinjol (pinjaman online) tracker
- [x] Add pinjol entry
- [x] Pinjol detail page

## ✅ Sprint 5: Insurance
- [x] Insurance catalog page
- [x] Insurance detail page
- [x] My insurance page
- [x] File claim page

## ✅ Sprint 6: Community
- [x] Community feed page
- [x] Create post page
- [x] Post detail page with comments
- [x] Advocacy page

## ✅ Sprint 7: Emergency / SOS
- [x] Emergency setup page
- [x] SOS page with pulsing button
- [x] Active SOS view (status, medical info, contacts, nearby drivers)
- [x] Emergency history page
- [x] Medical info page

## ✅ Sprint 8: Profile, Referral, Settings, Onboarding
- [x] Profile page (green gradient header, avatar, membership card, stats, menu)
- [x] Membership card widget (ID, QR placeholder, level badge)
- [x] Level & Points page (badge, progress bar, level comparison, points history)
- [x] Referral page (code display, copy, share buttons, stats, referral list, apply code)
- [x] Settings page (bahasa, zona, auto-tabung, notifikasi toggles, keamanan, tentang, bantuan, hapus akun)
- [x] Onboarding carousel (5 slides: welcome, income, savings, community, SOS)
- [x] Profile provider (profile, level, referral, settings, onboarding state)
- [x] All widgets: membership_card, level_badge, stat_item, referral_card, points_history_tile

## ✅ Sprint 9: Edit Profil & Vehicle Management
- [x] Edit profile page (name, email, photo, phone read-only, member ID read-only)
- [x] Vehicle management page (list, add, edit, delete, set primary)
- [x] Vehicle form page (type, brand dropdown, model, year, plate, color)
- [x] Document management page (SIM, STNK, SKCK, KTP — upload, view, delete, status)
- [x] Vehicle & document models (VehicleModel, DocumentModel)
- [x] Data source updates (CRUD for vehicles & documents)
- [x] Provider updates (vehicle & document state)
- [x] Widgets: vehicle_card, document_tile

## ✅ Sprint 10: Notification Center
- [x] Notification model & data source
- [x] Notification provider (fetch, pagination, read/dismiss, unread count)
- [x] Notification inbox page (grouped by date, swipe-to-delete, mark all read)
- [x] Notification detail page (full content, image, deep link button)
- [x] Notification badge on bottom nav (Beranda tab)
- [x] Notification bell on home header
- [x] Read/dismiss all functionality
- [x] Widgets: notification_tile (swipeable), notification_badge
- [ ] FCM push notification integration (deferred — needs firebase setup)

## ✅ Backlog (Partial)
- [x] Bantuan / Help center page (FAQ, contact, feedback)
- [x] Ride/order history (model, provider, list page, detail page, filters)
- [x] Rewards & loyalty (tukar poin grid, leaderboard, achievements with progress)
- [x] Camera/gallery image picker integration (edit profile + documents)
- [x] Error handling hardening (GlobalErrorHandler, ErrorPage, safe navigation)
- [x] Offline support / caching (CacheHelper with TTL, profile/vehicles/dashboard cache)
- [x] Deep linking (GoRouter error page, safe navigation extensions)

## ✅ Testing (Partial)
- [x] Unit tests — Models (83 test cases)
  - [x] profile_model_test.dart (ProfileModel, LevelInfo, ReferralInfo, SettingsModel, PointsHistory, ReferralEntry)
  - [x] vehicle_model_test.dart (VehicleModel, DocumentModel)
  - [x] notification_model_test.dart (NotificationModel — emoji, label, route, copyWith)
  - [x] ride_model_test.dart (RideModel — platform, status, distance, duration)
  - [x] reward_model_test.dart (RewardModel, AchievementModel, LeaderboardEntry)
- [x] Unit tests — Providers
  - [x] profile_provider_test.dart (fetch, update, vehicles CRUD, logout)
  - [x] notification_provider_test.dart (fetch, mark read, delete, add push, grouped)
- [x] Widget tests
  - [x] help_page_test.dart (render, FAQ expand, feedback submit)
  - [x] notification_tile_test.dart (render, unread dot, onTap)
- [x] Core tests
  - [x] cache_helper_test.dart (JSON cache, TTL, convenience, clear)

## 📋 Backlog (Remaining)
- [ ] More widget tests (profile, onboarding, ride history)
- [ ] File picker integration (document upload)
- [ ] Export ride history to CSV/PDF
- [ ] FCM push notification setup
- [ ] Android/iOS deep link config (App Links / Universal Links)

---

*Last updated: 2026-07-15 12:27 WIB*
