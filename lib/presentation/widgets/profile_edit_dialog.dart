import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_state.dart';

class AvatarConfig {
  final String label;
  final List<Color> gradient;
  final IconData icon;

  const AvatarConfig({
    required this.label,
    required this.gradient,
    required this.icon,
  });
}

class ProfileAvatarHelper {
  static const List<AvatarConfig> presets = [
    AvatarConfig(
      label: 'Kenyan Forest',
      gradient: [Color(0xFF1E4D38), Color(0xFF2D6A4F)],
      icon: Icons.person_rounded,
    ),
    AvatarConfig(
      label: 'Muted Sage',
      gradient: [Color(0xFF40916C), Color(0xFF52B788)],
      icon: Icons.eco_rounded,
    ),
    AvatarConfig(
      label: 'Warm Amber',
      gradient: [Color(0xFFD97706), Color(0xFFB45309)],
      icon: Icons.wb_sunny_rounded,
    ),
    AvatarConfig(
      label: 'Terracotta',
      gradient: [Color(0xFFC05621), Color(0xFF9C4221)],
      icon: Icons.local_fire_department_rounded,
    ),
    AvatarConfig(
      label: 'Slate Navy',
      gradient: [Color(0xFF2B6CB0), Color(0xFF1A365D)],
      icon: Icons.shield_rounded,
    ),
  ];

  static AvatarConfig getConfig(int index) {
    if (index >= 0 && index < presets.length) {
      return presets[index];
    }
    return presets[0];
  }
}

/// Modal bottom sheet allowing the user to set their name or nickname
/// and select a stylish profile avatar.
class ProfileEditBottomSheet extends StatefulWidget {
  final AppState appState;

  const ProfileEditBottomSheet({super.key, required this.appState});

  @override
  State<ProfileEditBottomSheet> createState() => _ProfileEditBottomSheetState();
}

class _ProfileEditBottomSheetState extends State<ProfileEditBottomSheet> {
  late TextEditingController _nameController;
  late int _selectedAvatarIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.appState.userName);
    _selectedAvatarIndex = widget.appState.avatarIndex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentConfig = ProfileAvatarHelper.getConfig(_selectedAvatarIndex);
    final initial = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : 'K';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Profile',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Avatar Preview
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: currentConfig.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: currentConfig.gradient.first.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose Avatar Style',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Avatar Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(ProfileAvatarHelper.presets.length, (idx) {
              final preset = ProfileAvatarHelper.presets[idx];
              final isSelected = _selectedAvatarIndex == idx;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatarIndex = idx;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: preset.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      preset.icon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Name Input
          Text(
            'Your Name or Nickname',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: 'e.g. Kurui',
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final name = _nameController.text.trim();
                widget.appState.setUserName(name.isEmpty ? 'Kurui' : name);
                widget.appState.setAvatarIndex(_selectedAvatarIndex);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Save Profile',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
