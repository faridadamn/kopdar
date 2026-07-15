class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String sendOtp = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Driver registration/profile
  static const String registerDriver = '/driver/register';
  static const String registerStatus = '/driver/status';
  static const String userProfile = '/driver/profile';
  static const String updateProfile = '/driver/profile';

  // Dashboard
  static const String dashboard = '/driver/dashboard';

  // Transactions
  static const String transactions = '/driver/transactions';
  static const String transactionSummary = '/driver/transactions/summary';

  // Savings
  static const String savings = '/driver/savings';

  // Insurance
  static const String insuranceProducts = '/driver/insurance/products';
  static const String insurancePolicies = '/driver/insurance/policies';
  static const String insuranceClaims = '/driver/insurance/claims';

  // Community
  static const String communityPosts = '/driver/community/posts';
  static const String communityZone = '/driver/community/zone';
  static const String communityAdvocacy = '/driver/community/advocacy';

  // SOS
  static const String sosActivate = '/driver/emergency/sos';
  static const String sosActive = '/driver/emergency/active';
  static const String sosHistory = '/driver/emergency/history';

  // Finance
  static const String hourlyRate = '/driver/hourly-rate';
  static const String insights = '/driver/insights';
  static const String exportData = '/driver/export';
}
