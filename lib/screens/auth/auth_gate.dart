import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:skill_exchange/screens/auth/signup_screen.dart';
import 'package:skill_exchange/screens/email_verification_screen.dart';
import 'package:skill_exchange/screens/profile/profile_screen.dart';
import 'package:skill_exchange/screens/skills/skills_teach_screen.dart';
import 'package:skill_exchange/screens/skills/skills_learn_screen.dart';
import 'package:skill_exchange/screens/main_navigation_screen.dart';

// ==========================================================
// AUTH GATE — single source of truth for app routing
// ==========================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // --------------------------------------------------
        // 1. Checking login state
        // --------------------------------------------------
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // --------------------------------------------------
        // 2. Not logged in
        // --------------------------------------------------
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const SignupScreen();
        }

        final User user = authSnapshot.data!;

        // --------------------------------------------------
        // 3. Check Firestore for Verification & Onboarding Progress
        // --------------------------------------------------
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .snapshots(),
          builder: (context, firestoreSnapshot) {
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (firestoreSnapshot.hasError) {
              return _ErrorScreen(
                message: "${firestoreSnapshot.error}",
              );
            }

            final doc = firestoreSnapshot.data;
            final Map<String, dynamic>? data =
            doc?.data() as Map<String, dynamic>?;

            // --------------------------------------------------
            // 4. Email verification check
            // --------------------------------------------------
            final bool isFirestoreVerified =
                (data?['verified'] == true) || (data?['isEmailVerified'] == true);

            if (!user.emailVerified && !isFirestoreVerified) {
              return const EmailVerificationScreen();
            }

            // --------------------------------------------------
            // 5. Onboarding progress checks
            // --------------------------------------------------
            final String bio = (data?['bio'] ?? '').toString().trim();
            final String gender = (data?['gender'] ?? '').toString().trim();

            final List teachSkills =
                (data?['teachSkills'] as List?) ?? const [];
            final List learnSkills =
                (data?['learnSkills'] as List?) ?? const [];

            // Step not done: basic profile info
            if (bio.isEmpty || gender.isEmpty) {
              return const ProfileScreen();
            }

            // Step not done: what they can teach
            if (teachSkills.isEmpty) {
              return const SkillsTeachScreen();
            }

            // Step not done: what they want to learn
            if (learnSkills.isEmpty) {
              return const SkillsLearnScreen();
            }

            // Everything done -> dashboard
            return const MainNavigationScreen();
          },
        );
      },
    );
  }
}

// ==========================================================
// Shared loading / error widgets used only inside AuthGate
// ==========================================================

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6A1B9A),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Something went wrong: $message",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}