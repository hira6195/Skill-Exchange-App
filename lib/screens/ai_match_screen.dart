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

class _AIMatchScreenState extends State<AIMatchScreen> {
  bool isLoading = true;
  String myLearnSkill = '';
  String myTeachSkill = '';
  List<Map<String, dynamic>> matchedExperts = [];

  final ChatService _chatService = ChatService();
  final AIMatchService _aiMatchService = AIMatchService();
  String? _loadingChatExpertId;

  @override
  void initState() {
    super.initState();
    _fetchAndMatchRealSkills();
  }

  // Enhanced extraction to support dynamic lists, maps and raw strings
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
        setState(() => isLoading = false);
        return;
      }

      // 1. Logged-in User Data Fetch
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic> userData =
      userDoc.exists ? (userDoc.data() as Map<String, dynamic>) : {};

      // Checked all profile keys used across user screens
      String userTeach = _extractSkill(userData, [
        'teachSkills',
        'verifiedSkill',
        'teachingSkill',
        'skillsToTeach',
        'skill',
        'canTeach',
        'teach',
        'teachingSkills',
        'expertSkill',
        'primarySkill',
        'Expert at'
      ]);

      String userLearn = _extractSkill(userData, [
        'learnSkills',
        'learningSkill',
        'skillsToLearn',
        'targetSkill',
        'wantToLearn',
        'learn',
        'learningSkills',
        'skillToLearn'
      ]);

      setState(() {
        myLearnSkill = userLearn;
        myTeachSkill = userTeach;
      });

      // User Profile Incomplete Check
      if (userLearn.isEmpty && userTeach.isEmpty) {
        setState(() {
          matchedExperts = [];
          isLoading = false;
        });
        return;
      }

      // 2. AI Swap Matching Service Call
      List<ExpertModel> aiMatchedList = await _aiMatchService.fetchAndMatchExperts(
        userTargetSkill: userLearn,
        userCategory: userData['category'] ?? 'Technology',
        userCanTeachSkill: userTeach,
      );

      // 3. Prepare Display List
      List<Map<String, dynamic>> finalMatches = [];

      for (var expert in aiMatchedList) {
        if (expert.uid == user.uid) continue; // Current user ko list se skip karo

        bool teachesWhatILearn = _checkSkillMatch(expert.skill, userLearn);
        bool wantsWhatITeach = _checkSkillMatch(expert.wantsToLearn, userTeach);

        int calculatedScore = expert.matchPercentage;

        // Dynamic score boost for swaps
        if (teachesWhatILearn && wantsWhatITeach) {
          calculatedScore = (calculatedScore < 90) ? 95 : calculatedScore;
        } else if (teachesWhatILearn || wantsWhatITeach) {
          calculatedScore = (calculatedScore < 60) ? 75 : calculatedScore;
        }

        finalMatches.add({
          'id': expert.uid,
          'name': expert.name,
          'teachSkill': expert.skill.isNotEmpty ? expert.skill : 'Not Specified',
          'learnSkill': expert.wantsToLearn.isNotEmpty ? expert.wantsToLearn : 'Not Specified',
          'image': expert.profileImage,
          'rating': expert.rating,
          'matchPercentage': '$calculatedScore%',
          'matchScoreValue': calculatedScore,
          'isPerfectSwap': (teachesWhatILearn && wantsWhatITeach) || calculatedScore >= 90,
        });
      }

      finalMatches.sort((a, b) => (b['matchScoreValue'] as int).compareTo(a['matchScoreValue'] as int));

      if (mounted) {
        setState(() {
          matchedExperts = finalMatches;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error matching skills: $e');
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
          builder: (context) => ChatScreen(
            chatId: chatId,
            receiverId: expertId,
            userName: expert['name'],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingChatExpertId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        title: const Text(
          'AI Skill Swap Match',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchAndMatchRealSkills,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Analyzing Real Skill Swaps with AI...'),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Profile Skill Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horizontal_circle_rounded,
                      color: Colors.deepPurple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Verified Profile',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87),
                            children: [
                              const TextSpan(text: 'Want to Learn: '),
                              TextSpan(
                                text: myLearnSkill.isNotEmpty
                                    ? myLearnSkill
                                    : 'Not Set',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple),
                              ),
                              const TextSpan(text: ' | Can Teach: '),
                              TextSpan(
                                text: myTeachSkill.isNotEmpty
                                    ? myTeachSkill
                                    : 'Not Set',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            matchedExperts.isEmpty
                ? Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off,
                        size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      'No Skill Swap Partners Found',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: Text(
                        'Make sure your profile has skills added under "Skills / Tech" and "Skills / Learn".',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: matchedExperts.length,
                itemBuilder: (context, index) {
                  final expert = matchedExperts[index];
                  final bool isChatLoading =
                      _loadingChatExpertId == expert['id'];
                  final bool isPerfectSwap = expert['isPerfectSwap'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isPerfectSwap
                          ? BorderSide(
                          color: Colors.green.shade400,
                          width: 1.5)
                          : BorderSide.none,
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor:
                                Colors.deepPurple.shade100,
                                backgroundImage:
                                expert['image'].isNotEmpty
                                    ? NetworkImage(
                                    expert['image'])
                                    : null,
                                child: expert['image'].isEmpty
                                    ? Text(
                                  expert['name'][0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                    FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      expert['name'],
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Teaches: ${expert['teachSkill']}',
                                      style: const TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Wants to Learn: ${expert['learnSkill']}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isPerfectSwap
                                      ? Colors.green.shade50
                                      : Colors.purple.shade50,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPerfectSwap
                                        ? Colors.green.shade200
                                        : Colors.purple.shade200,
                                  ),
                                ),
                                child: Text(
                                  '${expert['matchPercentage']}',
                                  style: TextStyle(
                                    color: isPerfectSwap
                                        ? Colors.green.shade700
                                        : Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isChatLoading
                                      ? null
                                      : () => _handleChatNavigation(
                                      expert),
                                  icon: isChatLoading
                                      ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.deepPurple,
                                    ),
                                  )
                                      : const Icon(
                                      Icons
                                          .chat_bubble_outline_rounded,
                                      size: 18),
                                  label: Text(isChatLoading
                                      ? 'Connecting...'
                                      : 'Chat'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExpertProfileScreen(
                                              expertId: expert['id'],
                                              expertName: expert['name'],
                                              expertImage:
                                              expert['image'],
                                              skill: expert['teachSkill'],
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text('View Profile'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}