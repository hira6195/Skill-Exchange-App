import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_exchange/screens/skills/skills_learn_screen.dart';
import 'package:skill_exchange/widgets/premium_banner.dart'; // Premium Banner Import

class SkillsTeachScreen extends StatefulWidget {
  const SkillsTeachScreen({super.key});

  @override
  State<SkillsTeachScreen> createState() => _SkillsTeachScreenState();
}

class _SkillsTeachScreenState extends State<SkillsTeachScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController customSkillController = TextEditingController();
  bool isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> skills = [
    {"name": "UI/UX Design", "icon": Icons.design_services},
    {"name": "Figma", "icon": Icons.brush},
    {"name": "Photoshop", "icon": Icons.photo},
    {"name": "Web Design", "icon": Icons.web},
    {"name": "HTML", "icon": Icons.code},
    {"name": "CSS", "icon": Icons.css},
    {"name": "JavaScript", "icon": Icons.javascript},
    {"name": "React", "icon": Icons.developer_mode},
  ];

  List<String> selectedSkills = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  // Premium Dialog Opener using PremiumBanner
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
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                String newSkillName = customSkillController.text.trim();
                if (newSkillName.isNotEmpty) {
                  if (selectedSkills.isNotEmpty) {
                    Navigator.pop(dialogContext);
                    _openPremiumDialog();
                    return;
                  } else {
                    bool alreadyExists = skills.any((skill) =>
                    skill['name'].toString().toLowerCase() ==
                        newSkillName.toLowerCase());

                    if (!alreadyExists) {
                      setState(() {
                        skills.add({
                          "name": newSkillName,
                          "icon": Icons.star_rounded,
                        });
                      });
                    }
                    setState(() {
                      selectedSkills = [newSkillName];
                    });
                  }
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
              child: const Text(
                "Add",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> saveTeachSkills() async {
    final messenger = ScaffoldMessenger.of(context);

    if (selectedSkills.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Please select a skill to teach"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("No user is logged in"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set(
        {
          "teachSkills": selectedSkills,
        },
        SetOptions(merge: true),
      );

      messenger.showSnackBar(
        const SnackBar(
          content: Text("Teaching Skills Saved Successfully"),
          backgroundColor: Color(0xff6A1B9A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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

    final filteredSkills = skills.where((skill) {
      final name = (skill['name'] as String).toLowerCase();
      return name.contains(searchQuery);
    }).toList();

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
          onPressed: () {
            Navigator.maybePop(context);
          },
          tooltip: 'Back',
        ),
        title: const Text(
          "Skills You Can Teach",
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
                // Plan Banner (Tapping banner also opens Premium Popup)
                GestureDetector(
                  onTap: _openPremiumDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD8B4FE),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Free Plan: Select 1 skill to teach. Buy Premium for more.",
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
                ),
                const SizedBox(height: 20),

                // Search Bar
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
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search skills...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
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

                // Skills Chips
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: filteredSkills.map((skill) {
                        final String skillName = skill['name'] as String;
                        final IconData skillIcon = skill['icon'] as IconData;
                        bool isSelected = selectedSkills.contains(skillName);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: ChoiceChip(
                            avatar: Icon(
                              skillIcon,
                              size: 16,
                              color: isSelected ? Colors.white : primaryColor,
                            ),
                            label: Text(skillName),
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
                                  selectedSkills = [skillName];
                                } else {
                                  selectedSkills.remove(skillName);
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

                // Custom Skill Button
                OutlinedButton.icon(
                  onPressed: _showAddSkillDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    "Add Custom Skill",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(
                      color: primaryColor,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                      final navigator = Navigator.of(context);
                      bool success = await saveTeachSkills();
                      if (success && mounted) {
                        navigator.push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                            const SkillsLearnScreen(),
                            transitionsBuilder:
                                (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;
                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                          ),
                        );
                      }
                    },
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
                      "Next",
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