import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expert_model.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
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
  final ChatService _chatService = ChatService();

  void _navigateToProfile(ExpertModel expert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpertProfileScreen(
          expert: expert,
          expertId: expert.uid,
          expertName: expert.name,
          expertImage: expert.profileImage,
          skill: expert.skill,
        ),
      ),
    );
  }

  void _bookSession(ExpertModel expert) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Book Session with ${expert.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skill: ${expert.skill}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Do you want to book a 1-on-1 session with this expert?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

              if (userId.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login to book a session')),
                );
                return;
              }

              try {
                await _bookingService.createBooking(
                  expertId: expert.id,
                  expertName: expert.name,
                  skill: expert.skill,
                  amount: 0.0,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Session booked successfully with ${expert.name}!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking failed: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm Booking', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startChat(ExpertModel expert) async {
    try {
      final String chatId = await _chatService.createOrGetChat(expert.uid);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            receiverId: expert.uid,
            userName: expert.name,
            userAvatar: expert.profileImage,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat Connection Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Elite Expert Session'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search expert by name, skill, or university...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
            ),
          ),
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
                    selectedColor: Colors.deepPurple,
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
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('experts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No experts available right now.'));
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _navigateToProfile(expert),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(
                                  expert.profileImage.isNotEmpty
                                      ? expert.profileImage
                                      : 'https://via.placeholder.com/150',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            expert.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, color: Colors.blue, size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      expert.skill,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        Text(
                                          ' ${expert.rating} (Top 1% Mentor)',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.deepPurple),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      minimumSize: const Size(60, 26),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () => _startChat(expert),
                                    child: const Text('Chat', style: TextStyle(color: Colors.deepPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 4),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      minimumSize: const Size(60, 26),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () => _bookSession(expert),
                                    child: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
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