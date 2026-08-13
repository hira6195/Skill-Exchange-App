import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class CertificateService {
  // TODO: Replace with your actual Cloudinary credentials if different
  final String _cloudName = "ubofyfvr";
  final String _uploadPreset = "certificate_upload";

  /// File Picker
  Future<File?> pickCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Direct Cloudinary Upload (No Firebase Storage dependency)
  Future<Map<String, dynamic>> uploadCertificate({
    required String skillName,
    required File certificate,
  }) async {
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
        return {
          'secureUrl': jsonMap['secure_url'],
          'publicId': jsonMap['public_id'],
        };
      } else {
        throw Exception("Cloudinary Upload Error: ${jsonMap['error']?['message'] ?? 'Upload failed'}");
      }
    } catch (e) {
      rethrow;
    }
  }
}