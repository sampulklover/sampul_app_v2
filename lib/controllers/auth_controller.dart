import 'package:google_sign_in/google_sign_in.dart';

class AuthController {
  AuthController._();

  static final AuthController instance = AuthController._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>['email']);

  Future<void> signOut() async {
    try {
      // Attempt to sign out of Google if previously signed in
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore errors on sign out for now (demo)
    }
  }
}


