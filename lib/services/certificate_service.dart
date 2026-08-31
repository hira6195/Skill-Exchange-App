import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CertificateService {
  final String _cloudName = "ubofyfvr";
  final String _uploadPreset = "certificate_upload";
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Pick File (PDF, PNG, JPG, JPEG, DOC, DOCX)
  Future<File?> pickCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Current User's Verification Status & Skill Limit
  Future<Map<String, dynamic>?> getUserVerificationStatus() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final query = await _db
        .collection('certificates')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }
    return null;
  }

  /// Direct Cloudinary Upload + Firestore Record Save
  Future<Map<String, dynamic>> uploadCertificate({
    required String skillName,
    required File certificate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User is not logged in!");

    // Check if user already uploaded a certificate (Free Tier Guard)
    final existingData = await getUserVerificationStatus();
    if (existingData != null && existingData['status'] != 'rejected') {
      throw Exception("Free Tier Limit Reached! You can only verify 1 skill in the free version.");
    }

    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/auto/upload");

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'certificates'
        ..files.add(await http.MultipartFile.fromPath('file', certificate.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonMap = json.decode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String secureUrl = jsonMap['secure_url'];
        final String publicId = jsonMap['public_id'];

        // Save Certificate info to Firestore
        await _db.collection('certificates').doc(user.uid).set({
          'userId': user.uid,
          'skillName': skillName,
          'fileUrl': secureUrl,
          'publicId': publicId,
          'status': 'pending', // 'pending', 'approved', 'rejected'
          'uploadedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return {
          'secureUrl': secureUrl,
          'publicId': publicId,
          'status': 'pending',
        };
      } else {
        throw Exception("Cloudinary Upload Error: ${jsonMap['error']?['message'] ?? 'Upload failed'}");
      }
    } catch (e) {
      rethrow;
    }
  }
}