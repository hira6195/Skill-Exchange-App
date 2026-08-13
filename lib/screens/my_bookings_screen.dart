import 'package:flutter/material.dart';
import 'package:skill_exchange/models/booking_model.dart';
import 'package:skill_exchange/services/booking_service.dart';

// Navigation screens
import 'calendar_schedule_screen.dart';
import 'join_meeting_screen.dart';
import 'learning_roadmap_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'completed':
      case 'confirmed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final BookingService bookingService = BookingService();

    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        title: const Text(
          'My Bookings & Schedule',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xff6A1B9A)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalendarScheduleScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingService.getUserBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff6A1B9A)),
            );
          }

          final bookings = snapshot.data ?? [];

          // 1. Empty State - اگر یوزر کی کوئی بکنگ فائر بیس میں نہ ہو
          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        size: 60,
                        color: Color(0xff6A1B9A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Booked Sessions Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Book a session with an expert from Search or AI Match to start your skill roadmap.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          // 2. Active Session Card Logic (حقیقی تازہ ترین بکنگ سے ڈیٹا فیچ کرنا)
          final latestBooking = bookings.first;
          final bool isCompleted = latestBooking.status.toLowerCase() == 'completed';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upcoming / Live Meeting Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted ? Colors.green.shade200 : Colors.deepPurple.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(latestBooking.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              latestBooking.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            "${latestBooking.sessionDate}, ${latestBooking.sessionTime}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff6A1B9A),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        latestBooking.skill,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Teacher: ${latestBooking.teacherName}",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JoinMeetingScreen(
                                booking: latestBooking,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          isCompleted ? Icons.workspace_premium : Icons.video_call,
                          color: Colors.white,
                        ),
                        label: Text(
                          isCompleted ? "View Progress & Meeting Room" : "Join Session Now",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff6A1B9A),
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dynamic Modules Roadmap according to Session Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Course Modules & Roadmap",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LearningRoadmapScreen(
                              skillName: latestBooking.skill,
                              subject: latestBooking.skill,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "View All",
                        style: TextStyle(color: Color(0xff6A1B9A)),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),

                // اگر سیشن ہو چکا ہے تو پہلا ماڈیول ان لاک، ورنہ لاک شو ہو گا
                _buildModuleTile(
                  week: "Week 1",
                  title: "${latestBooking.skill} Fundamentals",
                  subtitle: "Introduction & Core Concepts Setup",
                  isCompleted: isCompleted,
                  isCurrent: !isCompleted,
                ),
                _buildModuleTile(
                  week: "Week 2",
                  title: "Practical Projects & Hands-on",
                  subtitle: "Live Demonstration & Task Execution",
                  isCompleted: false,
                  isCurrent: false,
                ),
                _buildModuleTile(
                  week: "Week 3",
                  title: "Advanced Skill Assessment",
                  subtitle: "Final Feedback & Exchange Review",
                  isCompleted: false,
                  isCurrent: false,
                ),

                const SizedBox(height: 24),

                // All Real Bookings History
                const Text(
                  "All Bookings History",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    return _buildBookingCard(context, bookings[index]);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JoinMeetingScreen(booking: booking),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.teacherName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.status,
                      style: TextStyle(
                        color: _getStatusColor(booking.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                booking.skill,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(booking.sessionDate),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(booking.sessionTime),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleTile({
    required String week,
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isCurrent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? const Color(0xff6A1B9A) : Colors.grey.shade200,
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCompleted
                ? Colors.green.shade100
                : (isCurrent ? Colors.purple.shade100 : Colors.grey.shade100),
            child: Icon(
              isCompleted
                  ? Icons.check_circle
                  : (isCurrent ? Icons.play_circle_fill : Icons.lock_outline),
              color: isCompleted
                  ? Colors.green
                  : (isCurrent ? const Color(0xff6A1B9A) : Colors.grey),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$week: $title",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}