class ApiEndpoints {
  ApiEndpoints._();

  static const String sendOtp = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  static const String registerDriver = '/driver/register';
  static const String registerPersonal = registerDriver;
  static const String registerVehicle = registerDriver;
  static const String registerPlatforms = registerDriver;
  static const String registerBank = registerDriver;
  static const String registerSubmit = registerDriver;
  static const String registerStatus = '/driver/status';
  static const String uploadKtp = registerDriver;
  static const String uploadSelfie = registerDriver;
  static const String uploadVehicle = registerDriver;

  static const String userProfile = '/driver/profile';
  static const String updateProfile = '/driver/profile';

  static const String dashboard = '/driver/dashboard';
  static const String incomeSummary = '/driver/transactions/summary';
  static const String recentTransactions = '/driver/transactions';
  static const String alerts = '/driver/dashboard';

  static const String transactions = '/driver/transactions';
  static const String addIncome = '/driver/transactions';
  static const String addExpense = '/driver/transactions';
  static const String transactionSummary = '/driver/transactions/summary';

  static const String savings = '/driver/savings';
  static const String savingsCreate = '/driver/savings';
  static const String savingsWithdraw = '/driver/savings';

  static const String insuranceProducts = '/driver/insurance/products';
  static const String insuranceCatalog = insuranceProducts;
  static const String insurancePurchase = '/driver/insurance/policies';
  static const String insurancePolicies = '/driver/insurance/policies';
  static const String insuranceClaim = '/driver/insurance/claims';
  static const String insuranceClaims = '/driver/insurance/claims';

  static const String communityPosts = '/driver/community/posts';
  static const String communityFeed = communityPosts;
  static const String communityPost = communityPosts;
  static const String communityComment = communityPosts;
  static const String communityZone = '/driver/community/zone';
  static const String communityAdvocacy = '/driver/community/advocacy';

  static const String sosActivate = '/driver/emergency/sos';
  static const String sosResolve = '/driver/emergency/sos';
  static const String sosNearby = '/driver/emergency/active';
  static const String sosActive = '/driver/emergency/active';
  static const String sosHistory = '/driver/emergency/history';

  static const String hourlyRate = '/driver/hourly-rate';
  static const String insights = '/driver/insights';
  static const String exportData = '/driver/export';
}
