import 'package:flutter/material.dart';
import 'package:skill_exchange/screens/skill_detail_screen.dart';

class CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6C5CE7) : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: isSelected ? Colors.white : color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class SearchSkillsScreen extends StatefulWidget {
  const SearchSkillsScreen({super.key});

  @override
  State<SearchSkillsScreen> createState() => _SearchSkillsScreenState();
}

class _SearchSkillsScreenState extends State<SearchSkillsScreen> {
  final List<Map<String, dynamic>> _allSkills = [
    {"name": "Flutter Development", "category": "Development", "students": "24,532 students", "icon": Icons.code},
    {"name": "UI/UX Design", "category": "Design", "students": "18,921 students", "icon": Icons.palette},
    {"name": "Python Machine Learning", "category": "Development", "students": "16,231 students", "icon": Icons.terminal},
    {"name": "Fullstack Web Dev", "category": "Development", "students": "14,543 students", "icon": Icons.web},
    {"name": "Digital Marketing", "category": "Marketing", "students": "11,200 students", "icon": Icons.trending_up},
    {"name": "Business Strategy", "category": "Business", "students": "9,800 students", "icon": Icons.business},
  ];

  List<Map<String, dynamic>> _filteredSkills = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "";

  @override
  void initState() {
    super.initState();
    _filteredSkills = _allSkills;
  }

  void _runFilter() {
    final String keyword = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredSkills = _allSkills.where((s) {
        final matchSearch = s["name"].toString().toLowerCase().contains(keyword);
        final matchCategory = _selectedCategory.isEmpty || s["category"].toString().toLowerCase() == _selectedCategory.toLowerCase();
        return matchSearch && matchCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text("Explore Skills", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => _runFilter(),
              decoration: InputDecoration(
                hintText: "Search skills, technologies...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CategoryCard(label: "Design", icon: Icons.palette, color: Colors.pinkAccent, isSelected: _selectedCategory == "Design", onTap: () { setState(() => _selectedCategory = _selectedCategory == "Design" ? "" : "Design"); _runFilter(); }),
                CategoryCard(label: "Development", icon: Icons.code, color: Colors.purple, isSelected: _selectedCategory == "Development", onTap: () { setState(() => _selectedCategory = _selectedCategory == "Development" ? "" : "Development"); _runFilter(); }),
                CategoryCard(label: "Marketing", icon: Icons.trending_up, color: Colors.blue, isSelected: _selectedCategory == "Marketing", onTap: () { setState(() => _selectedCategory = _selectedCategory == "Marketing" ? "" : "Marketing"); _runFilter(); }),
                CategoryCard(label: "Business", icon: Icons.business, color: Colors.amber.shade700, isSelected: _selectedCategory == "Business", onTap: () { setState(() => _selectedCategory = _selectedCategory == "Business" ? "" : "Business"); _runFilter(); }),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSkills.length,
                itemBuilder: (context, index) {
                  final item = _filteredSkills[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(item["icon"], color: const Color(0xFF6C5CE7)),
                      title: Text(item["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item["students"]),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SkillDetailScreen(skillName: item["name"], category: item["category"]))),
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