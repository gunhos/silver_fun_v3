import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/l10n_extension.dart';
import '../../../core/providers/toast_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/btn.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/meetups_provider.dart';

const int _titleMax = 80;
const int _descMax = 500;
const int _locationMax = 120;
const int _maxAttendeesCap = 200;

class CreateMeetupScreen extends ConsumerStatefulWidget {
  const CreateMeetupScreen({super.key});

  @override
  ConsumerState<CreateMeetupScreen> createState() =>
      _CreateMeetupScreenState();
}

class _CreateMeetupScreenState extends ConsumerState<CreateMeetupScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _maxAttendees = TextEditingController();
  DateTime? _startsAt;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _maxAttendees.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _startsAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String? _validate(AppLocalizations l) {
    if (_title.text.trim().isEmpty) return l.meetupValidationTitleRequired;
    if (_startsAt == null) return l.meetupValidationDateRequired;
    if (_startsAt!.isBefore(DateTime.now())) {
      return l.meetupValidationDateInPast;
    }
    if (_location.text.trim().isEmpty) {
      return l.meetupValidationLocationRequired;
    }
    final raw = _maxAttendees.text.trim();
    if (raw.isNotEmpty) {
      final n = int.tryParse(raw);
      if (n == null || n < 1) return l.meetupValidationMaxAttendeesPositive;
    }
    return null;
  }

  Future<void> _onSave() async {
    final l = context.l10n;
    final err = _validate(l);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final raw = _maxAttendees.text.trim();
      final maxA = raw.isEmpty ? null : int.parse(raw);
      await ref.read(meetupsRepositoryProvider).createMeetup(
            organizerUid: user.uid,
            title: _title.text.trim(),
            description: _description.text.trim(),
            startsAt: _startsAt!,
            location: _location.text.trim(),
            maxAttendees: maxA,
          );
      if (!mounted) return;
      showToast(ref, l.toastMeetupCreated);
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l.meetupCreateError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final dateLabel = _startsAt == null
        ? l.meetupFieldDateTime
        : _formatDateTime(_startsAt!);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          l.meetupCreateTitle,
          style: text.headlineSmall,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Field(
                label: l.meetupFieldTitle,
                controller: _title,
                maxLength: _titleMax,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _Field(
                label: l.meetupFieldDescription,
                controller: _description,
                maxLength: _descMax,
                multiline: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _DateTimeField(label: dateLabel, onTap: _pickDateTime),
              const SizedBox(height: 16),
              _Field(
                label: l.meetupFieldLocation,
                controller: _location,
                maxLength: _locationMax,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _Field(
                label: l.meetupFieldMaxAttendees,
                controller: _maxAttendees,
                numeric: true,
                maxLength: _maxAttendeesCap.toString().length,
                onChanged: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: text.bodyMedium?.copyWith(color: AppColors.accent),
                ),
              ],
              const SizedBox(height: 24),
              Btn(
                label: _saving ? l.actionSaving : l.meetupCreateSave,
                onPressed: _saving ? null : _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLength;
  final bool multiline;
  final bool numeric;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.label,
    required this.controller,
    required this.maxLength,
    required this.onChanged,
    this.multiline = false,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: multiline ? 4 : 1,
      maxLength: maxLength,
      keyboardType: numeric
          ? TextInputType.number
          : (multiline ? TextInputType.multiline : TextInputType.text),
      inputFormatters:
          numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateTimeField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            const Icon(Icons.event_outlined,
                color: AppColors.muted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.ink, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}
