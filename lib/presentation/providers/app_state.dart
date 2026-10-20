import 'package:flutter/material.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../data/datasources/database_helper.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/services/sms_import_service.dart';

class AppState extends ChangeNotifier {
  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;
  final BudgetRepository _budgetRepo;
  final SmsImportService _smsService;

  List<TransactionModel> _allTransactions = [];
  List<CategoryModel> _categories = [];
  List<BudgetModel> _budgets = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // User Profile State
  String _userName = 'Kurui';
  String get userName => _userName;

  int _avatarIndex = 0;
  int get avatarIndex => _avatarIndex;

  // Search & Filter State
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  DateTime? _filterStartDate;
  DateTime? get filterStartDate => _filterStartDate;

  DateTime? _filterEndDate;
  DateTime? get filterEndDate => _filterEndDate;

  FinancialClassification? _filterClassification;
  FinancialClassification? get filterClassification => _filterClassification;

  String? _filterCategoryId;
  String? get filterCategoryId => _filterCategoryId;

  String _sortOrder = 'newest'; // newest, oldest, highest, lowest
  String get sortOrder => _sortOrder;

  // --- Memoization Caches for High-Performance 60/120fps UI Rendering ---
  List<TransactionModel>? _cachedFilteredTransactions;
  FinancialSummary? _cachedTodaySummary;
  FinancialSummary? _cachedWeekSummary;
  FinancialSummary? _cachedMonthSummary;
  List<BudgetStatus>? _cachedBudgetStatuses;
  final Map<int, List<CategorySpending>> _cachedPeriodBreakdowns = {};
  List<CategorySpending>? _cachedMonthlyCategoryBreakdown;
  TransactionModel? _cachedLatestMpesaBalanceTransaction;
  bool _hasCheckedLatestMpesaBalance = false;
  double? _cachedEstimatedBalance;
  List<MerchantSpending>? _cachedTopMerchants;

  void _invalidateAllCaches() {
    _cachedFilteredTransactions = null;
    _cachedTodaySummary = null;
    _cachedWeekSummary = null;
    _cachedMonthSummary = null;
    _cachedBudgetStatuses = null;
    _cachedPeriodBreakdowns.clear();
    _cachedMonthlyCategoryBreakdown = null;
    _cachedLatestMpesaBalanceTransaction = null;
    _hasCheckedLatestMpesaBalance = false;
    _cachedEstimatedBalance = null;
    _cachedTopMerchants = null;
  }

  void _invalidateFilterCache() {
    _cachedFilteredTransactions = null;
  }

  AppState({
    TransactionRepository? txRepo,
    CategoryRepository? catRepo,
    BudgetRepository? budgetRepo,
    SmsImportService? smsService,
  }) : _txRepo = txRepo ?? TransactionRepository(),
       _catRepo = catRepo ?? CategoryRepository(),
       _budgetRepo = budgetRepo ?? BudgetRepository(),
       _smsService = smsService ?? SmsImportService() {
    _listenToIncomingSms();
    loadInitialData();
  }

  void _listenToIncomingSms() {
    _smsService.onNewTransaction.listen((tx) {
      _allTransactions.insert(0, tx);
      _invalidateAllCaches();
      notifyListeners();
    });
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _catRepo.getAllCategories();
      _budgets = await _budgetRepo.getAllBudgets();
      _allTransactions = await _txRepo.getAllTransactions();

      // Load profile preferences
      final savedName = await DatabaseHelper.instance.getPreference('user_name');
      if (savedName != null && savedName.trim().isNotEmpty) {
        _userName = savedName.trim();
      }
      final savedAvatar =
          await DatabaseHelper.instance.getPreference('avatar_index');
      if (savedAvatar != null) {
        _avatarIndex = int.tryParse(savedAvatar) ?? 0;
      }

      // Check for any SMS received while app was closed
      await _smsService.processPendingBackgroundMessages();
      _allTransactions = await _txRepo.getAllTransactions();
    } catch (_) {}

    _invalidateAllCaches();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name.trim().isEmpty ? 'Kurui' : name.trim();
    await DatabaseHelper.instance.setPreference('user_name', _userName);
    notifyListeners();
  }

  Future<void> setAvatarIndex(int index) async {
    _avatarIndex = index;
    await DatabaseHelper.instance.setPreference('avatar_index', index.toString());
    notifyListeners();
  }

  List<TransactionModel> get allTransactions =>
      List.unmodifiable(_allTransactions);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<BudgetModel> get budgets => List.unmodifiable(_budgets);

  /// Filtered list of transactions based on active search, filters, and sort.
  List<TransactionModel> get filteredTransactions {
    if (_cachedFilteredTransactions != null) {
      return _cachedFilteredTransactions!;
    }

    final list = _allTransactions.where((tx) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = (tx.counterpartyName ?? '').toLowerCase().contains(
          query,
        );
        final matchDesc = (tx.description ?? '').toLowerCase().contains(query);
        final matchRef = (tx.mpesaReference ?? '').toLowerCase().contains(
          query,
        );
        final matchAcc = (tx.accountReference ?? '').toLowerCase().contains(
          query,
        );
        if (!matchName && !matchDesc && !matchRef && !matchAcc) return false;
      }

      if (_filterStartDate != null &&
          tx.timestamp.isBefore(_filterStartDate!)) {
        return false;
      }

      if (_filterEndDate != null && tx.timestamp.isAfter(_filterEndDate!)) {
        return false;
      }

      if (_filterClassification != null &&
          tx.classification != _filterClassification) {
        return false;
      }

      if (_filterCategoryId != null && tx.categoryId != _filterCategoryId) {
        return false;
      }

      return true;
    }).toList();

    switch (_sortOrder) {
      case 'oldest':
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case 'highest':
        list.sort((a, b) => b.amountCents.compareTo(a.amountCents));
        break;
      case 'lowest':
        list.sort((a, b) => a.amountCents.compareTo(b.amountCents));
        break;
      case 'newest':
      default:
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
    }

    return _cachedFilteredTransactions = list;
  }

  // --- Real-time Financial Calculations ---

  /// Summary for Today (00:00 to 23:59).
  FinancialSummary get todaySummary {
    if (_cachedTodaySummary != null) return _cachedTodaySummary!;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return _cachedTodaySummary = FinancialCalculator.calculateSummary(
      _allTransactions,
      startDate: start,
      endDate: end,
    );
  }

  /// Summary for This Week (Monday to Sunday).
  FinancialSummary get weekSummary {
    if (_cachedWeekSummary != null) return _cachedWeekSummary!;
    final bounds = BudgetCalculator.getPeriodBounds(
      BudgetPeriod.weekly,
      DateTime.now(),
    );
    return _cachedWeekSummary = FinancialCalculator.calculateSummary(
      _allTransactions,
      startDate: bounds.start,
      endDate: bounds.end,
    );
  }

  /// Summary for This Month (1st to last day of month).
  FinancialSummary get monthSummary {
    if (_cachedMonthSummary != null) return _cachedMonthSummary!;
    final bounds = BudgetCalculator.getPeriodBounds(
      BudgetPeriod.monthly,
      DateTime.now(),
    );
    return _cachedMonthSummary = FinancialCalculator.calculateSummary(
      _allTransactions,
      startDate: bounds.start,
      endDate: bounds.end,
    );
  }

  /// List of active budget statuses evaluated against current spending.
  List<BudgetStatus> get budgetStatuses {
    if (_cachedBudgetStatuses != null) return _cachedBudgetStatuses!;
    return _cachedBudgetStatuses = _budgets
        .where((b) => b.isActive)
        .map((b) => BudgetCalculator.evaluateBudget(b, _allTransactions))
        .toList();
  }

  /// Category breakdown for the active month.
  List<CategorySpending> get monthlyCategoryBreakdown {
    if (_cachedMonthlyCategoryBreakdown != null) {
      return _cachedMonthlyCategoryBreakdown!;
    }
    final bounds = BudgetCalculator.getPeriodBounds(
      BudgetPeriod.monthly,
      DateTime.now(),
    );
    return _cachedMonthlyCategoryBreakdown =
        FinancialCalculator.calculateCategoryBreakdown(
      _allTransactions,
      startDate: bounds.start,
      endDate: bounds.end,
    );
  }

  /// Category breakdown dynamically evaluated for period index (0: Today, 1: Week, 2: Month)
  List<CategorySpending> categoryBreakdownForPeriod(int periodIndex) {
    if (_cachedPeriodBreakdowns.containsKey(periodIndex)) {
      return _cachedPeriodBreakdowns[periodIndex]!;
    }

    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (periodIndex == 0) {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    } else if (periodIndex == 1) {
      final bounds = BudgetCalculator.getPeriodBounds(BudgetPeriod.weekly, now);
      start = bounds.start;
      end = bounds.end;
    } else {
      final bounds = BudgetCalculator.getPeriodBounds(BudgetPeriod.monthly, now);
      start = bounds.start;
      end = bounds.end;
    }

    final result = FinancialCalculator.calculateCategoryBreakdown(
      _allTransactions,
      startDate: start,
      endDate: end,
    );
    _cachedPeriodBreakdowns[periodIndex] = result;
    return result;
  }

  /// Most recent transaction with an explicit M-Pesa account balance recorded.
  TransactionModel? get latestMpesaBalanceTransaction {
    if (_hasCheckedLatestMpesaBalance) {
      return _cachedLatestMpesaBalanceTransaction;
    }
    _hasCheckedLatestMpesaBalance = true;
    for (final tx in _allTransactions) {
      if (tx.balanceAfterCents != null) {
        return _cachedLatestMpesaBalanceTransaction = tx;
      }
    }
    return _cachedLatestMpesaBalanceTransaction = null;
  }

  /// Estimated current wallet balance (explicit M-Pesa balance, or calculated net cash flow)
  double get currentEstimatedBalance {
    if (_cachedEstimatedBalance != null) return _cachedEstimatedBalance!;
    final latest = latestMpesaBalanceTransaction;
    if (latest != null && latest.balanceAfterCents != null) {
      return _cachedEstimatedBalance = latest.balanceAfterCents! / 100.0;
    }
    int total = 0;
    for (final tx in _allTransactions) {
      if (tx.classification == FinancialClassification.income ||
          tx.classification == FinancialClassification.adjustment) {
        total += tx.amountCents;
      } else {
        total -= tx.totalOutgoingCents;
      }
    }
    return _cachedEstimatedBalance = total / 100.0;
  }

  /// Top merchants for the active month.
  List<MerchantSpending> get topMerchants {
    if (_cachedTopMerchants != null) return _cachedTopMerchants!;
    final bounds = BudgetCalculator.getPeriodBounds(
      BudgetPeriod.monthly,
      DateTime.now(),
    );
    final txs = _allTransactions
        .where(
          (tx) =>
              !tx.timestamp.isBefore(bounds.start) &&
              !tx.timestamp.isAfter(bounds.end),
        )
        .toList();
    return _cachedTopMerchants = FinancialCalculator.findTopMerchants(txs);
  }

  // --- Filter Actions ---

  void setSearchQuery(String query) {
    _searchQuery = query;
    _invalidateFilterCache();
    notifyListeners();
  }

  void setFilterClassification(FinancialClassification? classification) {
    _filterClassification = classification;
    _invalidateFilterCache();
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    _invalidateFilterCache();
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    _invalidateFilterCache();
    notifyListeners();
  }

  void setSortOrder(String order) {
    _sortOrder = order;
    _invalidateFilterCache();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterStartDate = null;
    _filterEndDate = null;
    _filterClassification = null;
    _filterCategoryId = null;
    _sortOrder = 'newest';
    _invalidateFilterCache();
    notifyListeners();
  }

  // --- Transaction Actions ---

  Future<bool> addManualTransaction({
    required int amountCents,
    required TransactionType type,
    required FinancialClassification classification,
    required String categoryId,
    required String categoryName,
    DateTime? timestamp,
    String? counterpartyName,
    String? counterpartyPhone,
    String? description,
  }) async {
    final txTime = timestamp ?? DateTime.now();
    final fp = DeduplicationService.generateFingerprint(
      amountCents: amountCents,
      timestamp: txTime,
      counterparty: counterpartyName,
      type: type,
    );

    final tx = TransactionModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      transactionType: type,
      classification: classification,
      amountCents: amountCents,
      feeCents: 0,
      timestamp: txTime,
      counterpartyName: counterpartyName,
      counterpartyPhone: counterpartyPhone,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      source: TransactionSource.manual,
      fingerprint: fp,
      reviewStatus: ReviewStatus.verified,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final inserted = await _txRepo.insertTransaction(tx);
    if (inserted) {
      _allTransactions.insert(0, tx);
      _invalidateAllCaches();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> updateTransaction(TransactionModel updated) async {
    await _txRepo.updateTransaction(updated);
    final index = _allTransactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _allTransactions[index] = updated;
      _invalidateAllCaches();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _txRepo.deleteTransaction(id);
    _allTransactions.removeWhere((t) => t.id == id);
    _invalidateAllCaches();
    notifyListeners();
  }

  // --- Budget Actions ---

  Future<void> saveBudget(BudgetModel budget) async {
    await _budgetRepo.saveBudget(budget);
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _budgets[index] = budget;
    } else {
      _budgets.add(budget);
    }
    _invalidateAllCaches();
    notifyListeners();
  }

  Future<void> deleteBudget(String id) async {
    await _budgetRepo.deleteBudget(id);
    _budgets.removeWhere((b) => b.id == id);
    _invalidateAllCaches();
    notifyListeners();
  }

  // --- SMS Ingestion Actions ---

  Future<ImportBatchResult> importFromInbox({
    int limit = 200,
    DateTime? since,
  }) async {
    final result = await _smsService.importFromDeviceInbox(
      limit: limit,
      sinceDate: since,
    );
    _allTransactions = await _txRepo.getAllTransactions();
    _invalidateAllCaches();
    notifyListeners();
    return result;
  }

  Future<int> importPastedSms(String text) async {
    final previews = _smsService.previewPastedBatch(text);
    int imported = 0;
    for (final p in previews) {
      if (p.isMpesa && p.amountCents > 0) {
        final tx = await _smsService.processSingleMessage(
          p.rawMessage,
          source: TransactionSource.importedSms,
        );
        if (tx != null) {
          _allTransactions.insert(0, tx);
          imported++;
        }
      }
    }
    if (imported > 0) {
      _invalidateAllCaches();
      notifyListeners();
    }
    return imported;
  }

  // --- Backup & Export ---

  String exportToCsv() {
    return CsvExporter.exportTransactionsToCsv(_allTransactions);
  }

  String createBackupJson() {
    return BackupCodec.encode(
      transactions: _allTransactions,
      categories: _categories,
      budgets: _budgets,
    );
  }

  Future<void> restoreFromBackup(String jsonString) async {
    final payload = BackupCodec.decode(jsonString);
    await _txRepo.insertBatch(payload.transactions);
    for (final cat in payload.categories) {
      await _catRepo.insertCategory(cat);
    }
    for (final b in payload.budgets) {
      await _budgetRepo.saveBudget(b);
    }
    await loadInitialData();
  }

  Future<void> clearAllData() async {
    await DatabaseHelper.instance.clearAllUserData();
    _allTransactions.clear();
    _budgets.clear();
    _invalidateAllCaches();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
