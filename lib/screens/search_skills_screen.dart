import 'package:flutter/material.dart';
import 'package:skill_exchange/screens/skill_detail_screen.dart'; // Skill Detail Screen کا پاتھ

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
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xff6A1B9A) : color.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? Border.all(color: const Color(0xff6A1B9A), width: 2) : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xff6A1B9A) : Colors.black87,
            ),
          ),
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
  // Backend / Master Data
  final List<Map<String, dynamic>> _allSkills = [
    {
      "name": "Flutter Development",
      "category": "Development",
      "students": "24,532 students",
      "icon": Icons.code,
    },
    {
      "name": "UI/UX Design",
      "category": "Design",
      "students": "18,921 students",
      "icon": Icons.palette,
    },
    {
      "name": "Python Programming",
      "category": "Development",
      "students": "16,231 students",
      "icon": Icons.terminal,
    },
    {
      "name": "Web Development",
      "category": "Development",
      "students": "14,543 students",
      "icon": Icons.web,
    },
    {
      "name": "Digital Marketing",
      "category": "Marketing",
      "students": "11,200 students",
      "icon": Icons.trending_up,
    },
    {
      "name": "Business Strategy",
      "category": "Business",
      "students": "9,800 students",
      "icon": Icons.business,
    },
  ];

  List<Map<String, dynamic>> _filteredSkills = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "";

  @override
  void initState() {
    super.initState();
    _filteredSkills = _allSkills;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Backend Search & Category Filter Combined Logic
  void _runFilter() {
    final String keyword = _searchController.text.trim().toLowerCase();

    List<Map<String, dynamic>> results = _allSkills.where((skill) {
      final matchesSearch = skill["name"].toString().toLowerCase().contains(keyword);
      final matchesCategory = _selectedCategory.isEmpty ||
          skill["category"].toString().toLowerCase() == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();

    setState(() {
      _filteredSkills = results;
    });
  }

  void _selectCategory(String categoryLabel) {
    setState(() {
      if (_selectedCategory == categoryLabel) {
        _selectedCategory = ""; // Toggle unselect
      } else {
        _selectedCategory = categoryLabel;
      }
    });
    _runFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Search Skills",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Input Field with Filter & Clear functionality
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _runFilter(),
                    decoration: InputDecoration(
                      hintText: "Search skills...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter();
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Popular Categories with Selection logic
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Popular Categories",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = "";
                      _searchController.clear();
                    });
                    _runFilter();
                  },
                  child: Text(
                    _selectedCategory.isEmpty ? "View all" : "Clear Filter",
                    style: const TextStyle(color: Color(0xff6A1B9A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CategoryCard(
                  label: "Design",
                  icon: Icons.design_services,
                  color: Colors.pinkAccent,
                  isSelected: _selectedCategory == "Design",
                  onTap: () => _selectCategory("Design"),
                ),
                CategoryCard(
                  label: "Development",
                  icon: Icons.code,
                  color: Colors.purple,
                  isSelected: _selectedCategory == "Development",
                  onTap: () => _selectCategory("Development"),
                ),
                CategoryCard(
                  label: "Marketing",
                  icon: Icons.trending_up,
                  color: Colors.blue,
                  isSelected: _selectedCategory == "Marketing",
                  onTap: () => _selectCategory("Marketing"),
                ),
                CategoryCard(
                  label: "Business",
                  icon: Icons.business,
                  color: Colors.amber.shade700,
                  isSelected: _selectedCategory == "Business",
                  onTap: () => _selectCategory("Business"),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Dynamic Trending Skills / Search Results
            Text(
              _searchController.text.isNotEmpty
                  ? "Search Results (${_filteredSkills.length})"
                  : (_selectedCategory.isNotEmpty
                  ? "$_selectedCategory Skills"
                  : "Trending Skills"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _filteredSkills.isNotEmpty
                  ? ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredSkills.length,
                itemBuilder: (context, index) {
                  final item = _filteredSkills[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xff6A1B9A).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item["icon"],
                          color: const Color(0xff6A1B9A),
                        ),
                      ),
                      title: Text(
                        item["name"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item["students"]),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // AI ڈائنامک روڈ میپ اور ماڈیولز دیکھنے کے لیے نیویگیٹ کریں
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SkillDetailScreen(
                              skillName: item["name"],
                              category: item["category"],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      "No skills found for '${_searchController.text}'",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}