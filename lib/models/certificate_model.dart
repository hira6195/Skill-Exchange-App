import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateModel {
  final String certificateId;
  final String userId;
  final String title;
  final String skillName;
  final String certificateUrl; // Image or PDF download URL
  final DateTime issuedAt;

  CertificateModel({
    required this.certificateId,
    required this.userId,
    required this.title,
    required this.skillName,
    required this.certificateUrl,
    required this.issuedAt,
  });

  factory CertificateModel.fromMap(Map<String, dynamic> map, String id) {
    return CertificateModel(
      certificateId: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      skillName: map['skillName'] ?? '',
      certificateUrl: map['certificateUrl'] ?? '',
      issuedAt: (map['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}