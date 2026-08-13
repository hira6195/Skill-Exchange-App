import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_exchange/screens/profile/edit_profile_screen.dart';
import '../dashboard/Home_Screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool loading = true;

  // Fallback Avatars URLs
  final String _maleAvatar = 'https://cdn-icons-png.flaticon.com/512/4140/4140048.png';
  final String _femaleAvatar = 'https://cdn-icons-png.flaticon.com/512/4140/4140047.png';
  final String _defaultAvatar = 'https://cdn-icons-png.flaticon.com/512/847/847969.png';

  // Dynamic Avatar Determination
  String getProfileImage() {
    if (userData == null) return _defaultAvatar;

    // Check for saved photoUrl or profileImage
    String? userImg = userData!["photoUrl"] ?? userData!["profileImage"];

    if (userImg != null && userImg.toString().trim().isNotEmpty) {
      return userImg;
    }

    // Fallback based on Gender attribute saved in Firestore
    String gender = (userData!["gender"] ?? "").toString().toLowerCase();
    if (gender == 'male') {
      return _maleAvatar;
    } else if (gender == 'female') {
      return _femaleAvatar;
    }

    return _defaultAvatar;
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    User? user = auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      return;
    }

    try {
      DocumentSnapshot snapshot =
      await firestore.collection("users").doc(user.uid).get();

      if (!mounted) return;

      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data() as Map<String, dynamic>;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      debugPrint("Profile Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xffF7F5FF),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xff6A1B9A),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF7F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((value) {
                fetchUserProfile();
              });
            },
            icon: const Text(
              "Edit Profile",
              style: TextStyle(
                color: Color(0xff6A1B9A),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            label: const Icon(
              Icons.edit,
              color: Color(0xff6A1B9A),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: userData == null
          ? const Center(
        child: Text(
          "No Profile Found",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            profileCard(),
            const SizedBox(height: 25),
            const Text(
              "About Me",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userData!["About Me"] ?? "No About Added",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                statCard("Projects", userData!["projects"] ?? 0),
                statCard("Teaching", userData!["teaching"] ?? 0),
                statCard("Reviews", userData!["reviews"] ?? 0),
              ],
            ),
            const SizedBox(height: 30),
            skillSection("Skills / Tech", userData!["teachSkills"]),
            const SizedBox(height: 25),
            skillSection("Skills / Learn", userData!["learnSkills"]),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6A1B9A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Continue to Skill Verification",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget profileCard() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.purple.shade50,
            backgroundImage: NetworkImage(getProfileImage()),
          ),
          const SizedBox(height: 12),
          Text(
            userData!["name"] ?? "User Name",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff6A1B9A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.work_outline,
                color: Color(0xff6A1B9A),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                userData!["Expert at"] ?? "Expertise Not Added",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.red.shade400,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                userData!["location"] ?? "No Location",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_ind_outlined,
                  color: Colors.blue.shade400,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    userData!["bio"] ?? "No Bio Added",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget statCard(String title, dynamic value) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: Color(0xff6A1B9A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget skillSection(String title, dynamic skills) {
    List skillList = skills is List ? skills : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        skillList.isEmpty
            ? Text(
          "No skills added yet",
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        )
            : Wrap(
          spacing: 10,
          runSpacing: 10,
          children: skillList.map<Widget>((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Text(
                skill.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}