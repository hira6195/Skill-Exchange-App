import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skill_exchange/models/booking_model.dart';
import 'package:skill_exchange/services/booking_service.dart';
import 'package:skill_exchange/services/progress_service.dart';
import 'package:skill_exchange/screens/learning_progress_screen.dart';

class JoinMeetingScreen extends StatefulWidget {
  final BookingModel booking;

  const JoinMeetingScreen({
    super.key,
    required this.booking,
  });

  @override
  State<JoinMeetingScreen> createState() => _JoinMeetingScreenState();
}

class _JoinMeetingScreenState extends State<JoinMeetingScreen> {
  Timer? _timer;
  Duration _timeLeft = const Duration(minutes: 15, seconds: 0);
  bool _isEndingSession = false;
  bool _isRecording = false;

  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = Duration(seconds: _timeLeft.inSeconds - 1);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // Live Jitsi Meeting Room Handler
  Future<void> _handleJoinMeeting() async {
    final String roomName = widget.booking.bookingId.isNotEmpty
        ? widget.booking.bookingId
        : 'Session_${widget.booking.teacherId}';

    final Uri meetingUri = Uri.parse('https://meet.jit.si/SkillExchange_$roomName');

    try {
      final bool launched = await launchUrl(
        meetingUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch meeting room.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Toggle Recording Status
  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isRecording ? 'Session Recording Started' : 'Session Recording Stopped',
        ),
        backgroundColor: _isRecording ? Colors.red : Colors.orange,
      ),
    );
  }

  // End Session, Save Recording URL, and Unlock Progress
  Future<void> _handleEndSession() async {
    setState(() => _isEndingSession = true);
    try {
      // 1. فرضی ویڈیو سورس فائر بیس میں سیو کریں (اگر ریکارڈنگ کی گئی ہو)
      if (_isRecording) {
        String dummyRecordingUrl =
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

        await _bookingService.saveSessionRecording(
          bookingId: widget.booking.bookingId,
          recordingUrl: dummyRecordingUrl,
        );
      }

      // 2. سیشن ختم کریں اور Progress ان لاک کریں
      await ProgressService().endSessionAndInitializeProgress(
        bookingId: widget.booking.bookingId,
        studentId: widget.booking.studentId,
        teacherId: widget.booking.teacherId,
        skill: widget.booking.skill,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session completed & Recording Saved! Progress initialized.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to LearningProgressScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LearningProgressScreen(
            bookingId: widget.booking.bookingId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isEndingSession = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Join Session',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              Icons.fiber_manual_record,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
            onPressed: _toggleRecording,
            tooltip: _isRecording ? 'Recording On' : 'Start Recording',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Expert Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(
                      widget.booking.teacherName.isNotEmpty
                          ? widget.booking.teacherName[0].toUpperCase()
                          : 'E',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.booking.teacherName.isNotEmpty
                        ? widget.booking.teacherName
                        : 'Teacher',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.booking.skill,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              color: Colors.deepPurple.shade400, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            widget.booking.sessionDate,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.access_time_filled_rounded,
                              color: Colors.deepPurple.shade400, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            widget.booking.sessionTime,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.timer_rounded,
                              color: Colors.deepPurple.shade400, size: 20),
                          const SizedBox(height: 4),
                          const Text(
                            '60 Mins',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Countdown Timer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: Column(
                children: [
                  Text(
                    'Session Starts In',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_timeLeft),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Join Meeting Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _handleJoinMeeting,
                icon: const Icon(Icons.video_call_rounded, size: 24),
                label: const Text(
                  'Join Meeting Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Record Session Switch Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _toggleRecording,
                icon: Icon(
                  Icons.circle,
                  color: _isRecording ? Colors.red : Colors.grey,
                  size: 16,
                ),
                label: Text(
                  _isRecording ? 'Recording Active (Click to Stop)' : 'Record Meeting Session',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isRecording ? Colors.red : Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isRecording ? Colors.red : Colors.grey.shade400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Teacher End Session Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isEndingSession ? null : _handleEndSession,
                icon: _isEndingSession
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  _isEndingSession ? 'Ending Session...' : 'End Session & Unlock Progress',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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