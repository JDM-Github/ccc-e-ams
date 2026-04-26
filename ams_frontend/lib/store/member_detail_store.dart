import 'dart:convert';
import 'package:ccc_ojt_schedule/components/schedule/schedule_record.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemberDetailStore extends ChangeNotifier {
  static const String _storageKeyPrefix = 'member_schedules_';

  List<ScheduleRecord> _schedules = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetched;
  String? _currentMemberCccId;

  List<ScheduleRecord> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetched => _lastFetched;

  double calculateHours(TimeOfDay timeIn, TimeOfDay timeOut) {
    final timeInMinutes = timeIn.hour * 60 + timeIn.minute;
    final timeOutMinutes = timeOut.hour * 60 + timeOut.minute;

    if (timeOutMinutes <= timeInMinutes) return 0;

    int totalMinutes = timeOutMinutes - timeInMinutes;

    const lunchStart = 12 * 60;
    const lunchEnd = 13 * 60;
    if (timeOutMinutes > lunchStart && timeInMinutes < lunchEnd) {
      final overlapStart = timeInMinutes > lunchStart ? timeInMinutes : lunchStart;
      final overlapEnd = timeOutMinutes < lunchEnd ? timeOutMinutes : lunchEnd;
      final lunchMinutes = overlapEnd - overlapStart;
      totalMinutes -= lunchMinutes;
    }

    return totalMinutes / 60.0;
  }

  TimeOfDay _getEffectiveTimeIn(ScheduleRecord record) {
    if (record.timeIn.hour < 8 && !record.isAcceptedEarly) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
    return record.timeIn;
  }

  double get totalCompletedHours {
    return _schedules.fold(0.0, (sum, record) {
      if (!record.isInOffice && !record.isAcceptedWorkFromHome) return sum;

      final effectiveTimeIn = _getEffectiveTimeIn(record);
      if (record.timeOut == null) return sum;
      TimeOfDay effectiveTimeOut =
          record.timeOut ??
          (record.date.isBefore(DateTime.now())
              ? const TimeOfDay(hour: 17, minute: 0)
              : record.timeOut ?? const TimeOfDay(hour: 17, minute: 0));

      return sum + calculateHours(effectiveTimeIn, effectiveTimeOut);
    });
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    return recordDate.isBefore(today);
  }

  void _applyAutoTimeouts() {
    for (var record in _schedules) {
      if (_isPastDate(record.date) && record.timeOut == null) {
        record.timeOut = const TimeOfDay(hour: 17, minute: 0);
      }
    }
  }

  Future<void> loadFromLocal(String cccId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString('$_storageKeyPrefix$cccId');
      final String? lastFetchedStr = prefs.getString('${_storageKeyPrefix}${cccId}_last_fetched');

      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        _schedules = jsonList.map((json) => ScheduleRecord.fromJson(json)).toList();
        _applyAutoTimeouts();

        if (lastFetchedStr != null) {
          _lastFetched = DateTime.parse(lastFetchedStr);
        }

        _currentMemberCccId = cccId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading member schedules from local storage: $e');
    }
  }

  Future<void> saveToLocal(String cccId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _schedules.map((record) => record.toJson()).toList();
      await prefs.setString('$_storageKeyPrefix$cccId', jsonEncode(jsonList));
      await prefs.setString('${_storageKeyPrefix}${cccId}_last_fetched', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving member schedules to local storage: $e');
    }
  }

  Future<void> fetchSchedules(String cccId) async {
    _isLoading = true;
    _error = null;
    _currentMemberCccId = cccId;
    notifyListeners();

    try {
      final requestHandler = RequestHandler();
      final response = await requestHandler.handleRequest('user/schedules/$cccId', method: 'GET');

      if (response['success'] == true) {
        final List<dynamic> schedulesJson = response['schedules'];
        _schedules = schedulesJson.map((json) => ScheduleRecord.fromJson(json, isFetchedFromDatabase: true)).toList();
        _applyAutoTimeouts();
        _lastFetched = DateTime.now();
        await saveToLocal(cccId);
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to fetch schedules';
      }
    } catch (e) {
      _error = 'Network error: $e';
      debugPrint('Error fetching member schedules: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSchedule(ScheduleRecord newRecord) async {
    await _syncAddSchedule(newRecord);
  }

  Future<void> updateSchedule(int index, ScheduleRecord updatedRecord) async {
    await _syncUpdate(updatedRecord);
  }

  Future<void> deleteSchedule(int index) async {
    if (index >= 0 && index < _schedules.length) {
      final record = _schedules[index];
      _schedules.removeAt(index);

      if (_currentMemberCccId != null) {
        await saveToLocal(_currentMemberCccId!);
      }
      notifyListeners();
      await _syncDelete(record);
    }
  }

  Future<void> _syncAddSchedule(ScheduleRecord record) async {
    try {
      final requestHandler = RequestHandler();

      final body = {
        'ccc_id': _currentMemberCccId,
        'date': record.date.toIso8601String().split('T')[0],
        'time_in':
            '${record.timeIn.hour.toString().padLeft(2, '0')}:${record.timeIn.minute.toString().padLeft(2, '0')}:00',
        'isInOffice': record.isInOffice,
        'isAcceptedEarly': record.isAcceptedEarly,
        'isAcceptedWorkFromHome': record.isAcceptedWorkFromHome,
      };

      if (record.timeOut != null) {
        body['time_out'] =
            '${record.timeOut!.hour.toString().padLeft(2, '0')}:${record.timeOut!.minute.toString().padLeft(2, '0')}:00';
      }

      final response = await requestHandler.handleRequest('user/schedule/add', method: 'POST', body: body);
      if (response['success'] == true) {
        final newRecord = ScheduleRecord.fromJson(response['schedule'], isFetchedFromDatabase: true);
        _schedules.add(newRecord);
        if (_currentMemberCccId != null) {
          await saveToLocal(_currentMemberCccId!);
        }
        notifyListeners();
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      debugPrint('Sync add schedule failed: $e');
      rethrow;
    }
  }

  Future<void> _syncUpdate(ScheduleRecord record) async {
    try {
      final requestHandler = RequestHandler();

      final body = {
        'id': record.id,
        'time_in':
            '${record.timeIn.hour.toString().padLeft(2, '0')}:${record.timeIn.minute.toString().padLeft(2, '0')}:00',
        'isInOffice': record.isInOffice,
        'isAcceptedEarly': record.isAcceptedEarly,
        'isAcceptedWorkFromHome': record.isAcceptedWorkFromHome,
      };
      if (record.timeOut != null) {
        body['time_out'] =
            '${record.timeOut!.hour.toString().padLeft(2, '0')}:${record.timeOut!.minute.toString().padLeft(2, '0')}:00';
      }
      final response = await requestHandler.handleRequest('user/schedule/update', method: 'POST', body: body);
      if (response['success'] == true) {
        final index = _schedules.indexWhere((r) => r.id == record.id);
        if (index != -1) {
          record.alreadyInDatabase = true;
          _schedules[index] = record;
          if (_currentMemberCccId != null) {
            await saveToLocal(_currentMemberCccId!);
          }
          notifyListeners();
        }
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      debugPrint('Sync update failed: $e');
      rethrow;
    }
  }

  Future<void> _syncDelete(ScheduleRecord record) async {
    try {
      final requestHandler = RequestHandler();
      await requestHandler.handleRequest('user/schedule/${record.id}', method: 'DELETE');
    } catch (e) {
      debugPrint('Sync delete failed: $e');
    }
  }

  Future<void> clearAll() async {
    if (_currentMemberCccId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_storageKeyPrefix$_currentMemberCccId');
      await prefs.remove('${_storageKeyPrefix}${_currentMemberCccId}_last_fetched');
    }

    _schedules.clear();
    _lastFetched = null;
    _currentMemberCccId = null;
    notifyListeners();
  }
}
