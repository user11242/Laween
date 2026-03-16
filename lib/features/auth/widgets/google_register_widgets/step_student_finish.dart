import 'package:flutter/material.dart';
import 'package:laween/l10n/app_localizations.dart';

class StepStudentFinish extends StatelessWidget {
  const StepStudentFinish({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user, color: Colors.green, size: 60.0),
          const SizedBox(height: 20),
          Text(
            l10n.studentFinishMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
