import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_exchange/widgets/learner_dashboard_section.dart';

// Relative Imports
import 'ai_match_screen.dart';
import 'assessment/assessment_intro_screen.dart';
import 'chat_list_screen.dart';
import 'notification_screen.dart';
import 'search_skills_screen.dart';
import 'session_history_screen.dart';
import 'pricing_plans_screen.dart';
import 'package:skill_exchange/screens/learner/upcoming_sessions_screen.dart';

class MyHomeScreen extends StatelessWidget {
  final VoidCallback? onSearchTap;

  const MyHomeScreen({
    super.key,
    this.onSearchTap,
  });

  void _navigateToSearch(BuildContext context) {
    if (onSearchTap != null) {
      onSearchTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SearchSkillsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DYNAMIC USER NAME FETCHING FROM FIRESTORE
            StreamBuilder<DocumentSnapshot>(
              stream: userId != null
                  ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots()
                  : null,
              builder: (context, snapshot) {
                String userName = "Learner"; // Default fallback

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null &&
                      data.containsKey('name') &&
                      data['name'].toString().trim().isNotEmpty) {
                    userName = data['name'];
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, $userName! 👋",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ready to learn and grow today?",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Search Bar Button
            GestureDetector(
              onTap: () => _navigateToSearch(context),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Text("Search skills, teachers...",
                        style: TextStyle(color: Colors.grey)),
                    Spacer(),
                    Icon(Icons.tune, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const LearnerProgressDashboardCard(),
            const SizedBox(height: 16),

            // FIREBASE STREAM BUILDER FOR VERIFICATION
            StreamBuilder<DocumentSnapshot>(
              stream: userId != null
                  ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots()
                  : null,
              builder: (context, snapshot) {
                bool isTestPassed = false;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  isTestPassed = data?['isTestPassed'] ?? false;
                }

                return GestureDetector(
                  onTap: () {
                    if (!isTestPassed) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssessmentIntroScreen(
                            skillName: '',
                            certificateText: '',
                          ),
                        ),
                      );
                    }
                  },
                  child: buildVerificationBadge(isPassed: isTestPassed),
                );
              },
            ),

            const SizedBox(height: 20),

            // Premium Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff8E24AA), Color(0xff6A1B9A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text("👑", style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Unlock Premium Features",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Get priority matching, Unlimited sessions and more",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PricingPlansScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff6A1B9A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Upgrade Now",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Dynamic Sessions Cards (Realtime Firebase Stream)
            StreamBuilder<QuerySnapshot>(
              stream: userId != null
                  ? FirebaseFirestore.instance
                  .collection('sessions')
                  .where('learnerId', isEqualTo: userId)
                  .snapshots()
                  : null,
              builder: (context, snapshot) {
                int upcomingCount = 0;
                int completedCount = 0;

                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    String status =
                    (data['status'] ?? '').toString().toLowerCase();

                    if (status == 'scheduled' ||
                        status == 'upcoming' ||
                        status == 'pending') {
                      upcomingCount++;
                    } else if (status == 'completed') {
                      completedCount++;
                    }
                  }
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildSessionCard(
                        title: "Upcoming Sessions",
                        count: "$upcomingCount",
                        unit: upcomingCount == 1 ? "Session" : "Sessions",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const UpcomingSessionsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSessionCard(
                        title: "Completed Sessions",
                        count: "$completedCount",
                        unit: completedCount == 1 ? "Session" : "Sessions",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SessionHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Quick Actions Section
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionItem(
                  icon: Icons.search,
                  label: "Search Skills",
                  color: Colors.deepPurple.shade50,
                  iconColor: Colors.deepPurple,
                  onTap: () => _navigateToSearch(context),
                ),
                _buildQuickActionItem(
                  icon: Icons.shield,
                  label: "AI Match",
                  color: Colors.blue.shade50,
                  iconColor: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIMatchScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionItem(
                  icon: Icons.assignment_turned_in,
                  label: "My Skills",
                  color: Colors.purple.shade50,
                  iconColor: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssessmentIntroScreen(
                          skillName: '',
                          certificateText: '',
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionItem(
                  icon: Icons.chat_bubble,
                  label: "Messages",
                  color: Colors.red.shade50,
                  iconColor: Colors.redAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatListScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required String title,
    required String count,
    required String unit,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff6A1B9A),
                      ),
                    ),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff6A1B9A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildVerificationBadge({required bool isPassed}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPassed ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPassed ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.verified : Icons.lock_outline,
            color: isPassed ? Colors.green : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPassed ? "Skill Verified 🎉" : "Skill Unverified 🔒",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                    isPassed ? Colors.green.shade800 : Colors.grey.shade700,
                  ),
                ),
                Text(
                  isPassed
                      ? "Assessment Passed Successfully!"
                      : "Pass the test to unlock your badge.",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}