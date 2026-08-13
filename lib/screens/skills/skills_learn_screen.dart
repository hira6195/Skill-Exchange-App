import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_exchange/screens/profile/user_profile_screen.dart';

class SkillsLearnScreen extends StatefulWidget {
  const SkillsLearnScreen({super.key});

  @override
  State<SkillsLearnScreen> createState() => _SkillsLearnScreenState();
}

class _SkillsLearnScreenState extends State<SkillsLearnScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController customSkillController = TextEditingController();
  bool isLoading = false;

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
          // Agar database me multiple existing skills milein to free tier ke mutabiq standard limit 1 rakhein
          if (selectedSkills.length > 1) {
            selectedSkills = [selectedSkills.first];
          }
        }
        if (mounted) {
          setState(() {});
        }
      }
    } catch (_) {}
  }

  void filterSkills(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        filteredSkills = List.from(allSkills);
      } else {
        filteredSkills = allSkills
            .where((skill) => skill.toLowerCase().contains(value.toLowerCase()))
            .toList();
      }
    });
  }

  void _showAddSkillDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Custom Skill"),
          content: TextField(
            controller: customSkillController,
            decoration: const InputDecoration(
              hintText: "Enter skill name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                customSkillController.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String newSkillName = customSkillController.text.trim();
                if (newSkillName.isNotEmpty) {
                  if (selectedSkills.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Free plan limit reached! Please buy Premium to select multiple skills."),
                        backgroundColor: Colors.amber,
                      ),
                    );
                  }

                  if (!allSkills.any((s) => s.toLowerCase() == newSkillName.toLowerCase())) {
                    setState(() {
                      allSkills.add(newSkillName);
                      filteredSkills.add(newSkillName);
                    });
                  }

                  setState(() {
                    selectedSkills = [newSkillName];
                  });

                  customSkillController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveSkills() async {
    if (selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a skill to learn")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(
        {
          "learnSkills": selectedSkills,
          "isProfileCompleted": true,
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Learning Skills Saved Successfully")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const UserProfileScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
    searchController.dispose();
    customSkillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Skills You Want To Learn",
          style: TextStyle(
            color: Color(0xff6A1B9A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Select 1 skill to learn (Buy Premium for more)",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: searchController,
              onChanged: filterSkills,
              decoration: InputDecoration(
                hintText: "Search Skill",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: filteredSkills.map((skill) {
                    bool isSelected = selectedSkills.contains(skill);

                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      selectedColor: const Color(0xff6A1B9A),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            if (selectedSkills.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Free plan limit reached! Please buy Premium to select multiple skills."),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                            // Only allow single selection
                            selectedSkills = [skill];
                          } else {
                            selectedSkills.remove(skill);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 150,
              child: ElevatedButton.icon(
                onPressed: _showAddSkillDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add More"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xff6A1B9A),
                  side: const BorderSide(
                    color: Color(0xff6A1B9A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                  await saveSkills();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6A1B9A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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