import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/btn.dart';
import '../../../core/widgets/photo_widget.dart';
import '../../../core/widgets/step_bar.dart';
import '../notifiers/onboarding_form_notifier.dart';
import '../repository/onboarding_repository.dart';

class AddPhotoScreen extends ConsumerStatefulWidget {
  const AddPhotoScreen({super.key});

  @override
  ConsumerState<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends ConsumerState<AddPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _uploading) return;

    XFile? file;
    try {
      file = await _picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      setState(() => _error = 'Could not open gallery.');
      return;
    }
    if (file == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final url = await repo.uploadPhoto(uid: user.uid, file: file);
      await repo.savePhotoUrl(uid: user.uid, url: url);
      if (!mounted) return;
      ref.read(onboardingFormProvider.notifier).updatePhotoUrl(url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
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
              const StepBar(step: 1),
              const SizedBox(height: 28),
              Text(
                'Add a photo',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick a clear, recent photo of you.',
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: ClipOval(
                      child: PhotoWidget(
                        url: form.photoUrl.isEmpty ? null : form.photoUrl,
                        width: 180,
                        height: 180,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _uploading ? null : _pickAndUpload,
                  child: Text(
                    _uploading
                        ? 'Uploading…'
                        : (form.photoUrl.isEmpty
                            ? 'Choose from gallery'
                            : 'Replace photo'),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _error!,
                    style: text.bodySmall?.copyWith(color: AppColors.accent),
                  ),
                ),
              ],
              const Spacer(),
              Btn(
                label: 'Continue',
                onPressed: form.isPhotoValid && !_uploading
                    ? () => context.go('/onboarding/bio')
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
