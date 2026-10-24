import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';
import '../../data/repositories/sms_repository.dart';
import '../providers/app_state.dart';
import '../widgets/sms_batch_review_card.dart';

class SmsImportScreen extends StatefulWidget {
  final AppState appState;

  const SmsImportScreen({super.key, required this.appState});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pasteController = TextEditingController();

  bool _isImporting = false;
  bool _isCommitting = false;
  PermissionStatus _smsPermission = PermissionStatus.denied;
  List<SmsBatchReviewItem> _reviewItems = [];
  List<SmsImportRecord> _auditHistory = [];

  // M-Pesa Realistic Samples for Instant Testing
  static const Map<String, String> _samples = {
    'PayBill':
        'QA89TY45OP Confirmed. Ksh3,500.00 sent to SAFARICOM HOME FIBRE for account 12345678 on 24/10/26 at 5:12 PM. New M-PESA balance is Ksh15,420.00. Transaction cost, Ksh23.00.',
    'Buy Goods':
        'QB12CD34EF Confirmed. Ksh1,850.00 paid to NAIVAS KILIMANI on 24/10/26 at 2:30 PM. New M-PESA balance is Ksh13,570.00. Transaction cost, Ksh0.00.',
    'Send Money':
        'QC34EF56GH Confirmed. Ksh500.00 sent to JANE WAMBUI 0712345678 on 24/10/26 at 11:15 AM. New M-PESA balance is Ksh13,070.00. Transaction cost, Ksh7.00.',
    'Receive Money':
        'QD56GH78IJ Confirmed. You have received Ksh5,000.00 from JOHN MWANGI 0722000000 on 24/10/26 at 9:00 AM. New M-PESA balance is Ksh18,070.00.',
    'Batch (3x)':
        'QA89TY45OP Confirmed. Ksh3,500.00 sent to SAFARICOM HOME FIBRE for account 12345678 on 24/10/26 at 5:12 PM. New M-PESA balance is Ksh15,420.00. Transaction cost, Ksh23.00.\n\nQB12CD34EF Confirmed. Ksh1,850.00 paid to NAIVAS KILIMANI on 24/10/26 at 2:30 PM. New M-PESA balance is Ksh13,570.00. Transaction cost, Ksh0.00.\n\nQD56GH78IJ Confirmed. You have received Ksh5,000.00 from JOHN MWANGI 0722000000 on 24/10/26 at 9:00 AM. New M-PESA balance is Ksh18,070.00.',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPermissionStatus();
    _loadAuditHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.sms.status;
    if (mounted) {
      setState(() {
        _smsPermission = status;
      });
    }
  }

  Future<void> _loadAuditHistory() async {
    final list = await SmsRepository().getRecentImports(limit: 50);
    if (mounted) {
      setState(() {
        _auditHistory = list;
      });
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    if (mounted) {
      setState(() {
        _smsPermission = status;
      });
    }
    if (status.isPermanentlyDenied && mounted) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SMS Permission Required'),
        content: const Text(
          'Android requires SMS permission to automatically detect and import your M-Pesa transactions. '
          'You can enable this in Android App Settings, or continue using the Manual Paste fallback.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Pesa SMS Ingestion'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Device Inbox'),
            Tab(text: 'Manual Paste'),
            Tab(text: 'Audit Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInboxTab(context),
          _buildPasteTab(context),
          _buildAuditTab(context),
        ],
      ),
    );
  }

  // --- TAB 1: DEVICE INBOX ---

  Widget _buildInboxTab(BuildContext context) {
    final theme = Theme.of(context);
    final isGranted = _smsPermission.isGranted;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Privacy Notice Card
        Card(
          color: AppColors.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Offline & Private',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'GanjiPal parses M-Pesa confirmation SMS entirely on your device. '
                        'No message content or transaction details are ever sent to remote servers or third parties.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Permission Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'SMS Access Permission',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isGranted
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGranted ? 'Enabled' : 'Disabled',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isGranted
                              ? Colors.green[800]
                              : Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isGranted
                      ? 'Automatic SMS detection is active. New M-Pesa receipts will be captured as they arrive.'
                      : 'Permission is needed to read confirmation SMS from Safaricom M-Pesa.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                if (!isGranted)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.security, size: 18),
                      label: const Text('Grant SMS Permission'),
                      onPressed: _requestPermission,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Historical Import Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Past M-Pesa Messages',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Scans your inbox for past confirmation messages, extracts financial records, and skips duplicates automatically.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _isImporting
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Scanning inbox and parsing messages...'),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Scan & Import Device SMS'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _runInboxImport,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _runInboxImport() async {
    setState(() => _isImporting = true);

    final result = await widget.appState.importFromInbox(limit: 200);
    await _loadAuditHistory();

    if (mounted) {
      setState(() => _isImporting = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Import Complete'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scanned messages: ${result.totalScanned}'),
                const SizedBox(height: 4),
                Text(
                  'Imported transactions: ${result.successfullyImported}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Duplicates skipped: ${result.duplicatesSkipped}'),
                const SizedBox(height: 4),
                Text('Unrecognized: ${result.unrecognizedSkipped}'),
                if (result.errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Errors:\n${result.errors.join('\n')}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // --- TAB 2: MANUAL PASTE & BATCH REVIEW CARD ---

  Widget _buildPasteTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    final validSelectedItems =
        _reviewItems.where((i) => i.isSelected && i.isValid).toList();
    final selectedCount = validSelectedItems.length;
    final int selectedTotalCents = validSelectedItems.fold(
      0,
      (sum, item) => sum + item.parsed.amountCents,
    );

    final allSelected = _reviewItems.isNotEmpty &&
        _reviewItems.every((i) => !i.isValid || i.isSelected);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Input Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Paste M-Pesa SMS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton.icon(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste_rounded, size: 16),
              label: const Text('Paste Clipboard', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),

        const SizedBox(height: 4),
        const Text(
          'Paste single or multiple M-Pesa SMS messages below. Review amounts, counterparties, and categories before committing.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),

        const SizedBox(height: 10),

        // Quick Sample Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Samples: ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
              ..._samples.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ActionChip(
                    label: Text(entry.key, style: const TextStyle(fontSize: 11)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _insertSample(entry.value),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // SMS Paste Text Area
        TextField(
          controller: _pasteController,
          maxLines: 5,
          style: const TextStyle(fontSize: 13, height: 1.4),
          decoration: InputDecoration(
            hintText:
                'Paste SMS here (e.g. QA12BC34DE Confirmed. Ksh1,500.00 sent to JANE DOE...)\n\nMultiple messages separated by blank lines are supported.',
            hintStyle: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            filled: true,
            fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            suffixIcon: _pasteController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _pasteController.clear();
                      setState(() {
                        _reviewItems = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: (_) {
            if (_reviewItems.isNotEmpty) {
              setState(() {
                _reviewItems = [];
              });
            }
          },
        ),

        const SizedBox(height: 12),

        // Action Buttons: Parse & Clear
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Parse & Preview'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _previewPastedText,
              ),
            ),
            if (_reviewItems.isNotEmpty) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _pasteController.clear();
                  setState(() {
                    _reviewItems = [];
                  });
                },
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // BATCH REVIEW SECTION
        if (_reviewItems.isNotEmpty) ...[
          // Batch Summary Card & Select All Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$selectedCount of ${_reviewItems.length} selected for commit',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: KSh ${currencyFormat.format(selectedTotalCents / 100.0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      final targetState = !allSelected;
                      for (final item in _reviewItems) {
                        if (item.isValid) {
                          item.isSelected = targetState;
                        }
                      }
                    });
                  },
                  child: Text(allSelected ? 'Deselect All' : 'Select All'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // List of Batch Review Cards
          ..._reviewItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return SmsBatchReviewCard(
              key: ValueKey(item.id),
              item: item,
              onToggleSelected: (val) {
                setState(() {
                  item.isSelected = val ?? false;
                });
              },
              onSelectCategory: () => _showCategoryPickerModal(item),
              onToggleExpand: () {
                setState(() {
                  item.isExpanded = !item.isExpanded;
                });
              },
              onDelete: () {
                setState(() {
                  _reviewItems.removeAt(index);
                });
              },
            );
          }),

          const SizedBox(height: 16),

          // Big Primary Commit Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _isCommitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                _isCommitting
                    ? 'Writing to SQLite Ledger...'
                    : 'Commit $selectedCount Transactions (KSh ${currencyFormat.format(selectedTotalCents / 100.0)})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: (_isCommitting || selectedCount == 0)
                  ? null
                  : _commitReviewedBatch,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  // Parses pasted content into a batch of review items
  void _previewPastedText() {
    final text = _pasteController.text.trim();
    if (text.isEmpty) return;

    final segments = widget.appState.smsService.splitMultipleMessages(text);
    final List<SmsBatchReviewItem> items = [];

    for (int i = 0; i < segments.length; i++) {
      final raw = segments[i];
      final parsed = widget.appState.parser.parse(raw);
      final categoryId = widget.appState.classifier.suggestCategory(parsed);
      final categoryName =
          widget.appState.classifier.getCategoryName(categoryId);

      // Duplicate detection against existing SQLite transactions
      final txTimestamp = parsed.timestamp ?? DateTime.now();
      final fp = DeduplicationService.generateFingerprint(
        mpesaReference: parsed.mpesaReference,
        amountCents: parsed.amountCents,
        timestamp: txTimestamp,
        counterparty: parsed.counterpartyName,
        type: parsed.transactionType,
        accountReference: parsed.accountReference,
      );

      final isDup =
          widget.appState.allTransactions.any((t) => t.fingerprint == fp);

      items.add(
        SmsBatchReviewItem(
          id: '$i-${DateTime.now().microsecondsSinceEpoch}',
          parsed: parsed,
          isSelected: !isDup && parsed.isMpesa && parsed.amountCents > 0,
          categoryId: categoryId,
          categoryName: categoryName,
          isDuplicate: isDup,
        ),
      );
    }

    setState(() {
      _reviewItems = items;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Parsed ${items.length} ${items.length == 1 ? "message" : "messages"}. Review details below.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Inserts a sample text and immediately previews
  void _insertSample(String sampleText) {
    _pasteController.text = sampleText;
    _previewPastedText();
  }

  // Pastes text directly from system clipboard
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _pasteController.text = text;
      _previewPastedText();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty or does not contain text.'),
          ),
        );
      }
    }
  }

  // Opens interactive bottom modal sheet to select or change category
  void _showCategoryPickerModal(SmsBatchReviewItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final categories = widget.appState.categories;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    final isCurrent = cat.id == item.categoryId;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            Color(cat.colorValue).withValues(alpha: 0.2),
                        child: Icon(
                          _getCategoryIcon(cat.iconName),
                          size: 16,
                          color: Color(cat.colorValue),
                        ),
                      ),
                      title: Text(
                        cat.name,
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? AppColors.primary : null,
                        ),
                      ),
                      trailing: isCurrent
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          item.categoryId = cat.id;
                          item.categoryName = cat.name;
                        });
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'shopping_basket':
        return Icons.shopping_basket_rounded;
      case 'directions_bus':
        return Icons.directions_bus_rounded;
      case 'receipt_long':
        return Icons.receipt_long_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // Commits the reviewed batch to SQLite
  Future<void> _commitReviewedBatch() async {
    setState(() => _isCommitting = true);

    try {
      final count = await widget.appState.commitReviewedBatch(_reviewItems);
      _pasteController.clear();
      setState(() {
        _reviewItems = [];
        _isCommitting = false;
      });
      await _loadAuditHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[800],
            content: Text(
              'Successfully committed $count transactions to your ledger!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(); // Back to main screen
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCommitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[800],
            content: Text('Failed to commit batch: $e'),
          ),
        );
      }
    }
  }

  // --- TAB 3: AUDIT LOG ---

  Widget _buildAuditTab(BuildContext context) {
    if (_auditHistory.isEmpty) {
      return const Center(
        child: Text(
          'No SMS import history recorded yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, h:mm a');

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _auditHistory.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _auditHistory[index];
        final isSuccess = item.status == SmsImportStatus.success;
        final isDup = item.status == SmsImportStatus.duplicate;

        return ListTile(
          leading: Icon(
            isSuccess
                ? Icons.check_circle_outline
                : isDup
                    ? Icons.copy_outlined
                    : Icons.warning_amber_rounded,
            color: isSuccess
                ? Colors.green
                : isDup
                    ? Colors.blueGrey
                    : Colors.amber[800],
          ),
          title: Text(
            item.status.displayName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            'Ref: ${item.mpesaReference ?? "N/A"}${item.errorMessage != null ? " • ${item.errorMessage}" : ""}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            dateFormat.format(item.importedAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        );
      },
    );
  }
}
