import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sample_data_seeder.dart';
import '../providers/app_state.dart';
import '../widgets/profile_edit_dialog.dart';

class SettingsScreen extends StatelessWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            children: [
              // Profile Section
              _buildSectionHeader(context, 'Personal Profile'),
              Card(
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: ProfileAvatarHelper.getConfig(
                          appState.avatarIndex,
                        ).gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        appState.userName.isNotEmpty
                            ? appState.userName[0].toUpperCase()
                            : 'K',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    appState.userName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Tap to change nickname or avatar'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          ProfileEditBottomSheet(appState: appState),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Appearance Section
              _buildSectionHeader(context, 'Appearance'),
              Card(
                child: RadioGroup<ThemeMode>(
                  groupValue: appState.themeMode,
                  onChanged: (mode) {
                    if (mode != null) appState.setThemeMode(mode);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text('System Default'),
                        subtitle: Text('Follow Android device appearance'),
                        value: ThemeMode.system,
                      ),
                      Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: Text('Warm Ivory (Light Theme)'),
                        subtitle: Text('Natural, calm daytime appearance'),
                        value: ThemeMode.light,
                      ),
                      Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: Text('Deep Charcoal (Dark Theme)'),
                        subtitle: Text('Restful forest-slate night appearance'),
                        value: ThemeMode.dark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Data Export & Backup Section
              _buildSectionHeader(context, 'Data & Backup'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.table_chart_outlined,
                        color: isDark ? AppColors.sage : AppColors.primary,
                      ),
                      title: const Text('Export to CSV'),
                      subtitle: const Text(
                        'Generate formatted CSV of all transactions',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _handleCsvExport(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.backup_outlined,
                        color: isDark ? AppColors.sage : AppColors.primary,
                      ),
                      title: const Text('Create JSON Backup'),
                      subtitle: const Text(
                        'Full snapshot of transactions and budgets',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _handleCreateBackup(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.restore_outlined,
                        color: isDark ? AppColors.sage : AppColors.primary,
                      ),
                      title: const Text('Restore from Backup'),
                      subtitle: const Text('Import verified JSON backup file'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _handleRestoreBackup(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.data_exploration_outlined,
                        color: isDark ? AppColors.sage : AppColors.primary,
                      ),
                      title: const Text('Seed Sample Transactions'),
                      subtitle: const Text(
                        'Populate 10 realistic M-Pesa transactions for demo',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _handleSeedSampleData(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Privacy & Security Section
              _buildSectionHeader(context, 'Privacy & Security'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: isDark ? AppColors.sage : AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Strict On-Device Privacy',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• All financial transactions and SMS receipts are stored in application-private SQLite storage.\n'
                        '• GanjiPal does not transmit your financial data to any cloud service, external AI, or telemetry platform.\n'
                        '• Deduplication is performed deterministically using local SHA-256 hashing.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Danger Zone
              _buildSectionHeader(context, 'Danger Zone'),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: AppColors.expense,
                  ),
                  title: const Text(
                    'Clear All Financial Records',
                    style: TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Permanently deletes all transactions, budgets, and logs',
                  ),
                  onTap: () => _confirmClearAllData(context),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.sage : AppColors.primary,
            ),
      ),
    );
  }

  void _handleCsvExport(BuildContext context) {
    final csv = appState.exportToCsv();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV copied to clipboard. (Ready to paste or save)'),
      ),
    );
  }

  void _handleCreateBackup(BuildContext context) {
    final json = appState.createBackupJson();
    Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup JSON copied to clipboard. (Save securely)'),
      ),
    );
  }

  void _handleRestoreBackup(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your verified GanjiPal backup JSON string:'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '{"app": "GanjiPal", ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await appState.restoreFromBackup(textController.text.trim());
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup restored successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to restore: $e')),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase All Financial Data?'),
        content: const Text(
          'This action is irreversible. All your stored transactions, budgets, and import history will be permanently deleted from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await appState.clearAllData();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been cleared')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Erase Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSeedSampleData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed Sample Transactions?'),
        content: const Text(
          'This will populate your database with 10 realistic Kenyan M-Pesa transactions '
          '(income, rent, groceries, electricity, airtime, transfers, etc.) '
          'to demonstrate charts, budget analytics, and transaction filtering.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Seed Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final count = await SampleDataSeeder.seed();
      await appState.loadInitialData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0
                  ? 'Successfully added $count sample transactions.'
                  : 'Sample transactions are already present in the database.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to seed sample data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

