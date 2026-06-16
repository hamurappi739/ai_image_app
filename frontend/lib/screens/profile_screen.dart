import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/user_balance.dart';
import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/free_generations_welcome_dialog.dart';
import '../widgets/profile/profile_auth_dialogs.dart';
import '../widgets/profile/profile_email_auth_sheet.dart';
import '../widgets/profile/profile_sign_in_prompt_card.dart';

const _scaffoldBackground = Color(0xFFF7F8FC);
const _textPrimary = Color(0xFF1A1D26);
const _textSecondary = Color(0xFF6B7280);
const _accentColor = Color(0xFF5B6CFF);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
    required this.apiService,
    required this.onAuthChanged,
    required this.onNavigate,
    required this.balance,
    required this.balanceLoading,
    required this.balanceLoadFailed,
    required this.onRefreshBalance,
    required this.showUserBalance,
    this.onResetOnboarding,
  });

  final AuthService authService;
  final ApiService apiService;
  final VoidCallback onAuthChanged;
  final ValueChanged<AppSection> onNavigate;
  final UserBalance? balance;
  final bool balanceLoading;
  final bool balanceLoadFailed;
  final VoidCallback onRefreshBalance;
  final bool showUserBalance;
  final VoidCallback? onResetOnboarding;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSigningOut = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _applySessionToApi() {
    widget.apiService.setAccessToken(widget.authService.accessToken);
    widget.onAuthChanged();
    widget.onRefreshBalance();
    if (mounted) setState(() {});
  }

  Future<void> _onEmailTap() async {
    final auth = widget.authService;
    if (!auth.isConfigured) {
      await ProfileAuthDialogs.showEmailUnavailable(context);
      return;
    }

    final result = await ProfileEmailAuthSheet.show(
      context,
      authService: auth,
    );
    if (!mounted || result == null) return;

    _applySessionToApi();

    switch (result) {
      case ProfileEmailAuthResult.signedIn:
        _showSnackBar('Вы вошли в аккаунт.');
      case ProfileEmailAuthResult.signedUp:
        _showSnackBar(
          'Аккаунт создан. Вам доступны 3 бесплатные генерации.',
        );
        await FreeGenerationsWelcomeDialog.show(context);
    }
  }

  Future<void> _onSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await widget.authService.signOut();
      widget.apiService.setAccessToken(null);
      widget.onAuthChanged();
      if (!mounted) return;
      _showSnackBar('Вы вышли из аккаунта');
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Не удалось выйти. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.authService;
    final isSignedIn = auth.isConfigured && auth.isSignedIn;
    final email = auth.currentUser?.email?.trim();

    return Scaffold(
      backgroundColor: _scaffoldBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppScreenHeader(
                    title: 'Профиль',
                    showBalanceIndicator: false,
                  ),
                  const SizedBox(height: 16),
                  if (isSignedIn)
                    _SignedInAccountCard(email: email)
                  else
                    ProfileSignInPromptCard(
                      isAuthAvailable: auth.isConfigured,
                      onEmailTap: _onEmailTap,
                      onVkTap: () =>
                          ProfileAuthDialogs.showVkComingSoon(context),
                      onYandexTap: () =>
                          ProfileAuthDialogs.showYandexComingSoon(context),
                    ),
                  if (!auth.isConfigured) ...[
                    const SizedBox(height: 16),
                    const _ProfileDemoModeCard(),
                  ],
                  if (widget.showUserBalance) ...[
                    const SizedBox(height: 20),
                    _UserBalanceProfileCard(
                      balance: widget.balance,
                      isLoading: widget.balanceLoading,
                      hasError: widget.balanceLoadFailed,
                      onRefresh: widget.onRefreshBalance,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _ProfileQuickActions(onNavigate: widget.onNavigate),
                  if (isSignedIn) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isSigningOut ? null : _onSignOut,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentColor,
                          side: BorderSide(
                            color: _accentColor.withValues(alpha: 0.45),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSigningOut
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text(
                                'Выйти',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                  if (!auth.isConfigured) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => _showSnackBar(
                          'Документы будут добавлены перед релизом',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentColor,
                          side: BorderSide(
                            color: _accentColor.withValues(alpha: 0.45),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Политика конфиденциальности',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  if (kDebugMode && widget.onResetOnboarding != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: widget.onResetOnboarding,
                        child: const Text(
                          'Показать обучалку снова',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignedInAccountCard extends StatelessWidget {
  const _SignedInAccountCard({this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayEmail =
        (email != null && email!.isNotEmpty) ? email! : 'Аккаунт подключён';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(
              Icons.person,
              size: 30,
              color: _accentColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Вы вошли',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayEmail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.45,
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ваши фото, баланс и покупки сохраняются в этом аккаунте.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileQuickActions extends StatelessWidget {
  const _ProfileQuickActions({required this.onNavigate});

  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _ProfileQuickActionTile(
          icon: Icons.shopping_bag_outlined,
          label: 'Купить',
          onTap: () => onNavigate(AppSection.buy),
        ),
        const SizedBox(height: 10),
        _ProfileQuickActionTile(
          icon: Icons.photo_library_outlined,
          label: 'Готовые фото',
          onTap: () => onNavigate(AppSection.gallery),
        ),
        const SizedBox(height: 10),
        _ProfileQuickActionTile(
          icon: Icons.dashboard_customize_outlined,
          label: 'Фото по шаблону',
          onTap: () => onNavigate(AppSection.templatePhoto),
        ),
      ],
    );
  }
}

class _ProfileQuickActionTile extends StatelessWidget {
  const _ProfileQuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EAEF)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: _accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDemoModeCard extends StatelessWidget {
  const _ProfileDemoModeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8D4B8).withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline,
              size: 22,
              color: _accentColor.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Демо-режим',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Вход в аккаунт пока недоступен в этой сборке. '
                  'Можно проверить создание фото, фотосессии и покупку '
                  'без настоящей оплаты.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.45,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBalanceLine extends StatelessWidget {
  const _ProfileBalanceLine({
    required this.label,
    required this.value,
    required this.rowStyle,
  });

  final String label;
  final String value;
  final TextStyle? rowStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: rowStyle)),
        Text(
          value,
          style: rowStyle?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _UserBalanceProfileCard extends StatelessWidget {
  const _UserBalanceProfileCard({
    required this.balance,
    required this.isLoading,
    required this.hasError,
    required this.onRefresh,
  });

  final UserBalance? balance;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.45,
      color: _textPrimary,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ваш баланс',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            Text(
              'Загружаем баланс…',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                color: _textSecondary,
              ),
            )
          else if (hasError)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Не удалось загрузить баланс.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRefresh,
                  child: const Text('Повторить'),
                ),
              ],
            )
          else if (balance != null) ...[
            _ProfileBalanceLine(
              label: 'Изображения',
              value: '${balance!.totalAvailableImages}',
              rowStyle: rowStyle,
            ),
            const SizedBox(height: 10),
            _ProfileBalanceLine(
              label: 'Бесплатные генерации',
              value:
                  '${balance!.freeGenerationsRemaining} '
                  'из ${balance!.freeGenerationsLimit}',
              rowStyle: rowStyle,
            ),
            const SizedBox(height: 10),
            Text(
              'Фотосессия стоит ${balance!.photoshootImageCost} изображения',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.4,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Сначала используются бесплатные генерации.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.4,
                color: _textSecondary,
              ),
            ),
            if (!balance!.consumptionEnabled) ...[
              const SizedBox(height: 8),
              Text(
                'Сейчас включён демо-режим — списание отключено.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
