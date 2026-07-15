import 'package:flutter/material.dart';
import '../../data/models/transaction_item.dart';

class DailySummary {
  final int income;
  final int orderCount;
  final double hours;
  final int avgPerOrder;
  final double changePercent;

  const DailySummary({
    required this.income,
    required this.orderCount,
    required this.hours,
    required this.avgPerOrder,
    required this.changePercent,
  });
}

class DanaDarurat {
  final int currentAmount;
  final int targetAmount;
  final int dailyAmount;

  const DanaDarurat({
    required this.currentAmount,
    required this.targetAmount,
    required this.dailyAmount,
  });

  double get progress =>
      targetAmount > 0 ? currentAmount / targetAmount : 0;

  int get daysRemaining {
    final remaining = targetAmount - currentAmount;
    if (remaining <= 0 || dailyAmount <= 0) return 0;
    return (remaining / dailyAmount).ceil();
  }

  bool get isOnTrack => progress >= 0.3;
}

enum DashboardStatus { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardStatus _status = DashboardStatus.initial;
  DailySummary? _dailySummary;
  List<TransactionItem> _recentTransactions = [];
  String? _alertMessage;
  String _alertType = 'warning';
  DanaDarurat? _danaDarurat;
  String? _errorMessage;

  DashboardStatus get status => _status;
  DailySummary? get dailySummary => _dailySummary;
  List<TransactionItem> get recentTransactions => _recentTransactions;
  String? get alertMessage => _alertMessage;
  String get alertType => _alertType;
  DanaDarurat? get danaDarurat => _danaDarurat;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == DashboardStatus.loading;

  /// Driver display name — in real app fetched from user profile.
  String driverName = 'Budi';

  Future<void> fetchDashboard() async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network latency
      await Future.delayed(const Duration(milliseconds: 800));

      _dailySummary = const DailySummary(
        income: 247500,
        orderCount: 12,
        hours: 8.5,
        avgPerOrder: 20625,
        changePercent: 0.12,
      );

      _recentTransactions = [
        TransactionItem(
          icon: '🟢',
          title: 'GoFood — Order #4521',
          subtitle: '3.2 km · 25 menit',
          amount: 28500,
          isIncome: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        TransactionItem(
          icon: '🟩',
          title: 'GrabExpress — Paket',
          subtitle: '5.1 km · 38 menit',
          amount: 32000,
          isIncome: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        ),
        TransactionItem(
          icon: '⛽',
          title: 'Bensin Pertalite',
          subtitle: 'SPBU Ciputat',
          amount: 50000,
          isIncome: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        TransactionItem(
          icon: '🟠',
          title: 'ShopeeFood — Order #887',
          subtitle: '1.8 km · 15 menit',
          amount: 18500,
          isIncome: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ];

      _alertMessage =
          'Jangan lupa! Angsuran motor jatuh tempo dalam 3 hari. Siapkan Rp 850.000.';
      _alertType = 'warning';

      _danaDarurat = const DanaDarurat(
        currentAmount: 1250000,
        targetAmount: 5000000,
        dailyAmount: 10000,
      );

      _status = DashboardStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = DashboardStatus.error;
      _errorMessage = 'Gagal memuat data. Coba lagi.';
      notifyListeners();
    }
  }

  void dismissAlert() {
    _alertMessage = null;
    notifyListeners();
  }
}
