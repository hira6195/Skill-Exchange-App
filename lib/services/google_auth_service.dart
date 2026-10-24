import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Professional Google Sign-In Flow
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // SignOut force karte hain taake har baar Email Account Picker Pop-up samne aaye
      await googleSignIn.signOut();

      // 1. Google Account Picker Pop-up Screen Show Hogi
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Agar user ne account select kiye bina cancel kar diya
      if (googleUser == null) return null;

      // 2. Google Authentication details lena (Tokens)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Firebase Credential create karna
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase Auth mein Login/Signup karwana
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      // 5. Agar new user hai toh Firestore mein profile save karna
      if (user != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            "uid": user.uid,
            "name": user.displayName ?? "User",
            "email": user.email ?? "",
            "role": "Learner",
            "profileImage": user.photoURL ?? "",
            "bio": "",
            "skills": [],
            "verified": true, // Google accounts are automatically verified by Google
            "isEmailVerified": true, // Bypass manual email verification screen
            "rating": 0,
            "totalSessions": 0,
            "isProfileCompleted": false,
            "isPremium": false,
            "subscriptionPlan": "Basic",
            "createdAt": FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }
}