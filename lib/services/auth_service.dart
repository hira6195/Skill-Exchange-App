import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In Flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User cancelled the sign-in

      // 2. Obtain Auth Details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create Credentials for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign-in to Firebase
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      // 5. Save/Update User Profile in Firestore
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? "User",
            'email': user.email ?? "",
            'photoUrl': user.photoURL ?? "",
            'skillsOffered': [],
            'isTestPassed': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }
}