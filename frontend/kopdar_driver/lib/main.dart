import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/registration_draft_provider.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/income/presentation/providers/transaction_provider.dart';
import 'features/finance/presentation/providers/finance_provider.dart';
import 'features/savings/presentation/providers/saving_provider.dart';
import 'features/pinjol/presentation/providers/pinjol_provider.dart';
import 'features/insurance/presentation/providers/insurance_provider.dart';
import 'features/community/presentation/providers/community_provider.dart';
import 'features/emergency/presentation/providers/emergency_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/ride/presentation/providers/ride_provider.dart';
import 'core/storage/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationDraftProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => SavingProvider()),
        ChangeNotifierProvider(create: (_) => PinjolProvider()),
        ChangeNotifierProvider(create: (_) => InsuranceProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
      ],
      child: const KopDarApp(),
    ),
  );
}
