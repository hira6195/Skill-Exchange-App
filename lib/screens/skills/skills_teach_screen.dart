import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_exchange/screens/skills/skills_learn_screen.dart';

class SkillsTeachScreen extends StatefulWidget {
  const SkillsTeachScreen({super.key});

  @override
  State<SkillsTeachScreen> createState() => _SkillsTeachScreenState();
}

class _SkillsTeachScreenState extends State<SkillsTeachScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController customSkillController = TextEditingController();

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
                  // Restriction check: if already 1 skill selected
                  if (selectedSkills.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Free plan limit reached! Please buy Premium to teach multiple skills."),
                        backgroundColor: Colors.amber,
                      ),
                    );
                  } else {
                    bool alreadyExists = skills.any((skill) =>
                    skill['name'].toString().toLowerCase() == newSkillName.toLowerCase());

                    if (!alreadyExists) {
                      setState(() {
                        skills.add({
                          "name": newSkillName,
                          "icon": Icons.star,
                        });
                      });
                    }
                    setState(() {
                      selectedSkills = [newSkillName];
                    });
                  }
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

  Future<bool> saveTeachSkills() async {
    if (selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a skill to teach")),
      );
      return false;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user is logged in")),
        );
        return false;
      }
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(
        {
          "teachSkills": selectedSkills,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teaching Skills Saved Successfully")),
      );

      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return false;
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
    final filteredSkills = skills.where((skill) {
      final name = (skill['name'] as String).toLowerCase();
      return name.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Skills You Can Teach",
          style: TextStyle(
              color: Color(0xff5B3FD0),
              fontWeight: FontWeight.bold
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
                "Select 1 skill you can teach (Buy Premium for more)",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search Skills",
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
                    final String skillName = skill['name'] as String;
                    final IconData skillIcon = skill['icon'] as IconData;

                    bool isSelected = selectedSkills.contains(skillName);

                    return FilterChip(
                      avatar: Icon(
                          skillIcon,
                          size: 18,
                          color: isSelected ? Colors.white : Colors.black54
                      ),
                      label: Text(skillName),
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
                            // Replace existing selection (Max 1 allowed)
                            selectedSkills = [skillName];
                          } else {
                            selectedSkills.remove(skillName);
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
                  foregroundColor: const Color(0xff5B3FD0),
                  side: const BorderSide(
                    color: Color(0xff5B3FD0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  bool success = await saveTeachSkills();
                  if (success && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SkillsLearnScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff5B3FD0),
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