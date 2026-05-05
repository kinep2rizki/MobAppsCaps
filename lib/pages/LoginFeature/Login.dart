import 'package:my_app/Services/AuthService.dart';
import 'package:my_app/Services/ProfileService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController {
  static String? validateCredentials({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || password.isEmpty) {
      return 'Email dan password wajib diisi.';
    }

    return null;
  }

  static Future<AuthResult> submitLogin({
    required String email,
    required String password,
  }) {
    return AuthService.login(
      email: email,
      password: password,
    );
  }

  static Future<void> persistLoginSession({
    required String email,
    required AuthResult result,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', email);

    if (result.token != null) {
      await prefs.setString('authToken', result.token!);
    }

    if (result.refreshToken != null) {
      await prefs.setString('refreshToken', result.refreshToken!);
    }

    if (result.tokenType != null) {
      await prefs.setString('tokenType', result.tokenType!);
    }
    await ProfileService.saveCachedProfileFromMap(result.user);
  }
}