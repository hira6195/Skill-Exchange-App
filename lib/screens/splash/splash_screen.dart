import 'package:flutter/material.dart';
// Note: Apne folder structure ke mutabiq sahi import path check kar lijiyega
import 'package:skill_exchange/screens/auth/login_screen.dart';

// Humne class ka naam 'SplashScreen' (S capital) kar diya hai standard ke mutabiq
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? k}) : super(key: k);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E6AD4), // Top Blue
              Color(0xFF8A30AC), // Bottom Purple
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              // Logo and Title Section
              Column(
                children: [
                  const Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Skill Exchange',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn, Teach, Grow Together',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),

              // Bottom Button Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  children: [
                    // "Let's Get Started" Button
                    GestureDetector(
                      onTap: () {
                        // ENABLED: Ab click karne par yeh Login Screen par chala jayega
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "Let's Get Started",
                              style: TextStyle(
                                color: Color(0xFF8A30AC),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF8A30AC),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Explore More
                    Column(
                      children: [
                        Icon(
                          Icons.arrow_circle_down_outlined,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Explore More',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}