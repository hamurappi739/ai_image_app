import 'package:supabase_flutter/supabase_flutter.dart';

/// Skeleton for Supabase Auth. Call `Supabase.initialize(...)` from app bootstrap
/// before auth APIs return real data (not wired in `main.dart` yet).
class AuthService {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _client?.auth.currentUser;

  String? get accessToken => _client?.auth.currentSession?.accessToken;

  bool get isSignedIn => currentUser != null;

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
    await client.auth.signOut();
  }
}
