import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class CloudinaryService {
  final String cloudName;
  final String apiKey;
  final String apiSecret;
  final String uploadPreset;

  CloudinaryService({
    required this.cloudName,
    required this.apiKey,
    required this.apiSecret,
    required this.uploadPreset,
  });

  /// Upload media for Mobile (File Path)
  Future<String?> uploadMedia(String filePath) async {
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
    final fileExtension = mimeType.split('/').last;

    final endpoint = mimeType.startsWith('video')
        ? "https://api.cloudinary.com/v1_1/$cloudName/video/upload"
        : "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    final url = Uri.parse(endpoint);

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['api_key'] = apiKey
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType(mimeType.split('/').first, fileExtension),
        ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return json['secure_url'];
      } else {
        print("Cloudinary Upload Error: ${json['error']['message']}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  /// Upload media for Web (Bytes)
  Future<String?> uploadMediaFromBytes(
      Uint8List fileBytes, {
      required String fileName,
      required String mimeType,
    }) async {
    final endpoint = mimeType == 'mp4' || mimeType == 'mkv'
        ? "https://api.cloudinary.com/v1_1/$cloudName/video/upload"
        : "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    final url = Uri.parse(endpoint);

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['api_key'] = apiKey
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: MediaType(mimeType.split('/').first, mimeType.split('.').last),
        ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return json['secure_url'];
      } else {
        print("Cloudinary Upload Error: ${json['error']['message']}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }
}
