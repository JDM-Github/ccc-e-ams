import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ccc_ojt_schedule/components/schedule/schedule_record.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ScheduleStore extends ChangeNotifier {
  static const String _storageKey = 'schedules_cache';
  List<ScheduleRecord> _schedules = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetched;

  List<ScheduleRecord> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetched => _lastFetched;

  Future<void> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_storageKey);
      final String? lastFetchedStr = prefs.getString('${_storageKey}_last_fetched');

      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        _schedules = jsonList.map((json) => ScheduleRecord.fromJson(json)).toList();

        if (lastFetchedStr != null) {
          _lastFetched = DateTime.parse(lastFetchedStr);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading from local storage: $e');
    }
  }

  Future<void> saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _schedules.map((record) => record.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
      await prefs.setString('${_storageKey}_last_fetched', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  Future<void> fetchSchedules(String cccId) async {
    _isLoading = true;
    _error = null;
    RequestHandler requestHandler = RequestHandler();

    try {
      final localOnlySchedules = _schedules.where((s) => !s.alreadyInDatabase).toList();
      final response = await requestHandler.handleRequest('user/schedules/$cccId', method: 'GET');

      if (response['success'] == true) {
        final List<dynamic> schedulesJson = response['schedules'];
        _schedules = schedulesJson.map((json) => ScheduleRecord.fromJson(json, isFetchedFromDatabase: true)).toList();
        _lastFetched = DateTime.now();

        if (localOnlySchedules.isNotEmpty) {
          await _syncLocalSchedules(localOnlySchedules, cccId);
        }
        await saveToLocal();
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to fetch schedules';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncLocalSchedules(List<ScheduleRecord> localSchedules, String cccId) async {
    for (var localRecord in localSchedules) {
      final existsInDb = _schedules.any(
        (dbRecord) =>
            dbRecord.date.year == localRecord.date.year &&
            dbRecord.date.month == localRecord.date.month &&
            dbRecord.date.day == localRecord.date.day &&
            dbRecord.timeIn.hour == localRecord.timeIn.hour &&
            dbRecord.timeIn.minute == localRecord.timeIn.minute,
      );
      if (!existsInDb) {
        await _syncAdd(localRecord, cccId);
        await _syncUpdate(localRecord);
      }
    }
  }

  Future<void> addSchedule(ScheduleRecord record) async {
    final loginStore = LoginStore();
    if (loginStore.user.value.isNotEmpty) {
      final cccId = loginStore.user.value['ccc_id'];
      await _syncAdd(record, cccId);
    }
  }

  Future<void> updateSchedule(int index, ScheduleRecord record) async {
    if (index >= 0 && index < _schedules.length) {
      await _syncUpdate(record);
    }
  }

  Future<void> _syncAdd(ScheduleRecord record, String cccId) async {
    try {
      String? imageUrl;
      Uint8List? bytes;
      String filename = 'proof_in_${record.date.toIso8601String()}.jpg';

      if (record.proofInFile != null) {
        bytes = await record.proofInFile!.readAsBytes();
        filename = record.proofInFile!.name.isNotEmpty
            ? record.proofInFile!.name
            : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else if (record.proofIn != null && record.proofIn!.isNotEmpty) {
        final cleaned = record.proofIn!.contains(',') ? record.proofIn!.split(',').last : record.proofIn!;

        bytes = base64Decode(cleaned);

        if (bytes.isEmpty) {
          throw Exception('Failed to decode proof image.');
        }
      }

      if (bytes != null) {
        final uri = Uri.parse('${RequestHandler().baseUrl}/.netlify/functions/api/user/upload-proof');
        final request = http.MultipartRequest('POST', uri);
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

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
      }

      final handler = RequestHandler();
      final response = await handler.handleRequest(
        'user/schedule',
        method: 'POST',
        body: {
          'ccc_id': cccId,
          'date': record.date.toIso8601String().split('T')[0],
          'time_in':
              '${record.timeIn.hour.toString().padLeft(2, '0')}:${record.timeIn.minute.toString().padLeft(2, '0')}:00',
          'proof_in': imageUrl,
          'isInOffice': record.isInOffice,
        },
      );

      if (response['success'] != true) {
        throw Exception('Failed to save schedule record.');
      }
      record.alreadyInDatabase = true;
      record.proofInFile = null;

      _schedules.insert(0, record);

      await saveToLocal();
      notifyListeners();
    } catch (e) {
      throw Exception('Sync schedule failed: $e');
    }
  }

  Future<void> _syncUpdate(ScheduleRecord record) async {
    final loginStore = LoginStore();
    if (loginStore.user.value.isEmpty) {
      throw Exception('User not authenticated.');
    }

    final cccId = loginStore.user.value['ccc_id'];

    if (record.timeOut == null) {
      throw Exception('Time out is required.');
    }

    

    try {
      String? imageUrl;
      Uint8List? bytes;
      String filename = 'proof_out_${record.date.toIso8601String()}.jpg';

      if (record.proofOutFile != null) {
        bytes = await record.proofOutFile!.readAsBytes();
        filename = record.proofOutFile!.name.isNotEmpty
            ? record.proofOutFile!.name
            : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else if (record.proofOut != null && record.proofOut!.isNotEmpty) {
        final cleaned = record.proofOut!.contains(',') ? record.proofOut!.split(',').last : record.proofOut!;

        bytes = base64Decode(cleaned);
        if (bytes.isEmpty) {
          throw Exception('Failed to decode proof out image.');
        }
      }

      if (bytes != null) {
        final uri = Uri.parse('${RequestHandler().baseUrl}/.netlify/functions/api/user/upload-proof');
        final request = http.MultipartRequest('POST', uri);
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

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
      }

      final handler = RequestHandler();
      final response = await handler.handleRequest(
        'user/schedule/timeout',
        method: 'PUT',
        body: {
          'id': record.id,
          'ccc_id': cccId,
          'date': record.date.toIso8601String(),
          'time_out':
              '${record.timeOut!.hour.toString().padLeft(2, '0')}:${record.timeOut!.minute.toString().padLeft(2, '0')}:00',
          'proof_out': imageUrl,
        },
      );

      if (response['success'] != true) {
        throw Exception('Failed to update schedule timeout.');
      }

      await saveToLocal();
      notifyListeners();
    } catch (e) {
      throw Exception('Sync update failed: $e');
    }
  }

  Future<void> clearAll() async {
    _schedules.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove('${_storageKey}_last_fetched');
    _lastFetched = null;
    notifyListeners();
  }
}
