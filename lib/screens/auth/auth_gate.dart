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

//

// FLOW (each step happens ONCE per account, never repeats):

//

// Not logged in

// -> SignupScreen

//

// Logged in + Email NOT verified

// -> EmailVerificationScreen

//

// Logged in + Verified + Name missing

// -> ProfileScreen

//

// Logged in + Verified + Profile done + no Teach skill

// -> SkillsTeachScreen

//

// Logged in + Verified + Profile done + Teach done + no Learn skill

// -> SkillsLearnScreen

//

// Everything done

// -> MainNavigationScreen (Dashboard)

//

// NOTE: Instead of trusting a single "isProfileCompleted" flag

// (which can be set too early by mistake), this checks the

// actual saved data for each step. This way, even if a flag is

// wrong somewhere, the user is never sent to a broken state and

// never asked to repeat a step they've already finished.

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

// 3. Refresh emailVerified status

// --------------------------------------------------

// We don't sign the user out if this fails — a temporary

// network hiccup shouldn't destroy the user's session.

        return FutureBuilder<void>(

          future: user.reload(),

          builder: (context, reloadSnapshot) {

            if (reloadSnapshot.connectionState == ConnectionState.waiting) {

              return const _LoadingScreen();

            }



            final User? refreshedUser = FirebaseAuth.instance.currentUser;



            if (refreshedUser == null) {

              return const SignupScreen();

            }



// --------------------------------------------------

// 4. Email verification check

// --------------------------------------------------

            if (!refreshedUser.emailVerified) {

              return const EmailVerificationScreen();

            }



// --------------------------------------------------

// 5. Email verified -> check onboarding progress

// --------------------------------------------------

            return StreamBuilder<DocumentSnapshot>(

              stream: FirebaseFirestore.instance

                  .collection("users")

                  .doc(refreshedUser.uid)

                  .snapshots(),

              builder: (context, firestoreSnapshot) {

                if (firestoreSnapshot.connectionState ==

                    ConnectionState.waiting) {

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



                final String bio = (data?['bio'] ?? '').toString().trim();

                final String gender = (data?['gender'] ?? '').toString().trim();



                final List teachSkills =

                    (data?['teachSkills'] as List?) ?? const [];

                final List learnSkills =

                    (data?['learnSkills'] as List?) ?? const [];



// Step not done: basic profile info

// Name is provided during signup, so we check if bio or gender is empty

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