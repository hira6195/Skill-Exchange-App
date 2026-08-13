import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expert_model.dart';
import '../services/booking_service.dart';
import 'expert_profile_screen.dart';
import 'chat_screen.dart';

class ExpertBookingScreen extends StatefulWidget {
  const ExpertBookingScreen({super.key});

  @override
  State<ExpertBookingScreen> createState() => _ExpertBookingScreenState();
}

class _ExpertBookingScreenState extends State<ExpertBookingScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book an Expert Session'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search expert by name or skill...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
            ),
          ),

          // 2. Category Chips Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ['All', 'Developers', 'Design', 'Marketing'].map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    selectedColor: Colors.purple,
                    labelStyle: TextStyle(
                      color: selectedCategory == cat ? Colors.white : Colors.black,
                    ),
                    onSelected: (bool selected) {
                      setState(() => selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Expert List View
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('experts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No experts available.'));
                }

                final experts = snapshot.data!.docs
                    .map((doc) => ExpertModel.fromFirestore(doc))
                    .where((exp) {
                  bool matchesCat = selectedCategory == 'All' || exp.category == selectedCategory;
                  bool matchesSearch = exp.name.toLowerCase().contains(searchQuery) ||
                      exp.skill.toLowerCase().contains(searchQuery);
                  return matchesCat && matchesSearch;
                }).toList();

                return ListView.builder(
                  itemCount: experts.length,
                  itemBuilder: (context, index) {
                    final expert = experts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            expert.profileImage.isNotEmpty
                                ? expert.profileImage
                                : 'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Text(expert.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(expert.skill),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                Text(' ${expert.rating}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Profile View Icon Button
                            IconButton(
                              icon: const Icon(Icons.person, color: Colors.purple),
                              tooltip: 'View Profile',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExpertProfileScreen(expert: expert),
                                  ),
                                );
                              },
                            ),

                            // Book Session Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);

                                // سیشن بک کریں
                                bool success = await _bookingService.createBooking(
                                  expertId: expert.uid,
                                  expertName: expert.name,
                                  skill: expert.skill,
                                  amount: expert.hourlyRate,
                                  date: DateTime.now(),
                                );

                                if (!mounted) return;

                                if (success) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Session booked with ${expert.name}! Opening Chat...')),
                                  );

                                  // ChatScreen پر درست параметры کے ساتھ منتقل کریں
                                  navigator.push(
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        chatId: expert.uid,
                                        receiverId: expert.uid,
                                        userName: expert.name,
                                      ),
                                    ),
                                  );
                                } else {
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Failed to book session.')),
                                  );
                                }
                              },
                              child: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}