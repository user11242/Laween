import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laween/l10n/app_localizations.dart';

class StepWelcome extends StatelessWidget {
  final User? user;
  const StepWelcome({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: (user?.photoURL != null && user!.photoURL!.startsWith('http')) ? NetworkImage(user!.photoURL!) : null,
          radius: 40,
          child: user?.photoURL == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.welcomeUser(user?.displayName ?? "User"),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.needDetails,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
