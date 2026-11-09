import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

/// Client uploads use a restricted unsigned preset. Never ship an API secret in a Flutter app.
class CloudinaryService {
  final String cloudName;
  final String uploadPreset;
  const CloudinaryService({required this.cloudName, required this.uploadPreset});

  Future<String?> uploadMedia(String filePath) async {
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
    final file = await http.MultipartFile.fromPath('file', filePath, contentType: _mediaType(mimeType));
    return _upload(mimeType.startsWith('video') ? 'video' : 'image', file);
  }

  Future<String?> uploadMediaFromBytes(Uint8List bytes, {required String fileName, required String mimeType}) async {
    final detected = lookupMimeType(fileName) ?? mimeType;
    final file = http.MultipartFile.fromBytes('file', bytes, filename: fileName, contentType: _mediaType(detected));
    return _upload(detected.startsWith('video') ? 'video' : 'image', file);
  }

  Future<String?> _upload(String resourceType, http.MultipartFile file) async {
    final uri = Uri.https('api.cloudinary.com', '/v1_1/$cloudName/$resourceType/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(file);
    final response = await request.send();
    final body = await response.stream.bytesToString();
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300 && decoded is Map<String, dynamic>) {
      return decoded['secure_url'] as String?;
    }
    throw Exception('Cloudinary upload failed with status ${response.statusCode}.');
  }

  MediaType _mediaType(String value) {
    final parts = value.split('/');
    if (parts.length != 2) return MediaType('application', 'octet-stream');
    return MediaType(parts[0], parts[1]);
  }
}
