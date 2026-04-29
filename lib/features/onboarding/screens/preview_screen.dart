import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/btn.dart';
import '../../../core/widgets/chip_tag.dart';
import '../../../core/widgets/photo_widget.dart';
import '../notifiers/onboarding_form_notifier.dart';
import '../repository/onboarding_repository.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  bool _publishing = false;
  String? _error;

  Future<void> _onPublish() async {
    final form = ref.read(onboardingFormProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      await ref.read(onboardingRepositoryProvider).publishProfile(
            uid: user.uid,
            form: form,
          );
      if (!mounted) return;
      ref.read(onboardingFormProvider.notifier).reset();
      // Router redirect will pick up `published == true` and route to /app/feed.
      context.go('/app/feed');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Publish failed. Please try again.');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardingFormProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Preview your profile',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "This is how others will see you.",
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: _ProfileCardPreview(
                    name: form.name,
                    age: form.age,
                    bio: form.bio,
                    photoUrl: form.photoUrl,
                    interests: form.interests,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: AppColors.accent),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Btn(
                      label: 'Edit',
                      variant: BtnVariant.ghost,
                      onPressed: _publishing
                          ? null
                          : () => context.go('/onboarding/bio'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Btn(
                      label: _publishing ? 'Publishing…' : 'Publish',
                      onPressed: _publishing ? null : _onPublish,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCardPreview extends StatelessWidget {
  final String name;
  final int? age;
  final String bio;
  final String photoUrl;
  final List<String> interests;

  const _ProfileCardPreview({
    required this.name,
    required this.age,
    required this.bio,
    required this.photoUrl,
    required this.interests,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppTheme.radiusCard);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: PhotoWidget(
              url: photoUrl.isEmpty ? null : photoUrl,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  age == null ? name : '$name, $age',
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (bio.isNotEmpty)
                  Text(
                    bio,
                    style: text.bodyLarge?.copyWith(color: AppColors.ink),
                  ),
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests
                        .map((t) => ChipTag(label: t, size: ChipSize.sm))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
