import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Complaint / Report system (admin website ke Complaints page ka data yahin se aata hai).
class ComplaintService {
  static Future<void> submit({
    required String reportedUserId,
    required String reportedUserName,
    required String reason,
    String details = '',
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    await FirebaseFirestore.instance.collection('complaints').add({
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'reportedById': me.uid,
      'reportedByName': me.displayName ?? me.email ?? 'User',
      'reason': reason,
      'details': details,
      'status': 'Pending', // Pending -> In Review -> Resolved
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Kisi bhi screen se call karo:
/// showReportDialog(context, reportedUserId: ..., reportedUserName: ...)
Future<void> showReportDialog(
    BuildContext context, {
      required String reportedUserId,
      required String reportedUserName,
    }) async {
  const reasons = [
    'Inappropriate Behavior',
    'Spam',
    'Harassment',
    'Fake Profile',
    'Other',
  ];
  String reason = reasons.first;
  final detailsCtrl = TextEditingController();

  final bool? submit = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Report $reportedUserName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: reason,
              items: reasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => reason = v ?? reason),
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    ),
  );

  final details = detailsCtrl.text.trim();
  detailsCtrl.dispose();

  if (submit == true) {
    try {
      await ComplaintService.submit(
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        reason: reason,
        details: details,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit report: $e')),
        );
      }
    }
  }
}