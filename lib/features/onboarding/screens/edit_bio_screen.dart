import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/btn.dart';
import '../../../core/widgets/step_bar.dart';
import '../../profile/providers/my_profile_provider.dart';
import '../notifiers/onboarding_form_notifier.dart';
import '../repository/onboarding_repository.dart';

const int _bioLimit = 180;

class EditBioScreen extends ConsumerStatefulWidget {
  final bool standalone;

  const EditBioScreen({super.key, this.standalone = false});

  @override
  ConsumerState<EditBioScreen> createState() => _EditBioScreenState();
}

class _EditBioScreenState extends ConsumerState<EditBioScreen> {
  late final TextEditingController _bio;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.standalone
        ? (ref.read(myProfileProvider).valueOrNull?.bio ?? '')
        : ref.read(onboardingFormProvider).bio;
    _bio = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  Future<void> _onContinueOnboarding() async {
    final form = ref.read(onboardingFormProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !form.isBioValid) return;

    setState(() => _saving = true);
    try {
      await ref.read(onboardingRepositoryProvider).saveBio(
            uid: user.uid,
            bio: form.bio,
          );
      if (!mounted) return;
      context.go('/onboarding/interests');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onSaveStandalone() async {
    final user = FirebaseAuth.instance.currentUser;
    final value = _bio.text.trim();
    if (user == null || value.length < 10 || value.length > _bioLimit) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateField(user.uid, 'bio', value);
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (widget.standalone) {
      final value = _bio.text;
      final valid = value.trim().length >= 10 && value.length <= _bioLimit;
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Edit bio'),
          actions: [
            TextButton(
              onPressed: valid && !_saving ? _onSaveStandalone : null,
              child: Text(
                _saving ? 'Saving…' : 'Save',
                style: TextStyle(
                  color: valid ? AppColors.accent : AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: _BioEditor(
              controller: _bio,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      );
    }

    final form = ref.watch(onboardingFormProvider);
    final notifier = ref.read(onboardingFormProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const StepBar(step: 2),
                        const SizedBox(height: 28),
                        Text(
                          'Write a short bio',
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A sentence or two about you. Keep it light.',
                          style: text.bodyMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 24),
                        _BioEditor(
                          controller: _bio,
                          onChanged: notifier.updateBio,
                        ),
                        const Spacer(),
                        const SizedBox(height: 16),
                        Btn(
                          label: _saving ? 'Saving…' : 'Continue',
                          onPressed: form.isBioValid && !_saving
                              ? _onContinueOnboarding
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BioEditor extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _BioEditor({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final length = controller.text.characters.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: TextField(
            controller: controller,
            maxLines: 6,
            maxLength: _bioLimit,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'I love early morning coffee, hiking on weekends…',
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              counterText: '',
            ),
            style: text.bodyLarge,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$length / $_bioLimit',
            style: text.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}
