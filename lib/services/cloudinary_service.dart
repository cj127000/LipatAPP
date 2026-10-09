import 'dart:convert';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static const String cloudName = 'vqnbstqy';
  static const String uploadPreset = 'lipatAPP';

  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    cloudName,
    uploadPreset,
    cache: false,
  );

  /// Uploads a base64-encoded image. Returns the secure HTTPS URL,
  /// or null on failure (the error is logged to the console).
  static Future<String?> uploadProof(
    String base64Image, {
    String? bookingCode,
  }) async {
    try {
      // Strip the "data:image/jpeg;base64," prefix if present.
      final clean =
          base64Image.contains(',') ? base64Image.split(',').last : base64Image;

      final bytes = base64Decode(clean);

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier:
              bookingCode ?? 'proof_${DateTime.now().millisecondsSinceEpoch}',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // ignore: avoid_print
      print('[Cloudinary] upload OK: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e, st) {
      // ignore: avoid_print
      print('[Cloudinary] upload FAILED: $e\n$st');
      return null;
    }
  }
}
