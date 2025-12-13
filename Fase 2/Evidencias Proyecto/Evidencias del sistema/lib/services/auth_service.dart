import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AuthService {
  final _sb = Supa.client;

  Future<AuthResponse> signUpEmail({
    required String email,
    required String password,
    required String fullName, // 👈 NUEVO
  }) {
    return _sb.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(), // 👈 se guarda en user_metadata
      },
    );
  }

  Future<AuthResponse> signInEmail({
    required String email,
    required String password,
  }) {
    return _sb.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _sb.auth.signOut();
}
