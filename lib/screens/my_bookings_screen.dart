import 'package:flutter/material.dart';
import 'package:skill_exchange/models/booking_model.dart';
import 'package:skill_exchange/services/booking_service.dart';

import 'calendar_schedule_screen.dart';
import 'join_meeting_screen.dart';
import 'learning_roadmap_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  static const Color primaryColor = Color(0xff6A1B9A);

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
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: primaryColor,
            ),
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
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          // Sort sessions by session number.
          final sortedBookings = [...bookings];

          sortedBookings.sort(
                (a, b) {
              if (a.seriesId == b.seriesId) {
                return a.sessionNumber.compareTo(b.sessionNumber);
              }

              return b.bookingDate.compareTo(a.bookingDate);
            },
          );

          final latestBooking = sortedBookings.first;

          // Find the course/session series with most sessions.
          final String activeSeriesId = latestBooking.seriesId;

          final seriesBookings = sortedBookings
              .where(
                (booking) => booking.seriesId == activeSeriesId,
          )
              .toList();

          seriesBookings.sort(
                (a, b) => a.sessionNumber.compareTo(b.sessionNumber),
          );

          final int totalSessions =
          seriesBookings.isNotEmpty
              ? seriesBookings.first.totalSessions
              : latestBooking.totalSessions;

          final int completedSessions = seriesBookings
              .where(
                (booking) =>
            booking.sessionCompleted ||
                booking.status.toLowerCase() == 'completed',
          )
              .length;

          final int remainingSessions =
              totalSessions - completedSessions;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ==================================================
                // COURSE PROGRESS
                // ==================================================

                _buildCourseProgressCard(
                  skill: latestBooking.skill,
                  completedSessions: completedSessions,
                  totalSessions: totalSessions,
                  remainingSessions: remainingSessions,
                ),

                const SizedBox(height: 20),

                // ==================================================
                // ALL SESSIONS
                // ==================================================

                const Text(
                  'Course Sessions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ...seriesBookings.map(
                      (booking) => _buildSessionCard(
                    context,
                    booking,
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // ROADMAP
                // ==================================================

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Course Modules & Roadmap',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LearningRoadmapScreen(
                                  skillName: latestBooking.skill,
                                  subject: latestBooking.skill,
                                ),
                          ),
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                _buildModuleTile(
                  week: 'Week 1',
                  title:
                  '${latestBooking.skill} Fundamentals',
                  subtitle:
                  'Introduction & Core Concepts Setup',
                  isCompleted: completedSessions >= 1,
                  isCurrent:
                  completedSessions == 0,
                ),

                _buildModuleTile(
                  week: 'Week 2',
                  title:
                  'Practical Projects & Hands-on',
                  subtitle:
                  'Live Demonstration & Task Execution',
                  isCompleted: completedSessions >= 2,
                  isCurrent:
                  completedSessions == 1,
                ),

                _buildModuleTile(
                  week: 'Week 3',
                  title:
                  'Advanced Skill Assessment',
                  subtitle:
                  'Final Feedback & Exchange Review',
                  isCompleted: completedSessions >= 3,
                  isCurrent:
                  completedSessions == 2,
                ),

                const SizedBox(height: 24),

                // ==================================================
                // ALL BOOKINGS
                // ==================================================

                const Text(
                  'All Bookings History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ...sortedBookings.map(
                      (booking) => _buildBookingHistoryCard(
                    context,
                    booking,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
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
                color: primaryColor,
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
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COURSE PROGRESS CARD
  // ============================================================

  Widget _buildCourseProgressCard({
    required String skill,
    required int completedSessions,
    required int totalSessions,
    required int remainingSessions,
  }) {
    final double progress =
    totalSessions > 0
        ? completedSessions / totalSessions
        : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff6A1B9A),
            Color(0xff8E24AA),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Progress',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            skill.isNotEmpty
                ? skill
                : 'Skill Learning Course',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedSessions / $totalSessions Sessions Completed',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              Text(
                '$remainingSessions Remaining',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
              Colors.white24,
              valueColor:
              const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SESSION CARD
  // ============================================================

  Widget _buildSessionCard(
      BuildContext context,
      BookingModel booking,
      ) {
    final bool completed =
        booking.sessionCompleted ||
            booking.status.toLowerCase() ==
                'completed';

    final bool isNextSession =
        !completed &&
            booking.status.toLowerCase() ==
                'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color: completed
              ? Colors.green.shade200
              : primaryColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [

          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                completed
                    ? Colors.green.shade100
                    : Colors.deepPurple.shade50,
                child: Icon(
                  completed
                      ? Icons.check_circle
                      : Icons.video_call,
                  color: completed
                      ? Colors.green
                      : primaryColor,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session ${booking.sessionNumber}/${booking.totalSessions}',
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      booking.skill,
                      style: TextStyle(
                        color:
                        Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.shade50
                      : Colors.deepPurple.shade50,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Text(
                  completed
                      ? 'Completed'
                      : 'Upcoming',
                  style: TextStyle(
                    color: completed
                        ? Colors.green
                        : primaryColor,
                    fontSize: 11,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  booking.sessionDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ),

              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 7),

              Text(
                booking.sessionTime,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (isNextSession)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          JoinMeetingScreen(
                            booking: booking,
                          ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.video_call,
                  color: Colors.white,
                ),
                label: const Text(
                  'Join Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  minimumSize:
                  const Size(
                    double.infinity,
                    44,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(11),
                  ),
                ),
              ),
            ),

          if (completed)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          JoinMeetingScreen(
                            booking: booking,
                          ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.history,
                  color: primaryColor,
                ),
                label: const Text(
                  'View Session',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING HISTORY CARD
  // ============================================================

  Widget _buildBookingHistoryCard(
      BuildContext context,
      BookingModel booking,
      ) {
    return Card(
      margin:
      const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(15),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor:
              Color(0xffF1E6F7),
              child: Icon(
                Icons.school,
                color: primaryColor,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    '${booking.skill} • Session ${booking.sessionNumber}/${booking.totalSessions}',
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    booking.teacherName,
                    style: TextStyle(
                      color:
                      Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${booking.sessionDate} • ${booking.sessionTime}',
                    style: TextStyle(
                      color:
                      Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(
                  booking.status,
                ).withValues(alpha: 0.12),
                borderRadius:
                BorderRadius.circular(9),
              ),
              child: Text(
                booking.status,
                style: TextStyle(
                  color: _getStatusColor(
                    booking.status,
                  ),
                  fontSize: 10,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ROADMAP MODULE
  // ============================================================

  Widget _buildModuleTile({
    required String week,
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isCurrent = false,
  }) {
    return Container(
      margin:
      const EdgeInsets.only(bottom: 12),
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? primaryColor
              : Colors.grey.shade200,
          width: isCurrent
              ? 1.5
              : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
            isCompleted
                ? Colors.green.shade100
                : isCurrent
                ? Colors.purple.shade100
                : Colors.grey.shade100,
            child: Icon(
              isCompleted
                  ? Icons.check_circle
                  : isCurrent
                  ? Icons.play_circle_fill
                  : Icons.lock_outline,
              color: isCompleted
                  ? Colors.green
                  : isCurrent
                  ? primaryColor
                  : Colors.grey,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  '$week: $title',
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}