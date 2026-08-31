import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_exchange/screens/email_verification_screen.dart';
import 'package:skill_exchange/screens/auth/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  final Color primaryPurple = const Color(0xff6C25A8);
  final Color fieldBgColor = const Color(0xffF3F4F6);

  // ----------------------------------------------------------
  // EMAIL VALIDATION
  // ----------------------------------------------------------

  bool isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email.trim());
  }

  // ----------------------------------------------------------
  // PASSWORD VALIDATION
  // ----------------------------------------------------------

  String? validatePassword(String password) {
    if (password.length < 8) {
      return "Password must be at least 8 characters.";
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must contain at least one uppercase letter.";
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Password must contain at least one lowercase letter.";
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must contain at least one number.";
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(password)) {
      return "Password must contain at least one special character.";
    }

    return null;
  }

  // ----------------------------------------------------------
  // SIGN UP
  // ----------------------------------------------------------

  Future<void> signupUser() async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim().toLowerCase();
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage("Please fill in all fields.", isError: true);
      return;
    }

    if (name.length < 2) {
      showMessage("Please enter your full name.", isError: true);
      return;
    }

    if (!isValidEmail(email)) {
      showMessage("Please enter a valid email address.", isError: true);
      return;
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      showMessage(passwordError, isError: true);
      return;
    }

    if (password != confirmPassword) {
      showMessage("Passwords do not match.", isError: true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 1. CREATE FIREBASE AUTH ACCOUNT
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception("Unable to create account.");
      }

      // 2. SAVE DISPLAY NAME IN FIREBASE AUTH
      await user.updateDisplayName(name);
// 3. SEND FIREBASE VERIFICATION EMAIL
      await user.sendEmailVerification();

      // 4. CREATE FIRESTORE USER DOCUMENT
      await _firestore.collection("users").doc(user.uid).set({
        "uid": user.uid,
        "name": name,
        "email": email,
        "role": "Learner",
        "profileImage": "",
        "bio": "",
        "skills": [],
        "verified": false,
        "isEmailVerified": false,
        "rating": 0,
        "totalSessions": 0,
        "isProfileCompleted": false,
        "isPremium": false,
        "subscriptionPlan": "Basic",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 5. GO TO EMAIL VERIFICATION SCREEN
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const EmailVerificationScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("FIREBASE AUTH ERROR: [${e.code}] ${e.message}");
      if (!mounted) return;

      String message;
      switch (e.code) {
        case "email-already-in-use":
          message = "An account already exists with this email address.";
          break;
        case "invalid-email":
          message = "Please enter a valid email address.";
          break;
        case "weak-password":
          message = "Password is too weak. Please use a stronger password.";
          break;
        case "operation-not-allowed":
          message = "Email/password authentication is currently disabled.";
          break;
        case "network-request-failed":
          message = "Network error. Please check your internet connection.";
          break;
        case "too-many-requests":
          message = "Too many attempts. Please wait and try again.";
          break;
        default:
          message = e.message ?? "Unable to create your account.";
      }

      showMessage(message, isError: true);
    } catch (e) {
      debugPrint("FULL SIGNUP ERROR: $e");
      if (!mounted) return;

      showMessage("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ----------------------------------------------------------
  // MESSAGE
  // ----------------------------------------------------------

  void showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff2B59C3),
              Color(0xff8838BD),
              Color(0xff9B33B7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school,
                      size: 65,
                      color: primaryPurple,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Create Account",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Join Skill Exchange and start learning",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    buildInputField(
                      controller: nameController,
                      hint: "Full Name",
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 14),
                    buildInputField(
                      controller: emailController,
                      hint: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    buildPasswordField(
                      controller: passwordController,
                      hint: "Password",
                      hideText: hidePassword,
                      onToggle: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    buildPasswordField(
                      controller: confirmPasswordController,
                      hint: "Confirm Password",
                      hideText: hideConfirmPassword,
                      onToggle: () {
                        setState(() {
                          hideConfirmPassword = !hideConfirmPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Password: 8+ characters, uppercase, lowercase, number & special character",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : signupUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          "Create Account",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Login",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // INPUT FIELD
  // ----------------------------------------------------------

  Widget buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: primaryPurple,
          size: 20,
        ),
        filled: true,
        fillColor: fieldBgColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // PASSWORD FIELD
  // ----------------------------------------------------------

  Widget buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool hideText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: hideText,
      textInputAction: TextInputAction.next,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: primaryPurple,
          size: 20,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            hideText ? Icons.visibility_off : Icons.visibility,
            color: primaryPurple,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: fieldBgColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // DISPOSE
  // ----------------------------------------------------------

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}