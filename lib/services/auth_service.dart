import 'dart:async'; // Required for Completer
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Use Singleton (v7 standard)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Stream to listen to auth changes
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // ===========================================================================
  // 1. PUBLIC METHOD: signInWithGoogle
  // ===========================================================================
  Future<User?> signInWithGoogle() async {
    try {
      const String webClientId =
          "821207234840-kk6td2l0spfpn5tgpkd2hdml1msorcbd.apps.googleusercontent.com";

      await _googleSignIn.initialize(
        serverClientId: webClientId,
      );

      // Step A: Perform the robust Google Sign-In (using the Stream engine)
      final AuthCredential credential = await _performGoogleSignIn();

      // Step B: Sign in to Firebase
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      // Step C: Save to Firestore (Your specific logic)
      if (user != null) {
        await _saveUserToFirestore(user);
      }

      return user;
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }

  // ===========================================================================
  // 2. INTERNAL ENGINE: _performGoogleSignIn
  // (This is the robust logic from the working example you found)
  // ===========================================================================
  Future<AuthCredential> _performGoogleSignIn() async {
    // 1. Check platform support
    if (!_googleSignIn.supportsAuthenticate()) {
      // Fallback for Web or unsupported platforms if needed, or throw error
      throw Exception(
        'Google Sign-In not supported on this platform via authenticate()',
      );
    }

    // 2. Prepare the "Completer" to wait for the Stream
    final completer = Completer<GoogleSignInAccount?>();
    StreamSubscription<GoogleSignInAuthenticationEvent>? subscription;

    // 3. Listen to the Event Stream (The v7 Way)
    subscription = _googleSignIn.authenticationEvents.listen(
      (event) {
        if (!completer.isCompleted) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            completer.complete(event.user);
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            completer.complete(null);
          }
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    try {
      // 4. Trigger the Popup
      await _googleSignIn.authenticate();

      // 5. Wait for the stream to give us the user (with 30s timeout)
      final GoogleSignInAccount? googleUser = await completer.future.timeout(
        const Duration(seconds: 30),
      );

      // Clean up listener
      subscription.cancel();

      if (googleUser == null) {
        throw Exception('Google Sign-In canceled by user');
      }

      // 6. Get Tokens (No accessToken needed!)
      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get ID Token');
      }

      return GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    } catch (e) {
      subscription?.cancel();
      rethrow;
    }
  }

  // ===========================================================================
  // 3. FIRESTORE LOGIC
  // (Your original logic extracted for cleanliness)
  // ===========================================================================
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        String displayName = user.displayName ?? '';
        List<String> names = displayName.split(' ');
        String fName = names.isNotEmpty ? names.first : '';
        String lName = names.length > 1 ? names.sublist(1).join(' ') : '';
        String defaultUsername = user.email != null
            ? user.email!.split('@')[0]
            : '';

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'username': defaultUsername,
          'firstName': fName,
          'lastName': lName,
          'createdAt': FieldValue.serverTimestamp(),
          'profilePicUrl': user.photoURL ?? '',
          'faculty': '',
          'studyProgram': '',
        });
      }
    } catch (e) {
      print("Firestore Save Error: $e");
      // Don't crash login if Firestore fails, just log it
    }
  }

  // ===========================================================================
  // 4. STANDARD AUTH METHODS (Kept as is)
  // ===========================================================================

  Future<User?> signUpWithEmail(
    String email,
    String password,
    String username,
    String firstName,
    String lastName,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
          'createdAt': FieldValue.serverTimestamp(),
          'profilePicUrl': '',
          'faculty': '',
          'studyProgram': '',
        });
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      return (await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      )).user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
