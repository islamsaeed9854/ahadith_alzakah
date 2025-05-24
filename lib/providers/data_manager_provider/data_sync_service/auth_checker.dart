import 'package:supabase_flutter/supabase_flutter.dart';

class AuthChecker {
  final SupabaseClient _supabase;

  AuthChecker() : _supabase = Supabase.instance.client;

  bool isUserAuthenticated() {
    return _supabase.auth.currentUser != null;
  }
}