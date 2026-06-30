import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Sign-in call-to-action when the user is not logged in.
class ProfileSignInPromptCard extends StatelessWidget {
  const ProfileSignInPromptCard({
    super.key,
    required this.isAuthAvailable,
    required this.onEmailTap,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final bool isAuthAvailable;
  final VoidCallback onEmailTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_outline,
                size: 34,
                color: _accentColor.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Войдите в аккаунт',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAuthAvailable
                ? 'Так ваши фото, баланс и покупки будут сохраняться.'
                : 'Вход в аккаунт пока недоступен в этой демо-сборке.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.45,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 22),
          _PrimaryAuthButton(
            label: 'Войти по почте',
            icon: Icons.mail_outline,
            onTap: onEmailTap,
          ),
          const SizedBox(height: 10),
          _SocialAuthButton(
            label: 'Продолжить с VK ID',
            badgeText: 'VK',
            badgeColor: const Color(0xFF0077FF),
            enabled: false,
            soonLabel: 'Скоро',
          ),
          const SizedBox(height: 10),
          _SocialAuthButton(
            label: 'Продолжить с Яндекс ID',
            badgeText: 'Я',
            badgeColor: const Color(0xFFFF4433),
            enabled: false,
            soonLabel: 'Скоро',
          ),
          const SizedBox(height: 14),
          Text(
            'В демо-режиме вход может быть недоступен.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.35,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.badgeText,
    required this.badgeColor,
    this.enabled = true,
    this.soonLabel,
  });

  final String label;
  final String badgeText;
  final Color badgeColor;
  final bool enabled;
  final String? soonLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: enabled
              ? context.appTextPrimary
              : colors.textSecondary,
          backgroundColor: colors.elevatedSurface,
          disabledForegroundColor: colors.textSecondary,
          side: BorderSide(color: colors.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: enabled ? 1 : 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (soonLabel != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.mutedBadgeFill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  soonLabel!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
