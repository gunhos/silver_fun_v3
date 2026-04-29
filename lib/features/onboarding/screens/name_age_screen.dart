import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/btn.dart';
import '../../../core/widgets/step_bar.dart';
import '../notifiers/onboarding_form_notifier.dart';
import '../repository/onboarding_repository.dart';

class NameAgeScreen extends ConsumerStatefulWidget {
  const NameAgeScreen({super.key});

  @override
  ConsumerState<NameAgeScreen> createState() => _NameAgeScreenState();
}

class _NameAgeScreenState extends ConsumerState<NameAgeScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(onboardingFormProvider);
    _name = TextEditingController(text: initial.name);
    _age = TextEditingController(
      text: initial.age?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final form = ref.read(onboardingFormProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !form.isNameAgeValid) return;

    setState(() => _saving = true);
    try {
      await ref.read(onboardingRepositoryProvider).saveNameAge(
            uid: user.uid,
            name: form.name,
            age: form.age!,
          );
      if (!mounted) return;
      context.go('/onboarding/photo');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardingFormProvider);
    final notifier = ref.read(onboardingFormProvider.notifier);
    final text = Theme.of(context).textTheme;

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
                        const StepBar(step: 0),
                        const SizedBox(height: 28),
                        Text(
                          "What's your name?",
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This is what people will see on your profile.',
                          style: text.bodyMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          onChanged: notifier.updateName,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                          ),
                          style: text.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _age,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          onChanged: (v) =>
                              notifier.updateAge(int.tryParse(v)),
                          decoration: const InputDecoration(
                            labelText: 'Age',
                          ),
                          style: text.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You must be 18 or older to use Kindred.',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                        const Spacer(),
                        const SizedBox(height: 16),
                        Btn(
                          label: _saving ? 'Saving…' : 'Continue',
                          onPressed: form.isNameAgeValid && !_saving
                              ? _onContinue
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
