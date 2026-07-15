import 'package:intl/intl.dart';
import '../../config/constants.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: AppConstants.locale,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.compactCurrency(
    locale: AppConstants.locale,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _dayFormat = DateFormat('EEEE', 'id_ID');

  /// Format currency: 247500 → "Rp 247.500"
  static String currency(int amount) {
    return _currencyFormat.format(amount);
  }

  /// Format currency with sign: +Rp 247.500 / -Rp 50.000
  static String currencyWithSign(int amount) {
    if (amount >= 0) {
      return '+${_currencyFormat.format(amount)}';
    }
    return '-${_currencyFormat.format(amount.abs())}';
  }

  /// Format compact currency: 1500000 → "Rp 1,5jt"
  static String currencyCompact(int amount) {
    return _compactCurrencyFormat.format(amount);
  }

  /// Format phone number: 081234567890 → "0812-3456-7890"
  static String phone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-+]'), '');
    String normalized = cleaned;
    if (normalized.startsWith('628')) {
      normalized = '0${normalized.substring(2)}';
    }

    if (normalized.length >= 12) {
      return '${normalized.substring(0, 4)}-${normalized.substring(4, 8)}-${normalized.substring(8)}';
    } else if (normalized.length >= 8) {
      return '${normalized.substring(0, 4)}-${normalized.substring(4)}';
    }
    return normalized;
  }

  /// Format date: DateTime → "15 Jul 2026"
  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format datetime: DateTime → "15 Jul 2026 14:30"
  static String dateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format time: DateTime → "14:30"
  static String time(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format day name: DateTime → "Senin"
  static String dayName(DateTime date) {
    return _dayFormat.format(date);
  }

  /// Get greeting based on hour
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  /// Format percentage: 0.12 → "+12%"
  static String percentage(double value) {
    final percent = (value * 100).round();
    if (percent >= 0) {
      return '+$percent%';
    }
    return '$percent%';
  }

  /// Format duration in hours: 8.5 → "8.5 Jam"
  static String hours(double hours) {
    if (hours == hours.roundToDouble()) {
      return '${hours.round()} Jam';
    }
    return '${hours.toStringAsFixed(1)} Jam';
  }

  /// Format NIK with spaces for readability: 3201234567890001 → "3201 2345 6789 0001"
  static String nik(String nik) {
    final cleaned = nik.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length == 16) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8, 12)} ${cleaned.substring(12)}';
    }
    return cleaned;
  }

  /// Format number with thousand separator: 247500 → "247.500"
  static String number(int number) {
    return NumberFormat('#,###', 'id_ID').format(number).replaceAll(',', '.');
  }

  /// Relative time: "2 jam lalu", "Kemarin", etc.
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} minggu lalu';
    return date(dateTime);
  }
}
