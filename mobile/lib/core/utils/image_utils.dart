import 'package:image_picker/image_picker.dart';

abstract final class ImageUtils {
  static final _picker = ImagePicker();

  static Future<XFile?> pickFromGallery({int maxWidth = 1024}) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
      imageQuality: 80,
    );
    return image;
  }

  static Future<XFile?> pickFromCamera({int maxWidth = 1024}) async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth.toDouble(),
      imageQuality: 80,
    );
    return image;
  }

  static Future<List<XFile>> pickMultipleFromGallery({int maxWidth = 1024}) async {
    final images = await _picker.pickMultiImage(
      maxWidth: maxWidth.toDouble(),
      imageQuality: 80,
    );
    return images;
  }
}
