import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:skill_exchange/screens/auth/login_screen.dart';
import 'package:skill_exchange/screens/auth/signup_screen.dart';


import 'auth/auth_gate.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _verificationTimer;
  Timer? _cooldownTimer;

  bool isVerified = false;
  bool isChecking = false;

  bool _canResendEmail = true;
  int _resendCooldown = 60;

  @override
  void initState() {
    super.initState();

    // Start checking verification status automatically.
    _startVerificationChecker();
  }

  // ==========================================================
  // AUTOMATIC EMAIL VERIFICATION CHECKER
  // ==========================================================

  void _startVerificationChecker() {
    _verificationTimer?.cancel();

    _verificationTimer = Timer.periodic(
      const Duration(seconds: 12),
          (_) {
        checkEmailVerification(isManual: false);
      },
    );
  }

  Future<void> checkEmailVerification({
    bool isManual = false,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      _showMessage(
        "Session expired. Please login again.",
        isError: true,
      );

      _goToLogin();
      return;
    }

    try {
      // Refresh Firebase user information.
      await user.reload();

      final User? updatedUser = _auth.currentUser;

      if (updatedUser == null) {
        if (!mounted) return;

        _showMessage(
          "Session expired. Please login again.",
          isError: true,
        );

        _goToLogin();
        return;
      }

      // ======================================================
      // EMAIL IS VERIFIED
      // ======================================================

      if (updatedUser.emailVerified) {
        _verificationTimer?.cancel();
        _cooldownTimer?.cancel();

        if (mounted) {
          setState(() {
            isVerified = true;
          });
        }

        // Update Firestore.
        await _firestore
            .collection("users")
            .doc(updatedUser.uid)
            .set(
          {
            "isEmailVerified": true,
            "verified": true,
            "emailVerifiedAt": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // The user stays logged in after verification — no reason
        // to force them to log in again manually. AuthGate takes
        // over from here and decides whether they need Profile,
        // Skills, or the Dashboard next.
        if (!mounted) return;

        _showMessage(
          "Email verified successfully!",
          isError: false,
        );

        _goToApp();

        return;
      }

      // ======================================================
      // EMAIL NOT VERIFIED
      // ======================================================

      if (isManual) {
        _showMessage(
          "Email is not verified yet. Please check your inbox.",
          isError: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "Firebase verification error: [${e.code}] ${e.message}",
      );

      if (!mounted) return;

      if (e.code == "too-many-requests") {
        if (isManual) {
          _showMessage(
            "Too many requests. Please wait a moment and try again.",
            isError: true,
          );
        }
      } else if (e.code == "network-request-failed") {
        if (isManual) {
          _showMessage(
            "Network error. Please check your internet connection.",
            isError: true,
          );
        }
      } else if (isManual) {
        _showMessage(
          e.message ?? "Unable to check email verification.",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint(
        "Email verification check error: $e",
      );

      if (mounted && isManual) {
        _showMessage(
          "Unable to check verification status.",
          isError: true,
        );
      }
    }
  }

  // ==========================================================
  // MANUAL VERIFICATION CHECK
  // ==========================================================

  Future<void> manualVerificationCheck() async {
    if (isChecking) return;

    setState(() {
      isChecking = true;
    });

    await checkEmailVerification(isManual: true);

    if (mounted) {
      setState(() {
        isChecking = false;
      });
    }
  }

  // ==========================================================
  // RESEND VERIFICATION EMAIL
  // ==========================================================

  void _startCooldownTimer() {
    if (!mounted) return;

    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60;
    });

    _cooldownTimer?.cancel();

    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendCooldown <= 1) {
          timer.cancel();

          setState(() {
            _resendCooldown = 0;
            _canResendEmail = true;
          });
        } else {
          setState(() {
            _resendCooldown--;
          });
        }
      },
    );
  }

  Future<void> resendVerificationEmail() async {
    if (!_canResendEmail) return;

    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        "Session expired. Please login again.",
        isError: true,
      );

      _goToLogin();
      return;
    }

    try {
      await user.sendEmailVerification();

      _startCooldownTimer();

      _showMessage(
        "Verification email sent! Check your inbox and spam folder.",
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "Resend verification error: [${e.code}] ${e.message}",
      );

      if (e.code == "network-request-failed") {
        _showMessage(
          "Internet connection error. Please check your network.",
          isError: true,
        );
      } else if (e.code == "too-many-requests") {
        _showMessage(
          "Too many requests. Please wait a few minutes.",
          isError: true,
        );

        _startCooldownTimer();
      } else {
        _showMessage(
          e.message ?? "Failed to resend verification email.",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint(
        "Resend email error: $e",
      );

      _showMessage(
        "An unexpected error occurred. Please try again.",
        isError: true,
      );
    }
  }

  // ==========================================================
  // SIGN OUT
  // ==========================================================

  Future<void> handleSignOut() async {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();

    await _auth.signOut();

    if (!mounted) return;

    _goToLogin();
  }

  // ==========================================================
  // GO TO LOGIN
  // ==========================================================

  void _goToLogin() {
    if (!mounted) return;

    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  // ==========================================================
  // GO TO APP (AuthGate)
  // ==========================================================
  //
  // Used after successful verification, where the user should
  // stay logged in and continue straight into the app — AuthGate
  // decides whether Profile, Skills, or Dashboard comes next.
  // ==========================================================

  void _goToApp() {
    if (!mounted) return;

    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AuthGate(),
      ),
          (route) => false,
    );
  }

  // ==========================================================
  // SHOW MESSAGE
  // ==========================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.red.shade700 : const Color(0xff6A1B9A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffF7F5FF),

      appBar: AppBar(
        title: const Text(
          "Verify Your Email",
          style: TextStyle(
            color: Color(0xff6A1B9A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.black87,
            ),
            onPressed: handleSignOut,
            tooltip: "Logout",
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const SizedBox(height: 25),

              // ==================================================
              // ICON
              // ==================================================

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xff6A1B9A)
                      .withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: Color(0xff6A1B9A),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                "Verify Your Email",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "We've sent a verification link to:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // EMAIL
              // ==================================================

              Text(
                user?.email ?? "your email address",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff6A1B9A),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // INFO BOX
              // ==================================================

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade300,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Open your email and click the verification link. "
                            "If you don't see it, check your Spam or Junk folder.",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // MANUAL CHECK BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                  isChecking ? null : manualVerificationCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff6A1B9A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isChecking
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  label: Text(
                    isChecking
                        ? "Checking..."
                        : "I've Verified My Email",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // RESEND BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _canResendEmail
                      ? resendVerificationEmail
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _canResendEmail
                          ? const Color(0xff6A1B9A)
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.send_outlined,
                    color: _canResendEmail
                        ? const Color(0xff6A1B9A)
                        : Colors.grey.shade400,
                  ),
                  label: Text(
                    _canResendEmail
                        ? "Resend Verification Email"
                        : "Resend in ${_resendCooldown}s",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _canResendEmail
                          ? const Color(0xff6A1B9A)
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}