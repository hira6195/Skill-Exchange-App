import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_exchange/screens/my_bookings_screen.dart';
import 'package:skill_exchange/services/booking_service.dart';
import 'package:skill_exchange/services/chat_service.dart';

class BookingScreen extends StatefulWidget {
  final String expertId;
  final String expertName;
  final String expertImage;
  final String skill;
  final double hourlyRate;

  const BookingScreen({
    super.key,
    required this.expertId,
    required this.expertName,
    required this.expertImage,
    required this.skill,
    this.hourlyRate = 0.0,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  final ChatService _chatService = ChatService();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTime;
  String _sessionType = 'Online';
  String _selectedDuration = '60 Minutes';
  int _totalSessions = 1;
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];

  final List<String> _durations = [
    '30 Minutes',
    '60 Minutes',
    '90 Minutes',
  ];

  final List<int> _sessionCounts = [1, 3, 5, 10];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleConfirmBooking() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a session date')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available time slot')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Total package amount passed; service divides it per session
    final double totalAmount = (widget.hourlyRate > 0 ? widget.hourlyRate : 0.0) * _totalSessions;

    final success = await _bookingService.createBooking(
      expertId: widget.expertId,
      expertName: widget.expertName.isNotEmpty ? widget.expertName : 'Matched Expert',
      skill: widget.skill.isNotEmpty ? widget.skill : 'Matched Skill',
      amount: totalAmount,
      date: _selectedDate,
      sessionTime: _selectedTime!,
      sessionType: _sessionType,
      duration: _selectedDuration,
      notes: _notesController.text.trim(),
      totalSessions: _totalSessions,
      sessionNumber: 1,
    );

    if (success && widget.expertId.isNotEmpty) {
      try {
        final chatId = await _chatService.createOrGetChat(widget.expertId);
        await _chatService.sendMessage(
          chatId,
          widget.expertId,
          "Hello! I've booked $_totalSessions session(s) (${_selectedDuration} ${_sessionType}) for ${widget.skill}. First session starts on ${DateFormat('dd MMMM yyyy').format(_selectedDate!)} at ${_selectedTime!}.",
        );
      } catch (e) {
        debugPrint("Chat auto-message error: $e");
      }
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('All $_totalSessions Session(s) Scheduled Successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyBookingsScreen(),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm booking. A selected date/slot might already be booked.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Book Session Series',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExpertCard(),
            const SizedBox(height: 24),
            const Text(
              'Select Number of Sessions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _sessionCounts.map((count) {
                final isSelected = _totalSessions == count;
                return ChoiceChip(
                  label: Text('$count ${count == 1 ? "Session" : "Sessions"}'),
                  selected: isSelected,
                  selectedColor: Colors.deepPurple,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _totalSessions = count;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'First Session Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Choose Start Date'
                          : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 15,
                        color: _selectedDate == null ? Colors.grey.shade500 : Colors.black87,
                        fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.calendar_month_rounded, color: Colors.deepPurple),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Time Slots',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((slot) {
                final isSelected = _selectedTime == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  selectedColor: Colors.deepPurple,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedTime = selected ? slot : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'Online',
                        label: Text('Online'),
                        icon: Icon(Icons.videocam_outlined),
                      ),
                      ButtonSegment<String>(
                        value: 'Physical',
                        label: Text('Physical'),
                        icon: Icon(Icons.person_outline),
                      ),
                    ],
                    selected: {_sessionType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _sessionType = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white,
                      selectedBackgroundColor: Colors.deepPurple.shade50,
                      selectedForegroundColor: Colors.deepPurple,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Duration Per Session',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDuration,
                  isExpanded: true,
                  items: _durations.map((duration) {
                    return DropdownMenuItem(
                      value: duration,
                      child: Text(duration),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDuration = value;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Notes / Learning Goals (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your goals for this session series...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleConfirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : Text(
                  'Confirm Booking ($_totalSessions ${_totalSessions == 1 ? "Session" : "Sessions"})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepPurple.shade100,
            backgroundImage: widget.expertImage.isNotEmpty ? NetworkImage(widget.expertImage) : null,
            child: widget.expertImage.isEmpty
                ? Text(
              widget.expertName.isNotEmpty ? widget.expertName[0].toUpperCase() : 'E',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.expertName.isNotEmpty ? widget.expertName : 'Expert Name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Skill: ${widget.skill.isNotEmpty ? widget.skill : "Skill Swap"}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
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