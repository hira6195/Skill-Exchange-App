import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/expert_model.dart';
import 'booking_screen.dart';
import 'chat_screen.dart';
import '../services/chat_service.dart';

class ExpertProfileScreen extends StatefulWidget {
  final String? userId;
  final ExpertModel? expert;
  final String? expertId;
  final String? expertName;
  final String? expertImage;
  final String? skill;

  const ExpertProfileScreen({
    super.key,
    this.userId,
    this.expert,
    this.expertId,
    this.expertName,
    this.expertImage,
    this.skill,
  });

  @override
  State<ExpertProfileScreen> createState() => _ExpertProfileScreenState();
}

class _ExpertProfileScreenState extends State<ExpertProfileScreen> {
  ExpertModel? _expertData;
  bool _isLoading = true;
  String? _errorMessage = '';

  // Reviews state variables
  double _calculatedRating = 0.0;
  int _totalReviewsCount = 0;
  bool _isReviewsLoading = true;

  // Certificates state variables
  List<Map<String, dynamic>> _certificates = [];
  bool _isCertificatesLoading = true;

  // Chat Navigation State
  final ChatService _chatService = ChatService();
  bool _isNavigatingToChat = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Priority 1: Direct ExpertModel provided
    if (widget.expert != null) {
      _expertData = widget.expert;
      _calculatedRating = widget.expert!.rating;
      _isLoading = false;
      await Future.wait([
        _fetchReviewsFromFirestore(widget.expert!.uid),
        _fetchCertificatesFromFirestore(widget.expert!.uid),
      ]);
    }
    // Priority 2: Direct Parameters passed from previous screen
    else if (widget.expertId != null && widget.expertId!.isNotEmpty) {
      _expertData = ExpertModel(
        uid: widget.expertId!,
        name: widget.expertName ?? 'Expert Teacher',
        profileImage: widget.expertImage ?? '',
        skill: widget.skill ?? 'Development',
        rating: 4.8,
        matchPercentage: 95,
        category: 'Development',
        level: 'Expert',
        verified: true,
        premium: true,
        about:
        'Verified Expert level mentor in ${widget.skill ?? "Development"}. Dedicated to helping students learn effectively through interactive sessions.',
      );

      _calculatedRating = 4.8;
      _isLoading = false;

      await Future.wait([
        _fetchUserDataFromFirestoreById(widget.expertId!),
        _fetchReviewsFromFirestore(widget.expertId!),
        _fetchCertificatesFromFirestore(widget.expertId!),
      ]);
    }
    // Priority 3: Fallback userId passed
    else if (widget.userId != null) {
      await _fetchUserDataFromFirestoreById(widget.userId!);
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'Teacher profile details missing.';
          _isLoading = false;
        });
      }
    }
  }

  // Fetch User Profile by ID
  Future<void> _fetchUserDataFromFirestoreById(String id) async {
    try {
      final docSnap =
      await FirebaseFirestore.instance.collection('users').doc(id).get();

      if (!mounted) return;

      if (docSnap.exists && docSnap.data() != null) {
        final expert = ExpertModel.fromMap(docSnap.data()!, docSnap.id);
        setState(() {
          _expertData = expert;
          _calculatedRating = expert.rating;
          _isLoading = false;
        });
      } else if (_expertData == null) {
        setState(() {
          _errorMessage = 'Teacher profile could not be found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (_expertData == null) {
        setState(() {
          _errorMessage = 'Failed to load profile. Please check connection.';
          _isLoading = false;
        });
      }
    }
  }

  // Fetch Reviews
  Future<void> _fetchReviewsFromFirestore(String expertId) async {
    try {
      if (mounted) setState(() => _isReviewsLoading = true);

      final reviewsQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('expertId', isEqualTo: expertId)
          .get();

      if (!mounted) return;

      if (reviewsQuery.docs.isNotEmpty) {
        int totalCount = reviewsQuery.docs.length;
        double sumRating = reviewsQuery.docs.fold(
          0.0,
              (sum, doc) => sum + ((doc.data()['rating'] ?? 0.0) as num).toDouble(),
        );

        setState(() {
          _totalReviewsCount = totalCount;
          _calculatedRating = sumRating / totalCount;
          _isReviewsLoading = false;
        });
      } else {
        setState(() {
          _totalReviewsCount = 0;
          _calculatedRating = _expertData?.rating ?? 4.8;
          _isReviewsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isReviewsLoading = false);
    }
  }

  // Fetch Certificates from Firestore
  Future<void> _fetchCertificatesFromFirestore(String expertId) async {
    try {
      if (mounted) setState(() => _isCertificatesLoading = true);

      final certsQuery = await FirebaseFirestore.instance
          .collection('certificates')
          .where('expertId', isEqualTo: expertId)
          .get();

      if (!mounted) return;

      setState(() {
        _certificates = certsQuery.docs.map((doc) => doc.data()).toList();
        _isCertificatesLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isCertificatesLoading = false);
    }
  }

  // Dialog to view Certificate image in full size
  void _showCertificateDialog(String title, String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Failed to load image preview'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation to Chat Screen
  void _navigateToChatScreen() async {
    if (_expertData == null || _isNavigatingToChat) return;

    setState(() => _isNavigatingToChat = true);

    try {
      final String chatId =
      await _chatService.createOrGetChat(_expertData!.uid);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            receiverId: _expertData!.uid,
            userName: _expertData!.name,
            userAvatar: _expertData!.profileImage,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open chat: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isNavigatingToChat = false);
      }
    }
  }

  // Navigation to Booking Screen
  void _navigateToBookingScreen() {
    if (_expertData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          expertId: _expertData!.uid,
          expertName: _expertData!.name,
          expertImage: _expertData!.profileImage,
          skill: _expertData!.skill,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Teacher Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50.withValues(alpha: 0.7),
              Colors.white,
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: _buildBodyContent(),
        ),
      ),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildBottomActionBar(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null && _errorMessage!.isNotEmpty ||
        _expertData == null) {
      return _buildErrorView();
    }

    final expert = _expertData!;
    final List<String> skillsList =
    expert.skills != null && expert.skills!.isNotEmpty
        ? expert.skills!
        : [
      expert.skill,
      expert.category,
      '${expert.level} Level',
      'Mentorship',
      'Code Review',
      '1-on-1 Session',
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 120.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circle Avatar
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade300,
                        Colors.purple.shade100
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.deepPurple.shade50,
                      backgroundImage: expert.profileImage.isNotEmpty
                          ? NetworkImage(expert.profileImage)
                          : null,
                      child: expert.profileImage.isEmpty
                          ? Text(
                        expert.name.isNotEmpty
                            ? expert.name[0].toUpperCase()
                            : 'E',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
                if (expert.verified)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Teacher Name & PRO Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  expert.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (expert.premium) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Skill Chip & Match Badge
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Text(
                  expert.skill.isNotEmpty ? expert.skill : expert.category,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
              if (expert.matchPercentage > 0)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${expert.matchPercentage}% Match',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Rating + Reviews Count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 22,
              ),
              const SizedBox(width: 4),
              Text(
                _calculatedRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              if (_isReviewsLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.deepPurple,
                  ),
                )
              else
                Text(
                  '($_totalReviewsCount Reviews)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Category & Level
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '${expert.level} in ${expert.category}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 20),

          // About Section
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About Expert',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  (expert.about != null && expert.about!.isNotEmpty)
                      ? expert.about!
                      : 'Verified ${expert.level} level expert in ${expert.skill} (${expert.category}). Dedicated to helping students learn effectively through interactive sessions.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dynamic Skills Section
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skills & Expertise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 10.0,
                  children: skillsList
                      .map((skillItem) => _buildSkillChip(skillItem))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Certificates Section
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Certificates & Credentials',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.verified_user_outlined,
                      size: 20,
                      color: Colors.deepPurple.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCertificatesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Certificates Section
  Widget _buildCertificatesSection() {
    if (_isCertificatesLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.deepPurple.shade400,
            ),
          ),
        ),
      );
    }

    if (_certificates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No certificates added yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _certificates.map((cert) {
        final title = cert['title'] ?? cert['name'] ?? 'Certified Professional';
        final issuer =
            cert['issuer'] ?? cert['issuedBy'] ?? 'Verified Institute';
        final year = cert['year'] ?? cert['issueDate'] ?? '';
        final imageUrl = cert['imageUrl'] ?? cert['certificateUrl'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: imageUrl.isNotEmpty
                ? () => _showCertificateDialog(title, imageUrl)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: imageUrl.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.card_membership,
                                color: Colors.deepPurple.shade700),
                      ),
                    )
                        : Icon(
                      Icons.card_membership_rounded,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          issuer +
                              (year.toString().isNotEmpty ? ' • $year' : ''),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (imageUrl.isNotEmpty)
                    Icon(
                      Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Skill Chip Builder
  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.shade100,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.purple.shade900,
        ),
      ),
    );
  }

  // Loading View
  Widget _buildLoadingSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.deepPurple.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Teacher Profile...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Error View
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage != null && _errorMessage!.isNotEmpty
                  ? _errorMessage!
                  : 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Action Bar
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isNavigatingToChat ? null : _navigateToChatScreen,
                icon: _isNavigatingToChat
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.deepPurple,
                  ),
                )
                    : const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                label: Text(
                  _isNavigatingToChat ? 'Connecting...' : 'Chat',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _navigateToBookingScreen,
                icon: const Icon(Icons.calendar_month_outlined, size: 20),
                label: const Text(
                  'Book Session',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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