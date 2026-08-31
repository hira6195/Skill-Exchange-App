import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_exchange/screens/profile/user_profile_screen.dart';
import 'package:skill_exchange/widgets/premium_banner.dart';

class SkillsLearnScreen extends StatefulWidget {
  const SkillsLearnScreen({super.key});

  @override
  State<SkillsLearnScreen> createState() => _SkillsLearnScreenState();
}

class _SkillsLearnScreenState extends State<SkillsLearnScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController customSkillController = TextEditingController();
  bool isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<String> allSkills = [
    "Information Security",
    "Web Development",
    "JavaScript",
    "AI",
    "Python",
    "Machine Learning",
    "Flutter",
    "UI/UX Design",
    "Figma",
    "Photoshop",
    "HTML",
    "CSS",
    "React",
  ];

  List<String> filteredSkills = [];
  List<String> selectedSkills = [];

  @override
  void initState() {
    super.initState();
    filteredSkills = List.from(allSkills);
    loadSkills();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> loadSkills() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data["learnSkills"] != null) {
          selectedSkills = List<String>.from(data["learnSkills"]);
          if (selectedSkills.length > 1) {
            selectedSkills = [selectedSkills.first];
          }
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  void filterSkills(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        filteredSkills = List.from(allSkills);
      } else {
        filteredSkills = allSkills
            .where((skill) =>
            skill.toLowerCase().contains(value.toLowerCase()))
            .toList();
      }
    });
  }

  void _openPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16),
        child: PremiumBanner(),
      ),
    );
  }

  void _showAddSkillDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Add Custom Skill",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B29),
            ),
          ),
          content: TextField(
            controller: customSkillController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Enter skill name",
              filled: true,
              fillColor: const Color(0xFFF8F9FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                customSkillController.clear();
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                String newSkillName = customSkillController.text.trim();
                if (newSkillName.isNotEmpty) {
                  if (selectedSkills.isNotEmpty) {
                    Navigator.pop(dialogContext);
                    _openPremiumDialog();
                    return;
                  }

                  if (!allSkills.any((s) =>
                  s.toLowerCase() == newSkillName.toLowerCase())) {
                    setState(() {
                      allSkills.add(newSkillName);
                      filteredSkills.add(newSkillName);
                    });
                  }

                  setState(() {
                    selectedSkills = [newSkillName];
                  });

                  customSkillController.clear();
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff6A1B9A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveSkills() async {
    final messenger = ScaffoldMessenger.of(context);

    if (selectedSkills.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Please select a skill to learn"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set(
        {
          "learnSkills": selectedSkills,
          "isProfileCompleted": true,
        },
        SetOptions(merge: true),
      );

      messenger.showSnackBar(
        const SnackBar(
          content: Text("Skills saved! Redirecting to profile..."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // FIX: Stack reset karke seedha UserProfileScreen kholna
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const UserProfileScreen(),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    customSkillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6A1B9A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E1B29),
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Back to Teaching Skills',
        ),
        title: const Text(
          "Desired Learning Skills",
          style: TextStyle(
            color: Color(0xFF1E1B29),
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8B4FE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Free Plan: Select 1 skill. Upgrade to Premium for unlimited skills.",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSkills,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search skills...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: filteredSkills.map((skill) {
                        bool isSelected = selectedSkills.contains(skill);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: ChoiceChip(
                            label: Text(skill),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  if (selectedSkills.isNotEmpty && !isSelected) {
                                    _openPremiumDialog();
                                    return;
                                  }
                                  selectedSkills = [skill];
                                } else {
                                  selectedSkills.remove(skill);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _showAddSkillDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    "Add Custom Skill",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : saveSkills,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      elevation: 2,
                      shadowColor: primaryColor.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      "Continue to Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}