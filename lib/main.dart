import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

// Package & Screen Imports
import 'api_key.dart';
import 'firebase_options.dart';
import 'package:skill_exchange/screens/splash/splash_screen.dart';
import 'package:skill_exchange/screens/profile/profile_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  // 1. Ensure Flutter binding initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase Initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Gemini API Initialization
  Gemini.init(
    apiKey: ApiKey.geminiApiKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Skill Exchange',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        fontFamily: 'Roboto',
      ),
      // App strictly starts with SplashScreen
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// FIRESTORE PROFILE HELPER FUNCTION
// ==========================================
/// Naye user ki profile Firestore me save/update karne ke liye function
Future<void> saveUserProfileToFirestore({
  required String name,
  required String skill,
  Map<String, dynamic>? extraData,
}) async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'name': name,
        'skill': skill,
        'isProfileCompleted': true, // Essential to show Bottom Navigation
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (extraData != null) {
        userData.addAll(extraData);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
    }
  } catch (e) {
    debugPrint("Error saving user profile to Firestore: $e");
  }
}

// ==========================================
// AUTH & PROFILE COMPLETION CHECK GATEWAY
// ==========================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Show Loading state while checking auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6A1B9A),
              ),
            ),
          );
        }

        // 1. If user is NOT logged in -> Go to Profile/Login screen
        if (!authSnapshot.hasData) {
          return const ProfileScreen();
        }

        final user = authSnapshot.data!;

        // 2. Fetch user document in Realtime from Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .snapshots(),
          builder: (context, firestoreSnapshot) {
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6A1B9A),
                  ),
                ),
              );
            }

            // If user document exists in Firestore Backend
            if (firestoreSnapshot.hasData &&
                firestoreSnapshot.data != null &&
                firestoreSnapshot.data!.exists) {
              final userData =
              firestoreSnapshot.data!.data() as Map<String, dynamic>?;

              final isProfileCompleted =
                  userData?["isProfileCompleted"] ?? false;

              // If profile is completed, go to MainNavigationScreen
              if (isProfileCompleted) {
                return const MainNavigationScreen();
              }
            }

            // FIX FOR NEW USER: Even if Firestore document is created late,
            // default to MainNavigationScreen so Bottom Navigation is always visible.
            return const MainNavigationScreen();
          },
        );
      },
    );
  }
}