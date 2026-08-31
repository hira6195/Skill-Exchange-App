import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_exchange/widgets/learner_dashboard_section.dart';

import 'ai_match_screen.dart';
import 'notification_screen.dart';
import 'session_history_screen.dart';
import 'pricing_plans_screen.dart';
import 'search_skills_screen.dart'; // Standard Search Screen Import
import 'verify_skill/verify_skill_screen.dart';
import 'auth/auth_gate.dart';
import 'package:skill_exchange/screens/teacher/session_requests_screen.dart';

class MyHomeScreen extends StatelessWidget {
  final Function(int)? onTabSelect;
  final VoidCallback? onSearchTap;

  const MyHomeScreen({
    super.key,
    this.onTabSelect,
    this.onSearchTap,
  });

  void _navigateToTabOrPush(BuildContext context, int tabIndex) {
    if (onTabSelect != null) {
      onTabSelect!(tabIndex);
    }
  }

  void _animatedNavigate(BuildContext context, Widget targetScreen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  void _handleSearchAction(BuildContext context) {
    if (onSearchTap != null) {
      onSearchTap!();
    } else {
      _animatedNavigate(context, const SearchSkillsScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xffF9F9FB),

      // Drawer Menu
      drawer: Drawer(
        child: StreamBuilder<DocumentSnapshot>(
          stream: userId != null
              ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots()
              : null,
          builder: (context, snapshot) {
            String name = "User";
            String email = "User Account";
            String photoUrl = "https://cdn-icons-png.flaticon.com/512/847/847969.png";

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null) {
                name = data['name'] ?? name;
                email = data['email'] ?? email;
                photoUrl = data['photoUrl'] ?? data['profileImage'] ?? photoUrl;
              }
            }

            return Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xff6A1B9A),
                  ),
                  accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: NetworkImage(photoUrl),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: Color(0xff6A1B9A)),
                  title: const Text("View Profile"),
                  subtitle: const Text("Manage your bio & skills"),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTabOrPush(context, 4); // Index 4 = Profile Tab
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined, color: Color(0xff6A1B9A)),
                  title: const Text("Skill Verification"),
                  subtitle: const Text("Upload documents & pass test"),
                  onTap: () {
                    Navigator.pop(context);
                    _animatedNavigate(context, const VerifySkillScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.star_border_rounded, color: Color(0xff6A1B9A)),
                  title: const Text("Pricing Plans"),
                  subtitle: const Text("Upgrade to Premium"),
                  onTap: () {
                    Navigator.pop(context);
                    _animatedNavigate(context, const PricingPlansScreen());
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text("Sign Out", style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthGate()),
                          (route) => false,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black87),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
            onPressed: () => _animatedNavigate(context, const NotificationScreen()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: userId != null
                  ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots()
                  : null,
              builder: (context, snapshot) {
                String userName = "Learner";
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null && data['name'] != null && data['name'].toString().trim().isNotEmpty) {
                    userName = data['name'];
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, $userName! 👋",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
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

            // Search Bar -> Navigates to Search Screen or Callback
            GestureDetector(
              onTap: () => _handleSearchAction(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Text("Search skills, teachers...", style: TextStyle(color: Colors.grey)),
                    Spacer(),
                    Icon(Icons.tune_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const LearnerProgressDashboardCard(),
            const SizedBox(height: 16),

            StreamBuilder<DocumentSnapshot>(
              stream: userId != null
                  ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots()
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
                      _animatedNavigate(
                        context,
                        const VerifySkillScreen(),
                      );
                    }
                  },
                  child: buildVerificationBadge(isPassed: isTestPassed),
                );
              },
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff8E24AA), Color(0xff6A1B9A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff6A1B9A).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
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
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Get priority matching, Unlimited sessions and more",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _animatedNavigate(context, const PricingPlansScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff6A1B9A),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Upgrade", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                    String status = (data['status'] ?? '').toString().toLowerCase();

                    if (status == 'scheduled' || status == 'upcoming' || status == 'pending') {
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
                        onTap: () => _animatedNavigate(context, const SessionRequestsScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSessionCard(
                        title: "Completed Sessions",
                        count: "$completedCount",
                        unit: completedCount == 1 ? "Session" : "Sessions",
                        onTap: () => _animatedNavigate(context, const SessionHistoryScreen()),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            const Text("Quick Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionItem(
                  icon: Icons.search_rounded,
                  label: "Search Skills",
                  color: Colors.deepPurple.shade50,
                  iconColor: Colors.deepPurple,
                  onTap: () => _handleSearchAction(context),
                ),
                _buildQuickActionItem(
                  icon: Icons.auto_awesome_rounded,
                  label: "AI Match",
                  color: Colors.blue.shade50,
                  iconColor: Colors.blue,
                  onTap: () => _animatedNavigate(context, const AIMatchScreen()),
                ),
                _buildQuickActionItem(
                  icon: Icons.assignment_turned_in_rounded,
                  label: "My Skills",
                  color: Colors.purple.shade50,
                  iconColor: Colors.purple,
                  onTap: () => _navigateToTabOrPush(context, 2), // Index 2: Bookings/Skills
                ),
                _buildQuickActionItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: "Messages",
                  color: Colors.red.shade50,
                  iconColor: Colors.redAccent,
                  onTap: () => _navigateToTabOrPush(context, 3), // Index 3: Chat
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff6A1B9A))),
                    Text(unit, style: const TextStyle(fontSize: 11, color: Color(0xff6A1B9A), fontWeight: FontWeight.w500)),
                  ],
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
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
        border: Border.all(color: isPassed ? Colors.green : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(isPassed ? Icons.verified : Icons.lock_outline_rounded, color: isPassed ? Colors.green : Colors.grey, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPassed ? "Skill Verified 🎉" : "Skill Unverified 🔒",
                  style: TextStyle(fontWeight: FontWeight.bold, color: isPassed ? Colors.green.shade800 : Colors.grey.shade700),
                ),
                Text(
                  isPassed ? "Assessment Passed Successfully!" : "Pass the test to unlock your badge.",
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}