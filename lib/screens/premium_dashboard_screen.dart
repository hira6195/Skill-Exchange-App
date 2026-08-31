import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_exchange/models/expert_model.dart';
import 'package:skill_exchange/services/ai_recommendation_service.dart';

// Navigation Imports
import 'ai_match_screen.dart';
import 'search_skills_screen.dart';
import 'my_certificate_screen.dart';
import 'recorded_sessions_screen.dart';
import 'expert_booking_screen.dart';
import 'notification_screen.dart';
import 'expert_profile_screen.dart';
import 'package:skill_exchange/screens/splash/splash_screen.dart';
import 'package:skill_exchange/screens/auth/login_screen.dart';

class PremiumDashboardScreen extends StatefulWidget {
  const PremiumDashboardScreen({super.key});

  @override
  State<PremiumDashboardScreen> createState() => _PremiumDashboardScreenState();
}

class _PremiumDashboardScreenState extends State<PremiumDashboardScreen> {
  final AIRecommendationService _aiService = AIRecommendationService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _navigateToSplash() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
    );
  }

  // ==========================================================
  // SIGN OUT DIALOG & LOGIC
  // ==========================================================
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Kya aap Sign Out karna chahte hain? Aapka account profile, session history, aur premium membership safe rahegi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _performSignOut();
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToSplash();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xffF3E5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff4A148C), size: 18),
                onPressed: _navigateToSplash,
              ),
            ),
          ),
          title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(_currentUserId).snapshots(),
            builder: (context, snapshot) {
              String userName = 'Premium User';
              if (snapshot.hasData && snapshot.data!.exists) {
                userName = snapshot.data!.data()?['name'] ?? 'Premium User';
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Hey, $userName',
                          style: const TextStyle(
                            color: Color(0xff1A1A24),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFD700),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Welcome to your elite workspace',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              );
            },
          ),
          actions: [
            // 1. Search Icon
            _buildCircleIconButton(
              icon: Icons.search_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchSkillsScreen()),
                );
              },
            ),
            // 2. Notification Icon
            _buildCircleIconButton(
              icon: Icons.notifications_none_rounded,
              badge: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
            // 3. Sign Out Icon
            _buildCircleIconButton(
              icon: Icons.logout_rounded,
              iconColor: Colors.redAccent,
              onTap: _showSignOutDialog,
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(_currentUserId).snapshots(),
          builder: (context, userSnapshot) {
            Map<String, dynamic>? userData = userSnapshot.data?.data();
            String userTargetSkill = userData?['targetSkill'] ?? userData?['interest'] ?? 'Developer';

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Subscription Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff6A1B9A), Color(0xff4A148C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.stars_rounded, color: Colors.amber, size: 30),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Subscription Active!',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Enjoy unlimited expert bookings and verified certifications.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Premium Benefits',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  // Benefits Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.5,
                    children: [
                      _buildBenefitCard(
                        'Priority Matching',
                        'Instant AI sync',
                        Icons.flash_on_rounded,
                        const Color(0xffFF9800),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AIMatchScreen()));
                        },
                      ),
                      _buildBenefitCard(
                        'Expert Sessions',
                        'Top 1% mentors',
                        Icons.school_rounded,
                        const Color(0xff8E24AA),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpertBookingScreen()));
                        },
                      ),
                      _buildBenefitCard(
                        'Verified Certificate',
                        'Claim & share',
                        Icons.workspace_premium_rounded,
                        const Color(0xff1E88E5),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => MyCertificateScreen(userId: _currentUserId)));
                        },
                      ),
                      _buildBenefitCard(
                        'Recorded Sessions',
                        'Watch anytime',
                        Icons.play_circle_fill_rounded,
                        const Color(0xffE53935),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RecordedSessionsScreen()));
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('AI Recommendation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpertBookingScreen()));
                        },
                        child: const Text('View All', style: TextStyle(color: Color(0xff6A1B9A))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dynamic Experts Stream Cards
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('experts').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      List<ExpertModel> rawExperts = snapshot.data!.docs.map((doc) => ExpertModel.fromFirestore(doc)).toList();
                      List<ExpertModel> aiRecommended = _aiService.getAIRecommendedExperts(
                        allExperts: rawExperts,
                        userTargetSkill: userTargetSkill,
                      );

                      return SizedBox(
                        height: 245,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: aiRecommended.length,
                          itemBuilder: (context, index) {
                            return _buildExpertCard(context, aiRecommended[index]);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
    Color iconColor = const Color(0xff4A148C),
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xffF3F4F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(String title, String subtitle, IconData icon, Color accentColor, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 22),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertCard(BuildContext context, ExpertModel expert) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(expert.profileImage.isNotEmpty ? expert.profileImage : 'https://via.placeholder.com/150'),
            ),
            const SizedBox(height: 8),
            Text(expert.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(expert.skill, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff6A1B9A)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpertProfileScreen(expert: expert),
                    ),
                  );
                },
                child: const Text('Book Session', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}