import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ARImage {
  final DateTime addedAt;
  final String? description;
  String id;
  String image;
  bool isInDatabase = false;

  ARImage({required this.id, required this.image, required this.addedAt, this.description});

  Map<String, dynamic> toJson() {
    return {'id': id, 'image': image, 'addedAt': addedAt.toIso8601String(), 'description': description, 'isInDatabase': isInDatabase,
    };
  }

  factory ARImage.fromJson(Map<String, dynamic> json, {bool isInDatabase = false}) {
    final ar = ARImage(
      id: json['id'].toString(),
      image: json['image'] ?? json['image_url'],
      addedAt: DateTime.parse(json['addedAt'] ?? json['createdAt'] ?? json['created_at']).toLocal(),
      description: json['description'],
    );
    ar.isInDatabase = isInDatabase || (json['isInDatabase'] == true);
    return ar;
  }
}

class ARStore extends ChangeNotifier {
  static final ARStore _instance = ARStore._internal();
  factory ARStore() => _instance;
  ARStore._internal();

  Map<String, List<ARImage>> _arImages = {};
  bool _isLoading = false;
  String? _error;

  Map<String, List<ARImage>> get arImages => _arImages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ARImage> getImagesForRecord(String currentDate) {
    return _arImages[currentDate] ?? [];
  }

  int getImageCountForRecord(String currentDate) {
    return _arImages[currentDate]?.length ?? 0;
  }

  Future<void> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString('ar_images');

      if (cachedData != null) {
        final Map<String, dynamic> decoded = jsonDecode(cachedData);
        _arImages = decoded.map((key, value) {
          final List<dynamic> imagesList = value as List;
          return MapEntry(key, imagesList.map((img) => ARImage.fromJson(img)).toList());
        });

        notifyListeners();
        for (final entry in _arImages.entries) {
          final currentDate = entry.key;
          final unsyncedImages = entry.value.where((img) => img.isInDatabase == false).toList();

          for (final image in unsyncedImages) {
            _syncAddImage(currentDate, image)
                .catchError((e) {
                  debugPrint('Failed to sync unsynced AR image ${image.id}: $e');
                });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading AR images from local storage: $e');
      _error = 'Failed to load AR images';
    }
  }

  Future<void> fetchARActivities(String currentDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final requestHandler = RequestHandler();
    try {
      final response = await requestHandler.handleRequest('user/fetch-all-ar/$currentDate', method: 'GET');

      if (response['success'] == true) {
        final List<dynamic> arJson = response['activityRecords'] ?? [];
        final List<ARImage> images = arJson.map((json) => ARImage.fromJson(json, isInDatabase: true)).toList();
        _arImages[currentDate] = images;
        await saveToLocal();
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to fetch AR activities';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toSave = _arImages.map((key, value) {
        return MapEntry(key, value.map((img) => img.toJson()).toList());
      });
      await prefs.setString('ar_images', jsonEncode(toSave));
    } catch (e) {
      debugPrint('Error saving AR images to local storage: $e');
      _error = 'Failed to save AR images';
    }
  }

  Future<void> addImage(String currentDate, String imageBase64, bool isAlreadyInDatabase, {String? description}) async {
    try {
      final newImage = ARImage(
        id: '${currentDate}_${DateTime.now().millisecondsSinceEpoch}',
        image: imageBase64,
        addedAt: DateTime.now(),
        description: description,
      );
      if (_arImages[currentDate] == null) {
        _arImages[currentDate] = [];
      }
      if (isAlreadyInDatabase) {
        await _syncAddImage(currentDate, newImage);
      }
    } catch (e) {
      debugPrint('Error adding AR image: $e');
      _error = 'Failed to add image';
      notifyListeners();
    }
  }

  Future<void> deleteImage(String currentDate, String imageId) async {
    try {
      final images = _arImages[currentDate];
      if (images == null) return;
      final index = images.indexWhere((img) => img.id == imageId);
      if (index == -1) return;

      final image = images[index];
      if (image.isInDatabase) {
        if (await _syncDeleteImage(imageId)) {
          images.removeAt(index);
          if (images.isEmpty) {
            _arImages.remove(currentDate);
          }
          await saveToLocal();
          notifyListeners();
        } else {
          _error = 'Failed to delete image from server';
          notifyListeners();
        }
      } else {
        images.removeAt(index);
        if (images.isEmpty) {
          _arImages.remove(currentDate);
        }
        await saveToLocal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting AR image: $e');
      _error = 'Failed to delete image';
      notifyListeners();
    }
  }

  Future<void> updateDescription(String currentDate, String imageId, String description) async {
    try {
      if (_arImages[currentDate] != null) {
        final index = _arImages[currentDate]!.indexWhere((img) => img.id == imageId);
        if (index != -1) {
          final oldImage = _arImages[currentDate]![index];

          final updated = ARImage(
            id: oldImage.id,
            image: oldImage.image,
            addedAt: oldImage.addedAt,
            description: description,
          );
          updated.isInDatabase = oldImage.isInDatabase;
          _arImages[currentDate]![index] = updated;

          await saveToLocal();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating description: $e');
      _error = 'Failed to update description';
      notifyListeners();
    }
  }

  Future<void> _syncAddImage(String currentDate, ARImage image) async {
    try {
      String? imageUrl;

      if (image.image.isEmpty) {
        throw Exception('Image data is empty.');
      }
      final cleaned = image.image.contains(',') ? image.image.split(',').last : image.image;
      final bytes = base64Decode(cleaned);

      if (bytes.isEmpty) {
        throw Exception('Failed to decode image data.');
      }
      final uri = Uri.parse('${RequestHandler().baseUrl}/.netlify/functions/api/user/upload-proof');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'ar_${image.addedAt.millisecondsSinceEpoch}.jpg'),
      );

      final uploadResponse = await request.send();
      final respStr = await uploadResponse.stream.bytesToString();

      if (uploadResponse.statusCode != 200) {
        throw Exception('Image upload failed with status code ${uploadResponse.statusCode}.');
      }

      final respJson = jsonDecode(respStr);

      if (respJson['success'] != true || respJson['url'] == null) {
        throw Exception('Image upload failed: invalid server response.');
      }

      imageUrl = respJson['url'];

      final handler = RequestHandler();
      final response = await handler.handleRequest(
        'user/add-ar',
        method: 'POST',
        body: {'schedule_record_date': currentDate, 'image_url': imageUrl, 'description': image.description},
      );

      if (response['success'] != true || response['activityRecord'] == null) {
        throw Exception('Failed to save image record.');
      }

      image.image = imageUrl!;
      image.isInDatabase = true;
      image.id = response['activityRecord']['id'].toString();

      _arImages[currentDate]!.add(image);

      await saveToLocal();
      notifyListeners();
    } catch (e) {
      throw Exception('Sync image failed: $e');
    }
  }

  Future<bool> _syncDeleteImage(String imageId) async {
    try {
      final handler = RequestHandler();
      final response = await handler.handleRequest('user/delete-ar/$imageId', method: 'DELETE');
      if (response['success'] != true) {
        throw Exception('Failed to delete AR image');
      } else {
        return true;
      }
    } catch (e) {
      debugPrint('Sync AR delete failed: $e');
      return false;
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ar_images');
    _arImages.clear();
    notifyListeners();
  }
}
