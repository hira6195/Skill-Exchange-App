import 'package:flutter/material.dart';
import 'package:skill_exchange/models/expert_model.dart';
import 'package:skill_exchange/screens/expert_profile_screen.dart';

class ExpertCard extends StatelessWidget {
  final ExpertModel expert;
  final VoidCallback? onChatPressed;
  final VoidCallback? onViewProfile;

  const ExpertCard({
    super.key,
    required this.expert,
    this.onChatPressed,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic Match Badge Colors
    final bool isHighMatch = expert.matchPercentage > 50;
    final Color badgeBgColor = isHighMatch
        ? const Color(0xFFF0E6FF)
        : const Color(0xFFF5F5F5);
    final Color badgeTextColor = isHighMatch
        ? const Color(0xFF7C3AED)
        : Colors.grey.shade700;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // Deprecation Fix: withOpacity -> withValues
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Image with Avatar Fallback
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.purple.shade50,
                    backgroundImage: expert.profileImage.isNotEmpty
                        ? NetworkImage(expert.profileImage)
                        : null,
                    child: expert.profileImage.isEmpty
                        ? Text(
                      expert.name.isNotEmpty
                          ? expert.name[0].toUpperCase()
                          : 'E',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    )
                        : null,
                  ),
                  // Verified Badge
                  if (expert.verified)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // 2. Name, Skills, & Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expert.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (expert.premium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Teaches: ${expert.skill}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Category: ${expert.category}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expert.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Dynamic AI Match Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHighMatch
                        ? Colors.deepPurple.shade100
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: badgeTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${expert.matchPercentage}% Match',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // 4. Action Buttons (Chat & View Profile)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChatPressed ?? () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 15),
                  label: const Text(
                    "Chat",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: Colors.deepPurple.shade300),
                    foregroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onViewProfile ??
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExpertProfileScreen(
                              expert: expert,
                              skill: null,
                              expertImage: null,
                              expertName: null,
                              expertId: null,
                            ),
                          ),
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}