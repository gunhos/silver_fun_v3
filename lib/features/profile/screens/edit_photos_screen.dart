import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/providers/toast_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/photo_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/my_profile_provider.dart';

class EditPhotosScreen extends ConsumerStatefulWidget {
  const EditPhotosScreen({super.key});

  @override
  ConsumerState<EditPhotosScreen> createState() => _EditPhotosScreenState();
}

class _EditPhotosScreenState extends ConsumerState<EditPhotosScreen> {
  bool _uploading = false;

  Future<void> _showAddPhotoSheet() async {
    if (_uploading) return;
    final l = context.l10n;
    final selected = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.ink,
              ),
              title: Text(l.editPhotosActionTakePhoto),
              onTap: () => Navigator.of(sheetCtx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.ink,
              ),
              title: Text(l.editPhotosActionChooseFromGallery),
              onTap: () => Navigator.of(sheetCtx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.muted),
              title: Text(l.editPhotosActionCancel),
              onTap: () => Navigator.of(sheetCtx).pop(),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _onAdd(selected);
  }

  Future<void> _onAdd(ImageSource source) async {
    final user = ref.read(authProvider).valueOrNull;
    final l = context.l10n;
    if (user == null || _uploading) return;

    setState(() => _uploading = true);
    try {
      final uploader = ref.read(profilePhotoUploaderProvider);
      final url = await uploader(user.uid, source);
      if (url == null) return; // user canceled the picker
      await ref.read(profileRepositoryProvider).addPhoto(uid: user.uid, url: url);
      if (!mounted) return;
      showToast(ref, l.toastPhotoAdded);
    } catch (_) {
      if (!mounted) return;
      showToast(ref, l.editPhotosErrorAdd);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _onSetMain(String url) async {
    final user = ref.read(authProvider).valueOrNull;
    final l = context.l10n;
    if (user == null) return;
    try {
      await ref
          .read(profileRepositoryProvider)
          .setMainPhoto(uid: user.uid, url: url);
      if (!mounted) return;
      showToast(ref, l.toastMainPhotoUpdated);
    } catch (_) {
      if (!mounted) return;
      showToast(ref, l.editPhotosErrorSetMain);
    }
  }

  Future<void> _onRemove(String url) async {
    final user = ref.read(authProvider).valueOrNull;
    final l = context.l10n;
    if (user == null) return;
    try {
      await ref
          .read(profileRepositoryProvider)
          .removePhoto(uid: user.uid, url: url);
      // Best-effort delete from Storage. Failure is logged inside the deleter.
      await ref.read(profilePhotoDeleterProvider)(url);
      if (!mounted) return;
      showToast(ref, l.toastPhotoRemoved);
    } catch (_) {
      if (!mounted) return;
      showToast(ref, l.editPhotosErrorRemove);
    }
  }

  Future<void> _showActions({
    required String url,
    required bool isMain,
    required bool canRemove,
  }) async {
    final l = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              enabled: !isMain,
              leading: const Icon(Icons.star_border, color: AppColors.ink),
              title: Text(l.editPhotosActionSetMain),
              onTap: isMain
                  ? null
                  : () {
                      Navigator.of(sheetCtx).pop();
                      _onSetMain(url);
                    },
            ),
            ListTile(
              enabled: canRemove,
              leading: const Icon(Icons.delete_outline, color: AppColors.ink),
              title: Text(l.editPhotosActionRemove),
              subtitle: canRemove
                  ? null
                  : Text(
                      l.editPhotosCannotRemoveLast,
                      style: const TextStyle(color: AppColors.muted),
                    ),
              onTap: !canRemove
                  ? null
                  : () {
                      Navigator.of(sheetCtx).pop();
                      _onRemove(url);
                    },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.muted),
              title: Text(l.editPhotosActionCancel),
              onTap: () => Navigator.of(sheetCtx).pop(),
            ),
          ],
        ),
      ),
    );
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

    final urls = profile.photoUrls;
    final canAdd = urls.length < kMaxProfilePhotos;
    final canRemove = urls.length > 1;

    final tiles = <Widget>[
      for (int i = 0; i < urls.length; i++)
        _PhotoTile(
          key: ValueKey('edit-photos-tile-${urls[i]}'),
          url: urls[i],
          isMain: i == 0,
          onMore: () => _showActions(
            url: urls[i],
            isMain: i == 0,
            canRemove: canRemove,
          ),
        ),
      if (canAdd)
        _AddTile(
          key: const ValueKey('edit-photos-add-tile'),
          uploading: _uploading,
          onTap: _showAddPhotoSheet,
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l.editPhotosTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.editPhotosSubtitle,
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: tiles,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  l.editPhotosCounter(urls.length),
                  style: text.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final bool isMain;
  final VoidCallback onMore;

  const _PhotoTile({
    super.key,
    required this.url,
    required this.isMain,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PhotoWidget(url: url),
          if (isMain)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l.editPhotosMainBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 6,
            bottom: 6,
            child: GestureDetector(
              onTap: onMore,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_horiz,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final bool uploading;
  final VoidCallback onTap;

  const _AddTile({super.key, required this.uploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: uploading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        alignment: Alignment.center,
        child: uploading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: AppColors.accent, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    l.editPhotosAdd,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
