import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

enum ProfileEmailAuthResult { signedIn, signedUp }

/// Bottom sheet with email/password sign-in and sign-up.
class ProfileEmailAuthSheet extends StatefulWidget {
  const ProfileEmailAuthSheet({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  static Future<ProfileEmailAuthResult?> show(
    BuildContext context, {
    required AuthService authService,
  }) {
    return showModalBottomSheet<ProfileEmailAuthResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ProfileEmailAuthSheet(authService: authService),
      ),
    );
  }

  @override
  State<ProfileEmailAuthSheet> createState() => _ProfileEmailAuthSheetState();
}

class _ProfileEmailAuthSheetState extends State<ProfileEmailAuthSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSigningIn = false;
  bool _isSigningUp = false;

  bool get _isLoading => _isSigningIn || _isSigningUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _onSignIn() async {
    if (_isLoading) return;
    setState(() => _isSigningIn = true);
    try {
      await widget.authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(ProfileEmailAuthResult.signedIn);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Не удалось войти. Проверьте почту и пароль.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _onSignUp() async {
    if (_isLoading) return;
    setState(() => _isSigningUp = true);
    try {
      await widget.authService.signUpWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(ProfileEmailAuthResult.signedUp);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Не удалось создать аккаунт. '
        'Возможно, такая почта уже используется.',
      );
    } finally {
      if (mounted) setState(() => _isSigningUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;
    final accent = context.appAccent;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Вход по почте',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: textPrimary),
                  tooltip: 'Закрыть',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Введите email и пароль от вашего аккаунта.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              style: TextStyle(color: textPrimary, fontSize: 15),
              cursorColor: accent,
              decoration: _inputDecoration(context, 'Email'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: true,
              style: TextStyle(color: textPrimary, fontSize: 15),
              cursorColor: accent,
              decoration: _inputDecoration(context, 'Пароль'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Забыли пароль? Скоро добавим восстановление.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: colors.textSecondary.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                        ),
                  color: _isLoading ? colors.borderColor : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _onSignIn,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _isSigningIn
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Войти',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _onSignUp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSigningUp
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: accent,
                        ),
                      )
                    : const Text(
                        'Создать аккаунт',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final accent = context.appAccent;
    final borderRadius = BorderRadius.circular(12);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
      floatingLabelStyle: TextStyle(
        color: accent,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: colors.textSecondary.withValues(alpha: 0.75),
        fontSize: 14,
      ),
      filled: true,
      fillColor: colors.elevatedSurface,
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: accent.withValues(alpha: 0.55)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
    );
  }
}
