import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

enum ProfileEmailAuthResult { signedIn, signedUp }

enum _ProfileEmailAuthMode { signIn, signUp, passwordRecovery }

/// Bottom sheet with email/password sign-in, sign-up, and password recovery.
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
  _ProfileEmailAuthMode _mode = _ProfileEmailAuthMode.signIn;
  bool _isSubmitting = false;

  bool get _isLoading => _isSubmitting;
  bool get _needsPassword => _mode != _ProfileEmailAuthMode.passwordRecovery;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _title => switch (_mode) {
        _ProfileEmailAuthMode.signIn => 'Вход по почте',
        _ProfileEmailAuthMode.signUp => 'Создать аккаунт',
        _ProfileEmailAuthMode.passwordRecovery => 'Восстановить пароль',
      };

  String get _subtitle => switch (_mode) {
        _ProfileEmailAuthMode.signIn =>
          'Введите email и пароль от вашего аккаунта.',
        _ProfileEmailAuthMode.signUp =>
          'Укажите email и пароль для нового аккаунта.',
        _ProfileEmailAuthMode.passwordRecovery =>
          'Мы отправим ссылку для сброса пароля на вашу почту.',
      };

  String get _primaryActionLabel => switch (_mode) {
        _ProfileEmailAuthMode.signIn => 'Войти',
        _ProfileEmailAuthMode.signUp => 'Создать аккаунт',
        _ProfileEmailAuthMode.passwordRecovery => 'Отправить ссылку',
      };

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _setMode(_ProfileEmailAuthMode mode) {
    if (_isLoading || _mode == mode) return;
    setState(() => _mode = mode);
  }

  String _errorMessage(Object error) {
    if (error is AuthNotConfiguredException) {
      return error.message;
    }
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        return 'Не удалось войти. Проверьте почту и пароль.';
      }
      if (message.contains('user already registered')) {
        return 'Такая почта уже используется. Попробуйте войти.';
      }
      if (message.contains('password')) {
        return 'Пароль слишком короткий или не подходит.';
      }
      if (message.contains('email')) {
        return 'Проверьте правильность email.';
      }
    }
    return switch (_mode) {
      _ProfileEmailAuthMode.signIn =>
        'Не удалось войти. Проверьте почту и пароль.',
      _ProfileEmailAuthMode.signUp =>
        'Не удалось создать аккаунт. Попробуйте другую почту.',
      _ProfileEmailAuthMode.passwordRecovery =>
        'Не удалось отправить ссылку. Попробуйте позже.',
    };
  }

  Future<void> _onPrimaryAction() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Введите email.');
      return;
    }
    if (_needsPassword && _passwordController.text.isEmpty) {
      _showMessage('Введите пароль.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      switch (_mode) {
        case _ProfileEmailAuthMode.signIn:
          await widget.authService.signInWithEmailPassword(
            email,
            _passwordController.text,
          );
          if (!mounted) return;
          Navigator.of(context).pop(ProfileEmailAuthResult.signedIn);
        case _ProfileEmailAuthMode.signUp:
          await widget.authService.signUpWithEmailPassword(
            email,
            _passwordController.text,
          );
          if (!mounted) return;
          Navigator.of(context).pop(ProfileEmailAuthResult.signedUp);
        case _ProfileEmailAuthMode.passwordRecovery:
          await widget.authService.resetPasswordForEmail(email);
          if (!mounted) return;
          _showMessage(
            'Если аккаунт существует, мы отправили ссылку для восстановления.',
          );
          setState(() => _mode = _ProfileEmailAuthMode.signIn);
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                    _title,
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
              _subtitle,
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
            if (_needsPassword) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: true,
                style: TextStyle(color: textPrimary, fontSize: 15),
                cursorColor: accent,
                decoration: _inputDecoration(context, 'Пароль'),
              ),
            ],
            if (_mode == _ProfileEmailAuthMode.signIn) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => _setMode(_ProfileEmailAuthMode.passwordRecovery),
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Забыли пароль?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
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
                    onTap: _isLoading ? null : _onPrimaryAction,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _primaryActionLabel,
                              style: const TextStyle(
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
            const SizedBox(height: 14),
            if (_mode != _ProfileEmailAuthMode.signUp)
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => _setMode(_ProfileEmailAuthMode.signUp),
                  child: const Text('Создать аккаунт'),
                ),
              ),
            if (_mode != _ProfileEmailAuthMode.signIn)
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => _setMode(_ProfileEmailAuthMode.signIn),
                  child: const Text('Уже есть аккаунт? Войти'),
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
