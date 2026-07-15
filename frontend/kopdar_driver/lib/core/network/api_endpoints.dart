class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Registration
  static const String registerPersonal = '/register/personal';
  static const String registerVehicle = '/register/vehicle';
  static const String registerPlatforms = '/register/platforms';
  static const String registerBank = '/register/bank';
  static const String registerSubmit = '/register/submit';
  static const String registerStatus = '/register/status';

  // Upload
  static const String uploadKtp = '/upload/ktp';
  static const String uploadSelfie = '/upload/selfie';
  static const String uploadVehicle = '/upload/vehicle';

  // User
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';

  // Dashboard
  static const String dashboard = '/dashboard';
  static const String incomeSummary = '/dashboard/income-summary';
  static const String recentTransactions = '/dashboard/recent-transactions';
  static const String alerts = '/dashboard/alerts';

  // Transactions
  static const String transactions = '/transactions';
  static const String addIncome = '/transactions/income';
  static const String addExpense = '/transactions/expense';

  // Savings
  static const String savings = '/savings';
  static const String savingsCreate = '/savings/create';
  static const String savingsWithdraw = '/savings/withdraw';

  // Insurance
  static const String insuranceCatalog = '/insurance/catalog';
  static const String insurancePurchase = '/insurance/purchase';
  static const String insurancePolicies = '/insurance/policies';
  static const String insuranceClaim = '/insurance/claim';

  // Community
  static const String communityFeed = '/community/feed';
  static const String communityPost = '/community/post';
  static const String communityComment = '/community/comment';

  // SOS
  static const String sosActivate = '/sos/activate';
  static const String sosResolve = '/sos/resolve';
  static const String sosNearby = '/sos/nearby';

  // Finance
  static const String hourlyRate = '/driver/hourly-rate';
  static const String insights = '/driver/insights';
  static const String exportData = '/driver/export';
}
