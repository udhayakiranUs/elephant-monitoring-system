import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Photo evidence for full reports.
class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> capture() async {
    try {
      final result = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1600,
      );
      debugPrint('CameraService.capture() -> $result');
      return result;
    } catch (e, st) {
      debugPrint('CameraService.capture() FAILED: $e\n$st');
      return null;
    }
  }

  Future<List<XFile>> pickFromGallery() async {
    try {
      final result = await _picker.pickMultiImage(
        imageQuality: 75,
        maxWidth: 1600,
      );
      debugPrint(
          'CameraService.pickFromGallery() -> ${result.length} files: $result');
      return result;
    } catch (e, st) {
      debugPrint('CameraService.pickFromGallery() FAILED: $e\n$st');
      return const [];
    }
  }
}
