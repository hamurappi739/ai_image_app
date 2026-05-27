import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth wrapper. Requires `Supabase.initialize` in `main.dart` (dart-define).
class AuthService {
  bool get isSupabaseInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient? get _client {
    if (!isSupabaseInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _client?.auth.currentUser;

  String? get accessToken {
    if (!isSupabaseInitialized) return null;
    return _client?.auth.currentSession?.accessToken;
  }

  bool get isSignedIn => isSupabaseInitialized && currentUser != null;

  /// Emits auth changes when Supabase is initialized; otherwise an empty stream.
  Stream<AuthState> get onAuthStateChange {
    final client = _client;
    if (client == null) {
      return Stream<AuthState>.empty();
    }
    return client.auth.onAuthStateChange;
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } catch (_) {
      // Supabase not configured or session already cleared.
    }
  }
}
