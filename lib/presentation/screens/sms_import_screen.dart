import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';
import '../../data/repositories/sms_repository.dart';
import '../providers/app_state.dart';

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
  PermissionStatus _smsPermission = PermissionStatus.denied;
  List<ParsedSmsResult> _pastePreviews = [];
  List<SmsImportRecord> _auditHistory = [];

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
    setState(() {
      _smsPermission = status;
    });
  }

  Future<void> _loadAuditHistory() async {
    final list = await SmsRepository().getRecentImports(limit: 50);
    setState(() {
      _auditHistory = list;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    setState(() {
      _smsPermission = status;
    });
    if (status.isPermanentlyDenied) {
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

  Widget _buildInboxTab(BuildContext context) {
    final theme = Theme.of(context);
    final isGranted = _smsPermission.isGranted;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Privacy Notice Card
        Card(
          color: AppColors.primary.withValues(alpha: 0.08),
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
                        'PesaTrack parses M-Pesa confirmation SMS entirely on your device. '
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SMS Access Permission',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

    setState(() => _isImporting = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scanned messages: ${result.totalScanned}'),
              const SizedBox(height: 4),
              Text('Imported transactions: ${result.successfullyImported}'),
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

  Widget _buildPasteTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Paste M-Pesa SMS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        const Text(
          'Paste one or multiple M-Pesa confirmation messages below. You can preview the extracted values before committing.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pasteController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Paste SMS here (e.g. QA12BC34DE Confirmed. Ksh1,500.00 sent to JANE DOE...)',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _previewPastedText,
                child: const Text('Preview Parse'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _pastePreviews.isNotEmpty
                    ? _commitPastedBatch
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Commit to Database'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Preview Results List
        if (_pastePreviews.isNotEmpty) ...[
          const Text(
            'Parsed Previews:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._pastePreviews.map((p) {
            final isSuccess = p.isMpesa && p.amountCents > 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                title: Text(
                  isSuccess
                      ? '${p.transactionType.displayName}: KSh ${(p.amountCents / 100).toStringAsFixed(2)}'
                      : 'Unrecognized / Invalid',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isSuccess
                      ? 'Ref: ${p.mpesaReference ?? "N/A"} • ${p.counterpartyName ?? p.description ?? ""}'
                      : p.failureReason ?? 'Format error',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _previewPastedText() {
    final text = _pasteController.text.trim();
    if (text.isEmpty) return;

    final list = MpesaParser().parse(text); // parse single or batch
    setState(() {
      _pastePreviews = [list];
    });
  }

  Future<void> _commitPastedBatch() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) return;

    final count = await widget.appState.importPastedSms(text);
    _pasteController.clear();
    setState(() {
      _pastePreviews = [];
    });
    await _loadAuditHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully committed $count transactions.')),
      );
    }
  }

  Widget _buildAuditTab(BuildContext context) {
    if (_auditHistory.isEmpty) {
      return const Center(child: Text('No SMS import history recorded yet.'));
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
