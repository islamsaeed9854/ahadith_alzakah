// lib/core/secure_supabase_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A [LocalStorage] implementation that uses flutter_secure_storage
/// to persist the Supabase session.
///
/// This is a secure alternative to the default SharedPreferences.
class SecureSupabaseStorage implements LocalStorage {
  /// The key used to store the session in secure storage.
  static const _sessionKey = 'supabase_session';

  final _storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {
    // No initialization needed for flutter_secure_storage
  }

  @override
  Future<bool> hasAccessToken() async {
    return await _storage.containsKey(key: _sessionKey);
  }

  @override
  Future<String?> accessToken() async {
    return await _storage.read(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String session) async {
    await _storage.write(key: _sessionKey, value: session);
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: _sessionKey);
  }
}