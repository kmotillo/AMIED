import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client.auth);
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class AuthRepository {
  final GoTrueClient _auth;

  AuthRepository(this._auth);

  Future<void> signInWithEmailPassword(String email, String password) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmailPassword({
    required String email, 
    required String password,
    String? name,
    String? institution,
    String? subjects,
  }) async {
    await _auth.signUp(
      email: email, 
      password: password,
      data: {
        if (name != null && name.isNotEmpty) 'full_name': name,
        if (institution != null && institution.isNotEmpty) 'institution': institution,
        if (subjects != null && subjects.isNotEmpty) 'subjects': subjects,
      }
    );
  }

  Future<void> updateProfile({required String fullName, required String institution}) async {
    await _auth.updateUser(
      UserAttributes(
        data: {
          'full_name': fullName,
          'institution': institution,
        },
      ),
    );
  }

  Future<void> updateAvatar(String avatarUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Update Supabase Auth metadata
    await _auth.updateUser(
      UserAttributes(
        data: {
          'avatar_url': avatarUrl,
        },
      ),
    );

    // Update public profiles table
    await Supabase.instance.client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', user.id);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
