import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:skill_exchange/screens/skills/skills_learn_screen.dart';

// ==========================================================
// CONFIG / SERVICES / IMPORTS
// ==========================================================
import 'api_key.dart';
import 'firebase_options.dart';
import 'package:skill_exchange/services/session_manager.dart';

// SCREENS
import 'package:skill_exchange/screens/splash/splash_screen.dart';
import 'package:skill_exchange/screens/auth/signup_screen.dart';
import 'package:skill_exchange/screens/email_verification_screen.dart';
import 'package:skill_exchange/screens/main_navigation_screen.dart';
import 'package:skill_exchange/screens/skills/skills_teach_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        primaryColor: const Color(0xff6A1B9A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff6A1B9A),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class MainAppWrapper extends StatefulWidget {
  const MainAppWrapper({super.key});

  @override
  State<MainAppWrapper> createState() => _MainAppWrapperState();
}

class _MainAppWrapperState extends State<MainAppWrapper> {
  void _handleTimeout() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    SessionManager.startSessionTimer(_handleTimeout);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        SessionManager.resetTimer(_handleTimeout);
      },
      child: const AuthGate(),
    );
  }
}

Future<void> saveUserProfileToFirestore({
  required String name,
  required String skill,
  Map<String, dynamic>? extraData,
}) async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("Cannot save profile: No authenticated user.");
      return;
    }

    final Map<String, dynamic> userData = {
      'uid': user.uid,
      'email': user.email ?? '',
      'name': name,
      'skill': skill,
      'isProfileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (extraData != null) {
      userData.addAll(extraData);
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));

    debugPrint("User profile saved successfully.");
  } catch (e) {
    debugPrint("Error saving user profile to Firestore: $e");
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
            ),
          );
        }

        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const SignupScreen();
        }

        final User user = authSnapshot.data!;

        return FutureBuilder<void>(
          future: user.reload(),
          builder: (context, reloadSnapshot) {
            if (reloadSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
                ),
              );
            }

            final User? refreshedUser = FirebaseAuth.instance.currentUser;

            if (refreshedUser == null) {
              return const SignupScreen();
            }

            if (!refreshedUser.emailVerified) {
              return const EmailVerificationScreen();
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(refreshedUser.uid)
                  .get(),
              builder: (context, firestoreSnapshot) {
                if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
                    ),
                  );
                }

                if (firestoreSnapshot.hasData && firestoreSnapshot.data!.exists) {
                  final data = firestoreSnapshot.data!.data() as Map<String, dynamic>?;
                  final bool isProfileCompleted = data?['isProfileCompleted'] ?? false;

                  if (!isProfileCompleted) {
                    return const SkillsTeachScreen();
                  }

                  return const MainNavigationScreen();
                }

                return const SkillsLearnScreen();
              },
            );
          },
        );
      },
    );
  }
}