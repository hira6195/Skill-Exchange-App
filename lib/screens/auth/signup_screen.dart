import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_exchange/screens/auth/auth_gate.dart';
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
  final TextEditingController confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;
  bool isGoogleLoading = false;

  final Color primaryPurple = const Color(0xff6C25A8);
  final Color fieldBgColor = const Color(0xffF3F4F6);

  bool isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

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

  // ==========================================================
  // MANUAL SIGNUP LOGIC (INCLUDES EMAIL VERIFICATION SCREEN)
  // ==========================================================
  Future<void> signupUser() async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim().toLowerCase();
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
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
      // 1. Create user in Firebase Authentication[cite: 5]
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) throw Exception("Unable to create account.");

      await user.updateDisplayName(name);

      // 2. Save record to Firestore FIRST so the document definitely exists[cite: 5]
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

      // 3. Send email verification after Firestore document is successfully created[cite: 5]
      await user.sendEmailVerification();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const EmailVerificationScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
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
          message = "Password is too weak.";
          break;
        default:
          message = e.message ?? "Unable to create account.";
      }
      showMessage(message, isError: true);
    } catch (e) {
      if (!mounted) return;
      showMessage("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ==========================================================
  // PROFESSIONAL GOOGLE SIGN IN LOGIC (SHOWS EMAIL PICKER POPUP)
  // ==========================================================
  Future<void> signUpWithGoogle() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Forces the Google account chooser pop-up to appear every time
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          isGoogleLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

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
            "verified": true,
            "isEmailVerified": true, // Automatically verified by Google
            "rating": 0,
            "totalSessions": 0,
            "isProfileCompleted": false,
            "isPremium": false,
            "subscriptionPlan": "Basic",
            "createdAt": FieldValue.serverTimestamp(),
          });
        }
      }

      if (!mounted) return;

      // Direct entry to main app
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showMessage("Google Sign-In failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => isGoogleLoading = false);
    }
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                    Icon(Icons.school, size: 65, color: primaryPurple),
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
                      onToggle: () => setState(() => hidePassword = !hidePassword),
                    ),
                    const SizedBox(height: 14),
                    buildPasswordField(
                      controller: confirmPasswordController,
                      hint: "Confirm Password",
                      hideText: hideConfirmPassword,
                      onToggle: () => setState(() => hideConfirmPassword = !hideConfirmPassword),
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
                        onPressed: (isLoading || isGoogleLoading) ? null : signupUser,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text("OR", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: (isLoading || isGoogleLoading) ? null : signUpWithGoogle,
                        child: isGoogleLoading
                            ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: primaryPurple,
                            strokeWidth: 2,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://cdn-icons-png.flaticon.com/512/300/300221.png',
                              height: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Continue with Google",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
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
        prefixIcon: Icon(icon, color: primaryPurple, size: 20),
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
        prefixIcon: Icon(Icons.lock_outline, color: primaryPurple, size: 20),
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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}