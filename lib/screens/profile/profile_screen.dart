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

  final String _maleAvatar = 'https://cdn-icons-png.flaticon.com/512/4140/4140048.png';
  final String _femaleAvatar = 'https://cdn-icons-png.flaticon.com/512/4140/4140047.png';
  final String _defaultAvatar = 'https://cdn-icons-png.flaticon.com/512/847/847969.png';

  String _selectedGender = 'female';
  String _currentAvatarUrl = 'https://cdn-icons-png.flaticon.com/512/4140/4140047.png';

  final List<String> _maleKeywords = [
    'ali', 'khan', 'ahmed', 'ibrahim', 'muhammad', 'mohd', 'hassan', 'hussain',
    'umar', 'usman', 'hamza', 'bilal', 'mr', 'singh', 'kumar', 'raza', 'saad'
  ];

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
          expertAtController.text = data["Expert at"] ?? "";
          aboutMeController.text = data["About Me"] ?? "";

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
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user is logged in")),
        );
        return;
      }

      await _firestore.collection("users").doc(user.uid).set({
        "name": nameController.text.trim(),
        "bio": bioController.text.trim(),
        "location": locationController.text.trim(),
        "Expert at": expertAtController.text.trim(),
        "About Me": aboutMeController.text.trim(),
        "gender": _selectedGender,
        "photoUrl": _currentAvatarUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Saved Successfully")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SkillsTeachScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: const Text(
          "Complete Profile",
          style: TextStyle(
            color: Color(0xff6A1B9A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isExistingDataLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff6A1B9A)))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            const Text(
              "Let's know more about you",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),

            // Compact Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xff6A1B9A).withOpacity(0.1),
                  backgroundImage: NetworkImage(_currentAvatarUrl),
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xff6A1B9A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Full Name Input
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                prefixIcon: const Icon(Icons.person, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                _predictGenderFromName(value);
              },
            ),
            const SizedBox(height: 12),

            // Gender Selector Dropdown
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: "Gender",
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                prefixIcon: const Icon(Icons.wc, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _setGender(value);
                }
              },
            ),
            const SizedBox(height: 12),

            // Bio Field (Compact)
            TextField(
              controller: bioController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Bio",
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                prefixIcon: const Icon(Icons.edit, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: "Location",
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                prefixIcon: const Icon(Icons.location_on, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: expertAtController,
              decoration: InputDecoration(
                labelText: "Expert at",
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                prefixIcon: const Icon(Icons.star, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: aboutMeController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "About Me",
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                prefixIcon: const Icon(Icons.info, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await saveProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6A1B9A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}