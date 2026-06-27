import 'package:flutter/material.dart';

/// Soft sign-in prompt for screens that need an account when Supabase Auth is on.
class AuthRequiredPromptCard extends StatelessWidget {
  const AuthRequiredPromptCard({
    super.key,
    required this.onOpenProfile,
  });

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F7FF), Color(0xFFEDE9FF), Color(0xFFE8EEFC)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accentColor.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              shape: BoxShape.circle,
              border: Border.all(color: _accentColor.withValues(alpha: 0.18)),
            ),
            child: Icon(
              Icons.lock_outline,
              size: 30,
              color: _accentColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Войдите, чтобы сохранять фото, баланс и покупки',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'После входа ваши генерации, баланс и покупки будут привязаны к аккаунту.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 1.45,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onOpenProfile,
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Перейти в профиль',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
