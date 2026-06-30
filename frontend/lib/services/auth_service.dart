import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when Supabase was not initialized (missing dart-define config).
class AuthNotConfiguredException implements Exception {
  AuthNotConfiguredException([this.message = 'Вход недоступен в этом запуске']);

  final String message;

  @override
  String toString() => message;
}

/// Supabase Auth wrapper. Requires `Supabase.initialize` in `main.dart` (dart-define).
class AuthService {
  static const _authUnavailableMessage = 'Вход недоступен в этом запуске';

  bool get isConfigured {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient? get _client {
    if (!isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw AuthNotConfiguredException(_authUnavailableMessage);
    }
  }

  User? get currentUser {
    if (!isConfigured) return null;
    return _client?.auth.currentUser;
  }

  String? get accessToken {
    if (!isConfigured) return null;
    return _client?.auth.currentSession?.accessToken;
  }

  bool get isSignedIn => isConfigured && currentUser != null;

  Stream<AuthState> get onAuthStateChange {
    final client = _client;
    if (client == null) {
      return Stream<AuthState>.empty();
    }
    return client.auth.onAuthStateChange;
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    _ensureConfigured();
    final client = _client;
    if (client == null) {
      throw AuthNotConfiguredException(_authUnavailableMessage);
    }
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUpWithEmailPassword(String email, String password) async {
    _ensureConfigured();
    final client = _client;
    if (client == null) {
      throw AuthNotConfiguredException(_authUnavailableMessage);
    }
    await client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    _ensureConfigured();
    final client = _client;
    if (client == null) {
      throw AuthNotConfiguredException(_authUnavailableMessage);
    }
    await client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    _ensureConfigured();
    final client = _client;
    if (client == null) {
      throw AuthNotConfiguredException(_authUnavailableMessage);
    }
    await client.auth.signOut();
  }
}
