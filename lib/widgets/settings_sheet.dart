import 'package:flutter/material.dart';
import '../data/settings_store.dart';
import '../theme.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: NColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
    ),
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsStore.instance,
      builder: (context, _) {
        final s = SettingsStore.instance;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: NColors.inkSoft.withAlpha(60),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: Gap.lg),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: NColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: Gap.md),
                _Toggle(
                  icon: Icons.volume_up_rounded,
                  label: 'Sounds',
                  value: s.sound,
                  onChanged: s.setSound,
                ),
                const SizedBox(height: Gap.sm),
                _Toggle(
                  icon: Icons.vibration_rounded,
                  label: 'Vibration',
                  value: s.haptics,
                  onChanged: s.setHaptics,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NColors.bg,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: NColors.primary),
        title: Text(label,
            style: const TextStyle(
                color: NColors.ink, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: NColors.primary,
      ),
    );
  }
}
