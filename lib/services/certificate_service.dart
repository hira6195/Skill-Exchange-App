import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

  /// NEW: Compresses image certificates before upload.
  /// PDFs / DOC / DOCX are returned unchanged (can't be safely re-encoded).
  /// This is the #1 fix for slow uploads — a 8-10MB phone photo becomes
  /// ~300-800KB with almost no visible quality loss.
  Future<File> _optimizeFileForUpload(File original) async {
    final String ext = p.extension(original.path).toLowerCase();
    final bool isImage = ext == '.jpg' || ext == '.jpeg' || ext == '.png';

    if (!isImage) return original; // PDFs/DOC left as-is

    try {
      final int originalSizeKb = (await original.length()) ~/ 1024;

      // Skip compression if already small (e.g. < 400KB) — saves CPU time
      if (originalSizeKb < 400) return original;

      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = p.join(
        tempDir.path,
        'cert_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        original.absolute.path,
        targetPath,
        quality: 70, // good balance of clarity vs size for a document photo
        minWidth: 1600,
        minHeight: 1600,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile != null) {
        return File(compressedXFile.path);
      }
      return original;
    } catch (e) {
      // If compression fails for any reason, fall back to original file
      // rather than blocking the whole upload flow.
      return original;
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
      // NEW: compress before sending over the network — this is what was
      // making the upload feel slow on normal mobile connections.
      final File uploadFile = await _optimizeFileForUpload(certificate);

      final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/auto/upload");

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'certificates'
        ..files.add(await http.MultipartFile.fromPath('file', uploadFile.path));

      // NEW: hard timeout so the UI never hangs forever on a bad connection —
      // user gets a clear error instead of an endless spinner.
      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              "Upload timed out. Please check your internet connection and try again.");
        },
      );

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