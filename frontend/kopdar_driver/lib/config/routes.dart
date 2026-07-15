import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/presentation/pages/phone_input_page.dart';
import '../features/auth/presentation/pages/otp_page.dart';
import '../features/auth/presentation/pages/personal_data_page.dart';
import '../features/auth/presentation/pages/vehicle_data_page.dart';
import '../features/auth/presentation/pages/platform_selection_page.dart';
import '../features/auth/presentation/pages/bank_info_page.dart';
import '../features/auth/presentation/pages/waiting_verification_page.dart';
import '../features/common/pages/main_scaffold.dart';
import '../features/income/presentation/pages/add_income_page.dart';
import '../features/income/presentation/pages/add_expense_page.dart';
import '../features/income/presentation/pages/income_history_page.dart';
import '../features/income/presentation/pages/income_detail_page.dart';
import '../features/income/presentation/pages/keuangan_page.dart';
import '../features/expense/presentation/pages/expense_history_page.dart';
import '../features/finance/presentation/pages/hourly_rate_page.dart';
import '../features/finance/presentation/pages/insights_page.dart';
import '../features/finance/presentation/pages/export_page.dart';
import '../features/savings/presentation/pages/savings_page.dart';
import '../features/savings/presentation/pages/create_saving_page.dart';
import '../features/savings/presentation/pages/saving_detail_page.dart';
import '../features/pinjol/presentation/pages/pinjol_page.dart';
import '../features/pinjol/presentation/pages/add_pinjol_page.dart';
import '../features/pinjol/presentation/pages/pinjol_detail_page.dart';
import '../features/insurance/presentation/pages/insurance_catalog_page.dart';
import '../features/insurance/presentation/pages/insurance_detail_page.dart';
import '../features/insurance/presentation/pages/my_insurance_page.dart';
import '../features/insurance/presentation/pages/file_claim_page.dart';
import '../features/community/presentation/pages/community_page.dart';
import '../features/community/presentation/pages/create_post_page.dart';
import '../features/community/presentation/pages/post_detail_page.dart';
import '../features/community/presentation/pages/advocacy_page.dart';
import '../features/emergency/presentation/pages/emergency_setup_page.dart';
import '../features/emergency/presentation/pages/sos_page.dart';
import '../features/emergency/presentation/pages/emergency_history_page.dart';
import '../features/emergency/presentation/pages/medical_info_page.dart';
import '../features/profile/presentation/pages/profil_page.dart';
import '../features/profile/presentation/pages/level_page.dart';
import '../features/profile/presentation/pages/referral_page.dart';
import '../features/profile/presentation/pages/settings_page.dart';
import '../features/profile/presentation/pages/onboarding_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/vehicle_page.dart';
import '../features/profile/presentation/pages/vehicle_form_page.dart';
import '../features/profile/presentation/pages/document_page.dart';
import '../features/notification/presentation/pages/notification_page.dart';
import '../features/notification/presentation/pages/notification_detail_page.dart';
import '../features/help/presentation/pages/help_page.dart';
import '../features/ride/presentation/pages/ride_history_page.dart';
import '../features/ride/presentation/pages/ride_detail_page.dart';
import '../features/rewards/presentation/pages/rewards_page.dart';
import '../core/errors/error_handler.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => ErrorPage(
      errorMessage: state.error?.toString(),
    ),
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const PhoneInputPage(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpPage(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/register/personal',
        name: 'register-personal',
        builder: (context, state) => const PersonalDataPage(),
      ),
      GoRoute(
        path: '/register/vehicle',
        name: 'register-vehicle',
        builder: (context, state) => const VehicleDataPage(),
      ),
      GoRoute(
        path: '/register/platforms',
        name: 'register-platforms',
        builder: (context, state) => const PlatformSelectionPage(),
      ),
      GoRoute(
        path: '/register/bank',
        name: 'register-bank',
        builder: (context, state) => const BankInfoPage(),
      ),
      GoRoute(
        path: '/waiting-verification',
        name: 'waiting-verification',
        builder: (context, state) => const WaitingVerificationPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainScaffold(),
      ),

      // ── Income Tracker routes ──
      GoRoute(
        path: '/keuangan',
        name: 'keuangan',
        builder: (context, state) => const KeuanganPage(),
      ),
      GoRoute(
        path: '/income/add',
        name: 'income-add',
        builder: (context, state) => const AddIncomePage(),
      ),
      GoRoute(
        path: '/expense/add',
        name: 'expense-add',
        builder: (context, state) => const AddExpensePage(),
      ),
      GoRoute(
        path: '/income/history',
        name: 'income-history',
        builder: (context, state) => const IncomeHistoryPage(),
      ),
      GoRoute(
        path: '/income/:id',
        name: 'income-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return IncomeDetailPage(id: id);
        },
      ),

      // ── Sprint 3: Finance routes ──
      GoRoute(
        path: '/expense/history',
        name: 'expense-history',
        builder: (context, state) => const ExpenseHistoryPage(),
      ),
      GoRoute(
        path: '/finance/hourly-rate',
        name: 'hourly-rate',
        builder: (context, state) => const HourlyRatePage(),
      ),
      GoRoute(
        path: '/finance/insights',
        name: 'insights',
        builder: (context, state) => const InsightsPage(),
      ),
      GoRoute(
        path: '/finance/export',
        name: 'export',
        builder: (context, state) => const ExportPage(),
      ),

      // ── Sprint 4: Savings routes ──
      GoRoute(
        path: '/savings',
        name: 'savings',
        builder: (context, state) => const SavingsPage(),
      ),
      GoRoute(
        path: '/savings/create',
        name: 'savings-create',
        builder: (context, state) => const CreateSavingPage(),
      ),
      GoRoute(
        path: '/savings/:id',
        name: 'savings-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SavingDetailPage(id: id);
        },
      ),

      // ── Sprint 4: Pinjol routes ──
      GoRoute(
        path: '/pinjol',
        name: 'pinjol',
        builder: (context, state) => const PinjolPage(),
      ),
      GoRoute(
        path: '/pinjol/add',
        name: 'pinjol-add',
        builder: (context, state) => const AddPinjolPage(),
      ),
      GoRoute(
        path: '/pinjol/:id',
        name: 'pinjol-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PinjolDetailPage(id: id);
        },
      ),

      // ── Sprint 5: Insurance routes ──
      GoRoute(
        path: '/insurance',
        name: 'insurance',
        builder: (context, state) => const InsuranceCatalogPage(),
      ),
      GoRoute(
        path: '/insurance/:id',
        name: 'insurance-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InsuranceDetailPage(id: id);
        },
      ),
      GoRoute(
        path: '/insurance/my',
        name: 'insurance-my',
        builder: (context, state) => const MyInsurancePage(),
      ),
      GoRoute(
        path: '/insurance/claim',
        name: 'insurance-claim',
        builder: (context, state) => const FileClaimPage(),
      ),

      // ── Sprint 6: Community routes ──
      GoRoute(
        path: '/community',
        name: 'community',
        builder: (context, state) => const CommunityPage(),
      ),
      GoRoute(
        path: '/community/create',
        name: 'community-create',
        builder: (context, state) => const CreatePostPage(),
      ),
      GoRoute(
        path: '/community/:id',
        name: 'community-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PostDetailPage(id: id);
        },
      ),
      GoRoute(
        path: '/community/advocacy',
        name: 'community-advocacy',
        builder: (context, state) => const AdvocacyPage(),
      ),

      // ── Sprint 8: Profile routes ──
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/profile/level',
        name: 'profile-level',
        builder: (context, state) => const LevelPage(),
      ),
      GoRoute(
        path: '/profile/referral',
        name: 'profile-referral',
        builder: (context, state) => const ReferralPage(),
      ),
      GoRoute(
        path: '/profile/settings',
        name: 'profile-settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'profile-edit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profile/vehicle',
        name: 'profile-vehicle',
        builder: (context, state) => const VehiclePage(),
      ),
      GoRoute(
        path: '/profile/vehicle/add',
        name: 'profile-vehicle-add',
        builder: (context, state) => const VehicleFormPage(),
      ),
      GoRoute(
        path: '/profile/vehicle/edit/:id',
        name: 'profile-vehicle-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VehicleFormPage(vehicleId: id);
        },
      ),
      GoRoute(
        path: '/profile/documents',
        name: 'profile-documents',
        builder: (context, state) => const DocumentPage(),
      ),

      // ── Sprint 10: Notification routes ──
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpPage(),
      ),
      GoRoute(
        path: '/ride/history',
        name: 'ride-history',
        builder: (context, state) => const RideHistoryPage(),
      ),
      GoRoute(
        path: '/ride/detail/:id',
        name: 'ride-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RideDetailPage(rideId: id);
        },
      ),
      GoRoute(
        path: '/rewards',
        name: 'rewards',
        builder: (context, state) => const RewardsPage(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationPage(),
      ),
      GoRoute(
        path: '/notification/detail/:id',
        name: 'notification-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NotificationDetailPage(notificationId: id);
        },
      ),

      // ── Sprint 7: Emergency / SOS routes ──
      GoRoute(
        path: '/emergency/setup',
        name: 'emergency-setup',
        builder: (context, state) => const EmergencySetupPage(),
      ),
      GoRoute(
        path: '/emergency/sos',
        name: 'emergency-sos',
        builder: (context, state) => const SOSPage(),
      ),
      GoRoute(
        path: '/emergency/history',
        name: 'emergency-history',
        builder: (context, state) => const EmergencyHistoryPage(),
      ),
      GoRoute(
        path: '/emergency/medical',
        name: 'emergency-medical',
        builder: (context, state) => const MedicalInfoPage(),
      ),
    ],
  );
}
