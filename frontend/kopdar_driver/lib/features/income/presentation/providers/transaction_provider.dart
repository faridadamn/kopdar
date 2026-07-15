import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/datasources/transaction_remote_ds.dart';

enum TransactionStatus { initial, loading, loaded, error }
enum TransactionFilter { today, thisWeek, thisMonth }

class TransactionProvider extends ChangeNotifier {
  final TransactionRemoteDataSource _dataSource;

  TransactionProvider({TransactionRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? TransactionRemoteDataSource();

  // ── State ──
  TransactionStatus _status = TransactionStatus.initial;
  TransactionStatus _summaryStatus = TransactionStatus.initial;
  List<TransactionModel> _transactions = [];
  Map<String, dynamic>? _summary;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // ── Filters ──
  String? _typeFilter; // 'income' or 'expense'
  String? _platformFilter;
  TransactionFilter _periodFilter = TransactionFilter.today;

  // ── Getters ──
  TransactionStatus get status => _status;
  TransactionStatus get summaryStatus => _summaryStatus;
  List<TransactionModel> get transactions => _transactions;
  Map<String, dynamic>? get summary => _summary;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == TransactionStatus.loading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get typeFilter => _typeFilter;
  String? get platformFilter => _platformFilter;
  TransactionFilter get periodFilter => _periodFilter;

  // ── Derived ──
  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.netAmount);

  double get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (sum, t) => sum + t.amount);

  double get profit => totalIncome - totalExpense;

  /// Date range based on current period filter.
  (DateTime, DateTime) get _dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_periodFilter) {
      case TransactionFilter.today:
        return (today, today.add(const Duration(days: 1)));
      case TransactionFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (weekStart, weekStart.add(const Duration(days: 7)));
      case TransactionFilter.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        return (monthStart, monthEnd);
    }
  }

  // ── Actions ──

  void setTypeFilter(String? type) {
    _typeFilter = type;
    notifyListeners();
    fetchTransactions(refresh: true);
  }

  void setPlatformFilter(String? platform) {
    _platformFilter = platform;
    notifyListeners();
    fetchTransactions(refresh: true);
  }

  void setPeriodFilter(TransactionFilter filter) {
    _periodFilter = filter;
    notifyListeners();
    fetchTransactions(refresh: true);
  }

  /// Fetch transactions with current filters.
  Future<void> fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _transactions = [];
    }

    _status = TransactionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final (dateFrom, dateTo) = _dateRange;
      final result = await _dataSource.getTransactions(
        type: _typeFilter,
        platform: _platformFilter == 'Semua' ? null : _platformFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: _currentPage,
        limit: 20,
      );

      if (refresh) {
        _transactions = result;
      } else {
        _transactions.addAll(result);
      }

      _hasMore = result.length >= 20;
      _status = TransactionStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = TransactionStatus.error;
      _errorMessage = 'Gagal memuat transaksi. Coba lagi.';
      notifyListeners();
    }
  }

  /// Load next page of transactions.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      final (dateFrom, dateTo) = _dateRange;
      final result = await _dataSource.getTransactions(
        type: _typeFilter,
        platform: _platformFilter == 'Semua' ? null : _platformFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: _currentPage,
        limit: 20,
      );

      _transactions.addAll(result);
      _hasMore = result.length >= 20;
    } catch (e) {
      _currentPage--;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Fetch financial summary.
  Future<void> fetchSummary(String period) async {
    _summaryStatus = TransactionStatus.loading;
    notifyListeners();

    try {
      _summary = await _dataSource.getSummary(period);
      _summaryStatus = TransactionStatus.loaded;
      notifyListeners();
    } catch (e) {
      _summaryStatus = TransactionStatus.error;
      notifyListeners();
    }
  }

  /// Create a new income transaction with optimistic update.
  Future<bool> createTransaction({
    required String type,
    required String category,
    String? platform,
    required double amount,
    double commission = 0,
    String? notes,
    String? receiptUrl,
    int orderCount = 1,
  }) async {
    try {
      final tx = await _dataSource.createTransaction(
        type: type,
        category: category,
        platform: platform,
        amount: amount,
        commission: commission,
        notes: notes,
        receiptUrl: receiptUrl,
        orderCount: orderCount,
      );

      // Add to local list if it matches current filter
      if (_typeFilter == null || _typeFilter == type) {
        _transactions.insert(0, tx);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan transaksi.';
      notifyListeners();
      return false;
    }
  }

  /// Update a transaction.
  Future<bool> updateTransaction(
    String id, {
    String? category,
    String? platform,
    double? amount,
    double? commission,
    String? notes,
    String? receiptUrl,
    int? orderCount,
  }) async {
    try {
      final updated = await _dataSource.updateTransaction(
        id,
        category: category,
        platform: platform,
        amount: amount,
        commission: commission,
        notes: notes,
        receiptUrl: receiptUrl,
        orderCount: orderCount,
      );

      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        _transactions[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui transaksi.';
      notifyListeners();
      return false;
    }
  }

  /// Delete a transaction with optimistic update.
  Future<bool> deleteTransaction(String id) async {
    // Optimistic: remove from local list
    final index = _transactions.indexWhere((t) => t.id == id);
    TransactionModel? removed;
    if (index != -1) {
      removed = _transactions.removeAt(index);
      notifyListeners();
    }

    try {
      await _dataSource.deleteTransaction(id);
      return true;
    } catch (e) {
      // Rollback optimistic update
      if (removed != null && index != -1) {
        _transactions.insert(index, removed);
        notifyListeners();
      }
      _errorMessage = 'Gagal menghapus transaksi.';
      notifyListeners();
      return false;
    }
  }
}
