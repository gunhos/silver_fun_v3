import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/btn.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    final errorText = AppLocalizations.of(context).signInError;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(googleAuthServiceProvider).signIn();
      // Router redirect handles post-sign-in navigation.
    } catch (e, st) {
      developer.log(
        'Google sign-in failed',
        name: 'auth',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _error = kDebugMode ? '$errorText\n$e' : errorText);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              const _Logo(),
              const SizedBox(height: 28),
              Text(
                l.appTitle,
                style: text.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.signInTagline,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: AppColors.muted),
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: text.bodySmall?.copyWith(color: AppColors.accent),
                ),
                const SizedBox(height: 12),
              ],
              Btn(
                label: _busy ? l.signInButtonBusy : l.signInButton,
                onPressed: _busy ? null : _signIn,
                leading: const _GoogleG(),
              ),
              const SizedBox(height: 16),
              Text(
                l.signInTermsNote,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.favorite, color: Colors.white, size: 40),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
