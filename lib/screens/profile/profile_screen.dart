import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_exchange/screens/skills/skills_teach_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController expertAtController = TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isExistingDataLoading = true;
  bool isSaving = false;

  final String _maleAvatar = 'https://cdn-icons-png.flaticon.com/512/4140/4140048.png';
  final String _femaleAvatar = 'https://cdn-icons-png.flaticon.com/512/4140/4140047.png';
  final String _defaultAvatar = 'https://cdn-icons-png.flaticon.com/512/847/847969.png';

  String _selectedGender = 'female';
  String _currentAvatarUrl = 'https://cdn-icons-png.flaticon.com/512/4140/4140047.png';

  // ignore: spell_check_on_word_send_intent
  final List<String> _maleKeywords = [
    'ali', 'khan', 'ahmed', 'ibrahim', 'muhammad', 'mohd', 'hassan', 'hussain',
    'umar', 'usman', 'hamza', 'bilal', 'mr', 'singh', 'kumar', 'raza', 'saad'
  ];

  // ignore: spell_check_on_word_send_intent
  final List<String> _femaleKeywords = [
    'fatima', 'ayesha', 'zoya', 'sara', 'sana', 'marium', 'zainab', 'anita',
    'mrs', 'miss', 'kumari', 'begum', 'bibi', 'iqra', 'kinza'
  ];

  @override
  void initState() {
    super.initState();
    _updateAvatarByGender(_selectedGender);
    loadExistingUserData();
  }

  void _predictGenderFromName(String name) {
    if (name.trim().isEmpty) return;

    final String cleanName = name.trim().toLowerCase();
    final List<String> nameParts = cleanName.split(RegExp(r'\s+'));

    bool isMaleDetected = nameParts.any((part) => _maleKeywords.contains(part));
    bool isFemaleDetected = nameParts.any((part) => _femaleKeywords.contains(part));

    if (isMaleDetected && !isFemaleDetected) {
      _setGender('male');
    } else if (isFemaleDetected && !isMaleDetected) {
      _setGender('female');
    }
  }

  void _setGender(String gender) {
    setState(() {
      _selectedGender = gender;
      _updateAvatarByGender(gender);
    });
  }

  void _updateAvatarByGender(String gender) {
    if (gender == 'male') {
      _currentAvatarUrl = _maleAvatar;
    } else if (gender == 'female') {
      _currentAvatarUrl = _femaleAvatar;
    } else {
      _currentAvatarUrl = _defaultAvatar;
    }
  }

  Future<void> loadExistingUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection("users").doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          nameController.text = data["name"] ?? "";
          bioController.text = data["bio"] ?? "";
          locationController.text = data["location"] ?? "";
          expertAtController.text = data["expertAt"] ?? data["Expert at"] ?? "";
          aboutMeController.text = data["aboutMe"] ?? data["About Me"] ?? "";

          if (data["gender"] != null && data["gender"].toString().isNotEmpty) {
            _selectedGender = data["gender"];
            _updateAvatarByGender(_selectedGender);
          } else if (nameController.text.isNotEmpty) {
            _predictGenderFromName(nameController.text);
          }
        }
      } catch (e) {
        debugPrint("Error loading user data: $e");
      }
    }
    if (mounted) {
      setState(() {
        isExistingDataLoading = false;
      });
    }
  }

  Future<void> saveProfile() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your name"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      User? user = _auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No user is logged in"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await _firestore.collection("users").doc(user.uid).set({
        "name": nameController.text.trim(),
        "bio": bioController.text.trim(),
        "location": locationController.text.trim(),
        "expertAt": expertAtController.text.trim(),
        "Expert at": expertAtController.text.trim(),
        "aboutMe": aboutMeController.text.trim(),
        "About Me": aboutMeController.text.trim(),
        "gender": _selectedGender,
        "photoUrl": _currentAvatarUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile Saved Successfully"),
          backgroundColor: Color(0xff6A1B9A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SkillsTeachScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    locationController.dispose();
    expertAtController.dispose();
    aboutMeController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xff6A1B9A), size: 20),
      filled: true,
      fillColor: const Color(0xFFF9F8FD),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xff6A1B9A), width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff6A1B9A);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Back',
        ),
        title: const Text(
          "Complete Profile",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: isExistingDataLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Tell us a bit about yourself to personalize your profile",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Avatar with updated withValues() opacity
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Container(
                      key: ValueKey<String>(_currentAvatarUrl),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: primaryColor.withValues(alpha: 0.08),
                        backgroundImage: NetworkImage(_currentAvatarUrl),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Fields
              TextField(
                controller: nameController,
                decoration: _buildInputDecoration(
                  labelText: "Full Name",
                  icon: Icons.person_outline_rounded,
                ),
                onChanged: (value) => _predictGenderFromName(value),
              ),
              const SizedBox(height: 14),

              // Fixed Deprecated Dropdown Property (initialValue used)
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: _buildInputDecoration(
                  labelText: "Gender",
                  icon: Icons.wc_rounded,
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (value) {
                  if (value != null) _setGender(value);
                },
              ),
              const SizedBox(height: 14),

              TextField(
                controller: bioController,
                maxLines: 2,
                decoration: _buildInputDecoration(
                  labelText: "Bio",
                  hintText: "Short baseline bio...",
                  icon: Icons.edit_note_rounded,
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: locationController,
                decoration: _buildInputDecoration(
                  labelText: "Location",
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: expertAtController,
                decoration: _buildInputDecoration(
                  labelText: "Expert at",
                  icon: Icons.stars_outlined,
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: aboutMeController,
                maxLines: 3,
                decoration: _buildInputDecoration(
                  labelText: "About Me",
                  hintText: "Share more details about your journey...",
                  icon: Icons.info_outline_rounded,
                ),
              ),
              const SizedBox(height: 28),

              // Primary Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSaving ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 2,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                      : const Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}