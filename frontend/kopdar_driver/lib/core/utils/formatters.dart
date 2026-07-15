import 'package:intl/intl.dart';

import '../../config/constants.dart';

class Formatters {
  Formatters._();

  static const _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const _dayNames = <String>[
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: AppConstants.locale,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactCurrencyFormat =
      NumberFormat.compactCurrency(
    locale: AppConstants.locale,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static String currency(int amount) => _currencyFormat.format(amount);

  static String currencyWithSign(int amount) {
    if (amount >= 0) return '+${_currencyFormat.format(amount)}';
    return '-${_currencyFormat.format(amount.abs())}';
  }

  static String currencyCompact(int amount) =>
      _compactCurrencyFormat.format(amount);

  static String phone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-+]'), '');
    var normalized = cleaned;
    if (normalized.startsWith('628')) {
      normalized = '0${normalized.substring(2)}';
    }

    if (normalized.length >= 12) {
      return '${normalized.substring(0, 4)}-${normalized.substring(4, 8)}-${normalized.substring(8)}';
    }
    if (normalized.length >= 8) {
      return '${normalized.substring(0, 4)}-${normalized.substring(4)}';
    }
    return normalized;
  }

  static String date(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    return '$day ${_monthNames[local.month - 1]} ${local.year}';
  }

  static String dateTime(DateTime value) => '${date(value)} ${time(value)}';

  static String time(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String dayName(DateTime value) {
    final local = value.toLocal();
    return _dayNames[local.weekday - 1];
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  static String percentage(double value) {
    final percent = (value * 100).round();
    return percent >= 0 ? '+$percent%' : '$percent%';
  }

  static String hours(double value) {
    if (value == value.roundToDouble()) return '${value.round()} Jam';
    return '${value.toStringAsFixed(1)} Jam';
  }

  static String nik(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length == 16) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8, 12)} ${cleaned.substring(12)}';
    }
    return cleaned;
  }

  static String number(int value) =>
      NumberFormat('#,###', 'id_ID').format(value).replaceAll(',', '.');

  static String relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.isNegative || diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} minggu lalu';
    return date(dateTime);
  }
}
