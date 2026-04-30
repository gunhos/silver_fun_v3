import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/i18n/interest_label.dart';
import '../../../core/providers/toast_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chip_tag.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/my_profile_provider.dart';

class EditInterestsScreen extends ConsumerStatefulWidget {
  const EditInterestsScreen({super.key});

  @override
  ConsumerState<EditInterestsScreen> createState() =>
      _EditInterestsScreenState();
}

class _EditInterestsScreenState extends ConsumerState<EditInterestsScreen> {
  List<String>? _selection;
  bool _saving = false;

  void _ensureSeeded(List<String> initial) {
    _selection ??= List<String>.from(initial);
  }

  void _toggle(String tag) {
    final current = _selection!;
    setState(() {
      if (current.contains(tag)) {
        current.remove(tag);
      } else {
        if (current.length >= 6) return;
        current.add(tag);
      }
    });
  }

  bool get _valid =>
      _selection != null &&
      _selection!.length >= 3 &&
      _selection!.length <= 6;

  Future<void> _onSave() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null || !_valid || _saving) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateField(
            user.uid,
            'interests',
            List<String>.from(_selection!),
          );
      if (!mounted) return;
      showToast(ref, context.l10n.toastInterestsUpdated);
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final profile = ref.watch(myProfileProvider).valueOrNull;

    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    _ensureSeeded(profile.interests);
    final count = _selection!.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l.editInterestsTitle),
        actions: [
          TextButton(
            onPressed: _valid && !_saving ? _onSave : null,
            child: Text(
              _saving ? l.actionSaving : l.actionSave,
              style: TextStyle(
                color: _valid ? AppColors.accent : AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.editInterestsSubtitle,
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                l.onbInterestsCounter(count),
                style: text.bodySmall?.copyWith(
                  color: _valid ? AppColors.accent : AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kInterestPool.map((tag) {
                      final selected = _selection!.contains(tag);
                      return ChipTag(
                        label: l.localizedInterest(tag),
                        selected: selected,
                        onTap: () => _toggle(tag),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
