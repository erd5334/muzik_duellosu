import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String authProvider; // 'google', 'guest', 'email', 'apple'

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

  /// Apple ile Giriş Yap (iOS & macOS, App Store Guideline 4.8)
  Future<AuthUser?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final prefs = await SharedPreferences.getInstance();
      final userIdentifier = credential.userIdentifier ?? 'apple_${DateTime.now().millisecondsSinceEpoch}';

      // Apple sadece İLK girişte email ve ad soyad bilgisi gönderir.
      // Sonraki girişlerde null gelebileceğinden yerelde userIdentifier ile saklıyoruz.
      String email = credential.email ?? '';
      if (email.isNotEmpty) {
        await prefs.setString('apple_saved_email_$userIdentifier', email);
      } else {
        email = prefs.getString('apple_saved_email_$userIdentifier') ?? '';
      }

      String displayName = '';
      if (credential.givenName != null || credential.familyName != null) {
        final parts = [credential.givenName, credential.familyName]
            .where((s) => s != null && s.trim().isNotEmpty)
            .toList();
        displayName = parts.join(' ');
        if (displayName.isNotEmpty) {
          await prefs.setString('apple_saved_name_$userIdentifier', displayName);
        }
      }
      if (displayName.isEmpty) {
        displayName = prefs.getString('apple_saved_name_$userIdentifier') ??
            (email.isNotEmpty ? email.split('@').first : 'Apple Oyuncusu');
      }

      _currentUser = AuthUser(
        id: userIdentifier,
        email: email,
        displayName: displayName,
        photoUrl: null,
        authProvider: 'apple',
      );

      debugPrint('🍏 Apple Girişi Başarılı: ${_currentUser?.email} (${_currentUser?.id})');
      return _currentUser;
    } catch (e) {
      debugPrint('Apple Giriş Hatası: $e');
      return null;
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
