class AppConstants {
  AppConstants._();

  static const String appName = 'KopDar';
  static const String appTagline = 'Koperasi Digital Gig Worker';
  static const String appVersion = '1.0.0';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;

  static const String keyToken = 'auth_token';
  static const String keyRefreshToken = 'auth_refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserPhone = 'user_phone';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyIsVerified = 'is_verified';
  static const String keyFirstTime = 'first_time';
  static const String keyDriverStatus = 'driver_status';

  static const int otpLength = 6;
  static const int otpResendSeconds = 60;
  static const int otpExpiryMinutes = 5;
  static const int maxOtpAttempts = 3;
  static const int lockoutMinutes = 15;

  static const int nikLength = 16;
  static const int platMaxLength = 12;
  static const int splashDurationMs = 2000;

  static const List<String> platforms = [
    'Gojek',
    'Grab',
    'ShopeeFood',
    'Maxim',
    'InDrive',
  ];

  static const List<Map<String, String>> banks = [
    {'name': 'BCA', 'code': 'bca'},
    {'name': 'BRI', 'code': 'bri'},
    {'name': 'Mandiri', 'code': 'mandiri'},
    {'name': 'BNI', 'code': 'bni'},
    {'name': 'GoPay', 'code': 'gopay'},
    {'name': 'OVO', 'code': 'ovo'},
    {'name': 'Dana', 'code': 'dana'},
  ];

  static const Map<String, List<String>> vehicleBrands = {
    'Motor': ['Honda', 'Yamaha', 'Suzuki', 'Kawasaki', 'Vespa', 'Lainnya'],
    'Mobil': ['Toyota', 'Honda', 'Daihatsu', 'Suzuki', 'Mitsubishi', 'Hyundai', 'Lainnya'],
  };

  static const List<String> provinces = [
    'DKI Jakarta',
    'Jawa Barat',
    'Jawa Tengah',
    'Jawa Timur',
    'Banten',
    'DI Yogyakarta',
    'Bali',
    'Sumatera Utara',
    'Sumatera Barat',
    'Sumatera Selatan',
    'Kalimantan Timur',
    'Sulawesi Selatan',
    'Lainnya',
  ];

  static const Map<String, List<String>> citiesByProvince = {
    'DKI Jakarta': ['Jakarta Selatan', 'Jakarta Timur', 'Jakarta Barat', 'Jakarta Utara', 'Jakarta Pusat'],
    'Jawa Barat': ['Bandung', 'Bekasi', 'Depok', 'Bogor', 'Tangerang'],
    'Banten': ['Tangerang', 'Tangerang Selatan', 'Serang', 'Cilegon'],
    'Jawa Tengah': ['Semarang', 'Solo', 'Yogyakarta'],
    'Jawa Timur': ['Surabaya', 'Malang', 'Sidoarjo'],
  };

  static const int vehicleYearMin = 2010;
  static int get vehicleYearMax => DateTime.now().year;

  static const String currencySymbol = 'Rp';
  static const String locale = 'id_ID';
}
