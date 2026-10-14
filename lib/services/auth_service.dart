import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String authProvider; // 'google', 'guest', 'email'

  AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.authProvider,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '934487069688-8iiub0htcjnhc32dooqlg5i2glck16q2.apps.googleusercontent.com',
  );

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Google ile Giriş Yap
  Future<AuthUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // Kullanıcı giriş penceresini iptal etti
        return null;
      }

      _currentUser = AuthUser(
        id: account.id,
        email: account.email,
        displayName: account.displayName ?? 'Google Oyuncusu',
        photoUrl: account.photoUrl,
        authProvider: 'google',
      );

      debugPrint('Google Girişi Başarılı: ${_currentUser?.email}');
      return _currentUser;
    } catch (e) {
      debugPrint('Google Giriş Hatası: $e');
      rethrow;
    }
  }

  /// Çıkış Yap
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      _currentUser = null;
    } catch (e) {
      debugPrint('Çıkış Hatası: $e');
    }
  }
}
