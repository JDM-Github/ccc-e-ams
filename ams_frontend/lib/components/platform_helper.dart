import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PlatformHelper {
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static Future<bool> requestPermission(ImageSource source) async {
    if (!isMobile) return true;
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) openAppSettings();
        return false;
      }
    } else {
      final status = Platform.isIOS ? await Permission.photos.request() : await Permission.storage.request();
      if (!status.isGranted && !status.isLimited) return false;
    }
    return true;
  }

  static dynamic toFile(String path) => File(path);
}
