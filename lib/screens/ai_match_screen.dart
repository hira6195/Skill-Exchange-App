import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:skill_exchange/models/expert_model.dart';
import 'package:skill_exchange/screens/expert_profile_screen.dart';
import 'package:skill_exchange/screens/chat_screen.dart';
import 'package:skill_exchange/services/chat_service.dart';
import 'package:skill_exchange/services/ai_match_service.dart';

class AIMatchScreen extends StatefulWidget {
  const AIMatchScreen({super.key});

  @override
  State<AIMatchScreen> createState() => _AIMatchScreenState();
}

class _AIMatchScreenState extends State<AIMatchScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String myLearnSkill = '';
  String myTeachSkill = '';
  List<Map<String, dynamic>> matchedExperts = [];

  final ChatService _chatService = ChatService();
  final AIMatchService _aiMatchService = AIMatchService();
  String? _loadingChatExpertId;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color _primaryColor = Color(0xFF7C4DFF);
  static const Color _backgroundColor = Color(0xFFF4F5FA);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF1E1B29);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _fetchAndMatchRealSkills();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _extractSkill(Map<String, dynamic> data, List<String> possibleKeys) {
    for (String key in possibleKeys) {
      if (data.containsKey(key) && data[key] != null) {
        var value = data[key];
        if (value is List && value.isNotEmpty) {
          return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).join(', ');
        } else if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return '';
  }

  Future<void> _fetchAndMatchRealSkills() async {
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      Map<String, dynamic> userData = userDoc.exists ? (userDoc.data() as Map<String, dynamic>) : {};

      String userTeach = _extractSkill(userData, ['teachSkills', 'verifiedSkill', 'canTeach', 'teach', 'skill']);
      String userLearn = _extractSkill(userData, ['learnSkills', 'targetSkill', 'wantToLearn', 'learn', 'wantsToLearn']);

      setState(() {
        myLearnSkill = userLearn;
        myTeachSkill = userTeach;
      });

      List<ExpertModel> aiMatchedList = await _aiMatchService.fetchAndMatchExperts(
        userTargetSkill: userLearn,
        userCategory: userData['category'] ?? 'Technology',
        userCanTeachSkill: userTeach,
      );

      List<Map<String, dynamic>> finalMatches = [];
      for (var expert in aiMatchedList) {
        if (expert.uid == user.uid) continue;

        bool teachesWhatILearn = _checkSkillMatch(expert.skill, userLearn);
        bool wantsWhatITeach = _checkSkillMatch(expert.wantsToLearn, userTeach);
        int score = expert.matchPercentage;

        if (teachesWhatILearn && wantsWhatITeach) {
          score = 98;
        } else if (teachesWhatILearn || wantsWhatITeach) {
          score = score < 60 ? 78 : score;
        }

        finalMatches.add({
          'id': expert.uid,
          'name': expert.name,
          'teachSkill': expert.skill.isNotEmpty ? expert.skill : 'Flutter & Mobile App Dev',
          'learnSkill': expert.wantsToLearn.isNotEmpty ? expert.wantsToLearn : 'UI/UX Design',
          'image': expert.profileImage,
          'matchPercentage': '$score%',
          'matchScoreValue': score,
          'isPerfectSwap': (teachesWhatILearn && wantsWhatITeach) || score >= 90,
        });
      }

      finalMatches.sort((a, b) => (b['matchScoreValue'] as int).compareTo(a['matchScoreValue'] as int));

      if (mounted) {
        setState(() {
          matchedExperts = finalMatches;
          isLoading = false;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _checkSkillMatch(String skillA, String skillB) {
    if (skillA.isEmpty || skillB.isEmpty) return false;
    final aList = skillA.toLowerCase().split(RegExp(r'[,/ ]+'));
    final bList = skillB.toLowerCase().split(RegExp(r'[,/ ]+'));
    for (var a in aList) {
      if (a.length < 2) continue;
      for (var b in bList) {
        if (b.length < 2) continue;
        if (a.contains(b) || b.contains(a)) return true;
      }
    }
    return false;
  }

  Future<void> _handleChatNavigation(Map<String, dynamic> expert) async {
    final String expertId = expert['id'];
    setState(() => _loadingChatExpertId = expertId);
    try {
      final String chatId = await _chatService.createOrGetChat(expertId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chatId, receiverId: expertId, userName: expert['name']),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error initializing chat: $e')));
    } finally {
      if (mounted) setState(() => _loadingChatExpertId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('AI Mutual Skill Swap Engine', style: TextStyle(color: _textColor, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _primaryColor),
            onPressed: _fetchAndMatchRealSkills,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: _primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("My Profile Swap Criteria:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text("• Want to Learn: ${myLearnSkill.isNotEmpty ? myLearnSkill : 'Flutter'}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          Text("• Can Teach: ${myTeachSkill.isNotEmpty ? myTeachSkill : 'UI/UX Design'}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: matchedExperts.length,
                  itemBuilder: (context, index) {
                    final expert = matchedExperts[index];
                    return UserCardWidget(
                      expert: expert,
                      isLoadingChat: _loadingChatExpertId == expert['id'],
                      onChatPressed: () => _handleChatNavigation(expert),
                      onProfilePressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpertProfileScreen(
                            expertId: expert['id'],
                            expertName: expert['name'],
                            expertImage: expert['image'],
                            skill: expert['teachSkill'],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserCardWidget extends StatelessWidget {
  final Map<String, dynamic> expert;
  final bool isLoadingChat;
  final VoidCallback onChatPressed;
  final VoidCallback onProfilePressed;

  const UserCardWidget({
    super.key,
    required this.expert,
    required this.isLoadingChat,
    required this.onChatPressed,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF7C4DFF);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                backgroundImage: (expert['image'] != null && expert['image'].toString().isNotEmpty)
                    ? NetworkImage(expert['image'])
                    : null,
                child: (expert['image'] == null || expert['image'].toString().isEmpty)
                    ? Text(expert['name'][0].toUpperCase(), style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expert['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Teaches: ${expert['teachSkill']}', style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('Wants to Learn: ${expert['learnSkill']}', style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(12)),
                child: Text(expert['matchPercentage'], style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onChatPressed,
                  child: isLoadingChat
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Chat'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: onProfilePressed,
                  child: const Text('Profile', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}