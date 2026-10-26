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
              // Personal Profile Section
              _buildSectionHeader(context, 'PERSONAL PROFILE'),
              _buildGroupedCard(
                isDark: isDark,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.sage : AppColors.primary)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          appState.userName.isNotEmpty
                              ? appState.userName[0].toUpperCase()
                              : 'K',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.sage
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      appState.userName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Tap to change nickname or avatar',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
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
                ],
              ),
              const SizedBox(height: 20),

              // Appearance Section
              _buildSectionHeader(context, 'APPEARANCE'),
              _buildGroupedCard(
                isDark: isDark,
                children: [
                  _buildThemeOption(
                    context: context,
                    title: 'System Default',
                    subtitle: 'Follow device system appearance',
                    mode: ThemeMode.system,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildThemeOption(
                    context: context,
                    title: 'Warm Ivory (Light)',
                    subtitle: 'Off-white background with forest accents',
                    mode: ThemeMode.light,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildThemeOption(
                    context: context,
                    title: 'Deep Forest (Dark)',
                    subtitle: 'Near-black ground with quiet sage tones',
                    mode: ThemeMode.dark,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Data & Backup Section
              _buildSectionHeader(context, 'DATA & BACKUP'),
              _buildGroupedCard(
                isDark: isDark,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                    leading: Icon(
                      Icons.table_chart_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    title: Text(
                      'Export to CSV',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Copy formatted CSV of all transactions',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onTap: () => _handleCsvExport(context),
                  ),
                  _buildDivider(isDark),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                    leading: Icon(
                      Icons.backup_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    title: Text(
                      'Create JSON Backup',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Full snapshot of records and budgets',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onTap: () => _handleCreateBackup(context),
                  ),
                  _buildDivider(isDark),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                    leading: Icon(
                      Icons.restore_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    title: Text(
                      'Restore from Backup',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Import a verified JSON backup string',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onTap: () => _handleRestoreBackup(context),
                  ),
                  _buildDivider(isDark),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                    leading: Icon(
                      Icons.data_exploration_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    title: Text(
                      'Seed Sample Data',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Populate 10 realistic demo transactions',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onTap: () => _handleSeedSampleData(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Privacy & Security Section
              _buildSectionHeader(context, 'PRIVACY & SECURITY'),
              _buildGroupedCard(
                isDark: isDark,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: isDark
                                  ? AppColors.sage
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Strict On-Device Storage',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• All financial transactions and SMS receipts remain strictly inside local SQLite storage on this phone.\n'
                          '• GanjiPal does not send data to any cloud service, external AI, analytics, or third-party server.\n'
                          '• SMS deduplication is calculated deterministically with local SHA-256 hashes.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Danger Zone
              _buildSectionHeader(context, 'DANGER ZONE'),
              _buildGroupedCard(
                isDark: isDark,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                    leading: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.expense,
                    ),
                    title: const Text(
                      'Clear All Financial Records',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.expense,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Permanently erase all transactions, budgets, and logs',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    onTap: () => _confirmClearAllData(context),
                  ),
                ],
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildGroupedCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightBorder,
          width: 0.75,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.75,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required bool isDark,
  }) {
    final isSelected = appState.themeMode == mode;
    return InkWell(
      onTap: () => appState.setThemeMode(mode),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 18,
                color: isDark ? AppColors.sage : AppColors.primary,
              ),
          ],
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
