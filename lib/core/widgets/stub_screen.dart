import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class StubScreen extends StatelessWidget {
  final String title;

  const StubScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          l.stubComingSoon(title),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
              ),
        ),
      ),
    );
  }
}
