import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/l10n_extension.dart';
import '../../../core/providers/toast_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/my_profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _onTogglePause(bool nextValue) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(authProvider).valueOrNull;
    if (user == null || _busy) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateField(user.uid, 'profilePaused', nextValue);
      if (!mounted) return;
      showToast(ref, nextValue ? l.toastProfilePaused : l.toastProfileLive);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onSignOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(googleAuthServiceProvider).signOut();
      if (!mounted) return;
      context.go('/signin');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final paused = profile?.profilePaused ?? false;
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          l.settingsTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SectionTitle(l.settingsSectionProfile),
            _SettingsCard(
              children: [
                SwitchListTile.adaptive(
                  value: paused,
                  onChanged: _busy ? null : _onTogglePause,
                  title: Text(l.settingsPauseProfile),
                  subtitle: Text(
                    paused
                        ? l.settingsPauseSubtitlePaused
                        : l.settingsPauseSubtitleLive,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  activeThumbColor: AppColors.accent,
                ),
                const _DividerRow(),
                ListTile(
                  title: Text(l.settingsEditPhoto),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.muted,
                  ),
                ),
                const _DividerRow(),
                ListTile(
                  title: Text(l.settingsWhoCanSeeMe),
                  subtitle: Text(
                    l.settingsWhoCanSeeMeValue,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionTitle(l.settingsSectionNotifications),
            _SettingsCard(
              children: [
                _UiOnlyToggleRow(label: l.settingsNotifLikes),
                const _DividerRow(),
                _UiOnlyToggleRow(
                  label: l.settingsNotifDigest,
                  initial: false,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionTitle(l.settingsSectionAccount),
            _SettingsCard(
              children: [
                ListTile(
                  title: Text(l.settingsAccountGoogle),
                  trailing: const Icon(Icons.check, color: AppColors.muted),
                ),
                const _DividerRow(),
                ListTile(
                  title: Text(l.settingsAccountPrivacy),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.muted,
                  ),
                ),
                const _DividerRow(),
                ListTile(
                  title: Text(l.settingsAccountHelp),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SignOutButton(onPressed: _busy ? null : _onSignOut),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _DividerRow extends StatelessWidget {
  const _DividerRow();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.line,
      indent: 16,
      endIndent: 16,
    );
  }
}

class _UiOnlyToggleRow extends StatefulWidget {
  final String label;
  final bool initial;

  const _UiOnlyToggleRow({required this.label, this.initial = true});

  @override
  State<_UiOnlyToggleRow> createState() => _UiOnlyToggleRowState();
}

class _UiOnlyToggleRowState extends State<_UiOnlyToggleRow> {
  late bool _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      title: Text(widget.label),
      activeThumbColor: AppColors.accent,
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _SignOutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Text(
          l.settingsSignOut,
          style: TextStyle(
            color: onPressed == null ? AppColors.muted : AppColors.accent,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
