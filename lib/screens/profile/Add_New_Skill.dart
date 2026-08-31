import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_exchange/widgets/premium_banner.dart';

class AddNewSkillScreen extends StatefulWidget {
  const AddNewSkillScreen({super.key});

  @override
  State<AddNewSkillScreen> createState() => _AddNewSkillScreenState();
}

class _AddNewSkillScreenState extends State<AddNewSkillScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _skillNameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _selectedCategory = "Design";
  String? _selectedLevel = "Beginner";
  String _skillType = "teach"; // 'teach' or 'learn'

  bool _isSaving = false;

  final List<String> _categories = [
    "Design",
    "Development",
    "Marketing",
    "Business",
    "Music",
    "Languages",
    "Photography"
  ];
  final List<String> _levels = ["Beginner", "Intermediate", "Advanced"];

  static const Color _primaryColor = Color(0xFF7C4DFF);
  static const Color _backgroundColor = Color(0xFFF4F5FA);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF1E1B29);

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

  @override
  void dispose() {
    _animationController.dispose();
    _skillNameController.dispose();
    _descController.dispose();
    super.dispose();
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

  Future<void> _saveSkillToFirestore() async {
    final user = _auth.currentUser;
    final skillName = _skillNameController.text.trim();

    if (user == null || skillName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a skill name"),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String dbField = _skillType == "teach" ? "teachSkills" : "learnSkills";

      Map<String, dynamic> skillData = {
        "name": skillName,
        "category": _selectedCategory ?? "General",
        "level": _selectedLevel ?? "Beginner",
        "description": _descController.text.trim(),
        "createdAt": Timestamp.now(),
      };

      // Free Plan: Purana skill REPLACE ho kar naya skill Overwrite ho jayega
      await _firestore.collection("users").doc(user.uid).update({
        dbField: [skillData]
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Skill updated successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating skill: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textColor,
              size: 18,
            ),
            onPressed: _handleBackNavigation,
            tooltip: 'Back',
          ),
        ),
        title: const Text(
          "Update Your Skill",
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Alert Banner
                GestureDetector(
                  onTap: _openPremiumDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD8B4FE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: _primaryColor, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Free Plan: Saving will replace your existing skill. Upgrade for multiple skills.",
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openPremiumDialog,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Upgrade",
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Skill Mode Switcher (Teach vs Learn)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _skillType = "teach"),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _skillType == "teach"
                                  ? _primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "I Can Teach",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _skillType == "teach"
                                      ? Colors.white
                                      : _textColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _skillType = "learn"),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _skillType == "learn"
                                  ? _primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "I Want to Learn",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _skillType == "learn"
                                      ? Colors.white
                                      : _textColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Main Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skill Name Input
                      _buildLabel("Skill Name", Icons.stars_rounded),
                      TextField(
                        controller: _skillNameController,
                        style: const TextStyle(fontSize: 15, color: _textColor),
                        decoration: _buildInputDecoration(
                          hintText: "e.g. Flutter Development, UI Design",
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Category Dropdown
                      _buildLabel("Category", Icons.category_outlined),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        style: const TextStyle(fontSize: 15, color: _textColor),
                        dropdownColor: _cardColor,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: _primaryColor),
                        decoration: _buildInputDecoration(hintText: "Select Category"),
                        items: _categories
                            .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                      ),
                      const SizedBox(height: 18),

                      // Level Dropdown
                      _buildLabel("Proficiency Level", Icons.bar_chart_rounded),
                      DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        style: const TextStyle(fontSize: 15, color: _textColor),
                        dropdownColor: _cardColor,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: _primaryColor),
                        decoration: _buildInputDecoration(hintText: "Select Level"),
                        items: _levels
                            .map((lvl) => DropdownMenuItem(
                          value: lvl,
                          child: Text(lvl),
                        ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedLevel = val),
                      ),
                      const SizedBox(height: 18),

                      // Description Field
                      _buildLabel("Description (Optional)", Icons.description_outlined),
                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 15, color: _textColor),
                        decoration: _buildInputDecoration(
                          hintText:
                          "Describe your experience or what you expect to learn...",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Skill Primary Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSkillToFirestore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      elevation: 2,
                      shadowColor: _primaryColor.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sync_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Update Skill",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Premium Upgrade Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _openPremiumDialog,
                    icon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 20),
                    label: const Text(
                      "Want to add more skills? Upgrade to Premium",
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.purple.shade200),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  Widget _buildLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8F9FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryColor, width: 1.8),
      ),
    );
  }
}