import 'package:flutter/material.dart';

import 'auth_required_prompt_card.dart';

/// Full-screen placeholder when Supabase Auth is configured but user is signed out.
class AuthRequiredScreen extends StatelessWidget {
  const AuthRequiredScreen({
    super.key,
    required this.onOpenProfile,
  });

  static const _scaffoldBackground = Color(0xFFF7F8FC);

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
            child: AuthRequiredPromptCard(onOpenProfile: onOpenProfile),
          ),
        ),
      ),
    );
  }
}
