import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/btn.dart';
import '../../../core/widgets/chip_tag.dart';
import '../../../core/widgets/step_bar.dart';
import '../notifiers/onboarding_form_notifier.dart';
import '../repository/onboarding_repository.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  bool _saving = false;

  Future<void> _onContinue() async {
    final form = ref.read(onboardingFormProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !form.isInterestsValid) return;

    setState(() => _saving = true);
    try {
      await ref.read(onboardingRepositoryProvider).saveInterests(
            uid: user.uid,
            interests: form.interests,
          );
      if (!mounted) return;
      context.go('/onboarding/preview');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardingFormProvider);
    final notifier = ref.read(onboardingFormProvider.notifier);
    final text = Theme.of(context).textTheme;
    final count = form.interests.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepBar(step: 3),
              const SizedBox(height: 28),
              Text(
                'Pick your interests',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose 3 to 6 things you love.',
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                '$count / 6 selected',
                style: text.bodySmall?.copyWith(
                  color: form.isInterestsValid
                      ? AppColors.accent
                      : AppColors.muted,
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
                      final selected = form.interests.contains(tag);
                      return ChipTag(
                        label: tag,
                        selected: selected,
                        onTap: () => notifier.toggleInterest(tag),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Btn(
                label: _saving ? 'Saving…' : 'Continue',
                onPressed:
                    form.isInterestsValid && !_saving ? _onContinue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
