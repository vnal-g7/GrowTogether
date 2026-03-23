import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class UploadService {
  static const String _cloudName = 'dfcthorll';
  static const String _uploadPreset = 'GrowTogether Images';

  static const int maxOriginalBytes = 8 * 1024 * 1024; // 8 MB
  static const int maxCompressedBytes = 2 * 1024 * 1024; // 2 MB target

  static const List<String> _allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];

  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  Future<String> uploadChallengeImage({
    required XFile file,
    required String userId,
    required String challengeId,
  }) async {
    _validateConfig();
    await _validatePickedFile(file);

    final Uint8List compressedBytes = await _compressImage(file);

    if (compressedBytes.isEmpty) {
      throw Exception('Image compression failed.');
    }

    if (compressedBytes.length > maxCompressedBytes) {
      throw Exception(
        'Compressed image is still too large. Please choose a smaller image.',
      );
    }

    final String mimeType =
        lookupMimeType(file.name, headerBytes: compressedBytes) ??
        'image/jpeg';

    if (!_allowedMimeTypes.contains(mimeType)) {
      throw Exception('Only JPG, PNG, and WEBP images are allowed.');
    }

    final List<String> mimeParts = mimeType.split('/');
    if (mimeParts.length != 2) {
      throw Exception('Invalid image type detected.');
    }

    final String fileName = _buildFileName(
      userId,
      challengeId,
      file.name,
      mimeType,
    );

    final request =
        http.MultipartRequest('POST', Uri.parse(_uploadUrl))
          ..fields['upload_preset'] = _uploadPreset
          ..fields['folder'] = 'growtogether/submissions/$userId/$challengeId'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              compressedBytes,
              filename: fileName,
              contentType: MediaType(mimeParts[0], mimeParts[1]),
            ),
          );

    final streamedResponse = await request.send();
    final result = await http.Response.fromStream(streamedResponse);

    if (result.statusCode != 200 && result.statusCode != 201) {
      throw Exception('Upload failed (${result.statusCode}): ${result.body}');
    }

    final dynamic data = jsonDecode(result.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid Cloudinary response.');
    }

    final String? secureUrl = data['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('No secure image URL returned by Cloudinary.');
    }

    return secureUrl;
  }

  void _validateConfig() {
    if (_cloudName.trim().isEmpty || _uploadPreset.trim().isEmpty) {
      throw Exception('Cloudinary configuration is missing.');
    }
  }

  Future<void> _validatePickedFile(XFile file) async {
    final int size = await file.length();

    if (size <= 0) {
      throw Exception('Selected image is empty.');
    }

    if (size > maxOriginalBytes) {
      throw Exception('Image too large. Maximum allowed size is 8MB.');
    }

    final Uint8List bytes = await file.readAsBytes();

    final String? mimeType = lookupMimeType(
      file.name,
      headerBytes: bytes.length > 32 ? bytes.sublist(0, 32) : bytes,
    );

    if (mimeType == null || !_allowedMimeTypes.contains(mimeType)) {
      throw Exception('Only JPG, PNG, and WEBP images are allowed.');
    }
  }

  Future<Uint8List> _compressImage(XFile file) async {
    final Uint8List originalBytes = await file.readAsBytes();

    final Uint8List compressedFirstPass =
        await FlutterImageCompress.compressWithList(
          originalBytes,
          quality: 70,
          minWidth: 1280,
          minHeight: 1280,
          format: CompressFormat.jpeg,
        );

    if (compressedFirstPass.isEmpty) {
      throw Exception('Failed to compress image.');
    }

    if (compressedFirstPass.length <= maxCompressedBytes) {
      return compressedFirstPass;
    }

    final Uint8List compressedSecondPass =
        await FlutterImageCompress.compressWithList(
          compressedFirstPass,
          quality: 55,
          minWidth: 1080,
          minHeight: 1080,
          format: CompressFormat.jpeg,
        );

    if (compressedSecondPass.isEmpty) {
      throw Exception('Failed during final compression.');
    }

    return compressedSecondPass;
  }

  String _buildFileName(
    String userId,
    String challengeId,
    String originalName,
    String mimeType,
  ) {
    final int time = DateTime.now().millisecondsSinceEpoch;

    final String safeOriginal =
        originalName
            .replaceAll(RegExp(r'\s+'), '_')
            .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');

    final String ext;
    if (mimeType == 'image/png') {
      ext = 'png';
    } else if (mimeType == 'image/webp') {
      ext = 'webp';
    } else {
      ext = 'jpg';
    }

    final String cleanedBase =
        safeOriginal.contains('.')
            ? safeOriginal.substring(0, safeOriginal.lastIndexOf('.'))
            : safeOriginal;

    return 'proof_${userId}_${challengeId}_${cleanedBase}_$time.$ext';
  }
}