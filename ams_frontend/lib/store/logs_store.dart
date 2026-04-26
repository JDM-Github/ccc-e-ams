// lib/store/logs_store.dart
import 'dart:convert';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogType { timeIn, timeOut, create, update, delete, sync, error, info }

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogType type;
  final String message;

  LogEntry({required this.id, required this.timestamp, required this.type, required this.message});

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'].toString(),
      timestamp: DateTime.parse(json['createdAt']),
      type: LogType.values.firstWhere((e) => e.name == json['log_type'], orElse: () => LogType.info),
      message: json['message'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'log_type': type.name,
      'message': message,
      'createdAt': timestamp.toIso8601String(),
    };
  }
}

class LogsStore extends ChangeNotifier {
  static final LogsStore _instance = LogsStore._internal();
  factory LogsStore() => _instance;
  LogsStore._internal();

  static const String _storageKey = 'activity_logs';

  List<LogEntry> _logs = [];
  String? _error;
  bool _isLoading = false;

  List<LogEntry> get logs => _logs;
  bool get isLoading => _isLoading;

  Future<void> loadFromLocal() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_storageKey);

      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        _logs = jsonList.map((json) => LogEntry.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _logs.map((log) => log.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving logs: $e');
    }
  }

  Future<void> fetchAllLogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final handler = RequestHandler();
      final response = await handler.handleRequest('user/logs', method: 'GET');

      if (response['success'] == true && response['logs'] != null) {
        final List<dynamic> logsJson = response['logs'];
        _logs = logsJson.map((json) => LogEntry.fromJson(json)).toList();
        await saveToLocal();
      } else {
        _error = response['message'] ?? 'Failed to fetch logs';
      }
    } catch (e) {
      _error = 'Network error: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _logs.clear();
    notifyListeners();
  }

  List<LogEntry> filterByType(LogType? type) {
    if (type == null) return _logs;
    return _logs.where((log) => log.type == type).toList();
  }

  List<LogEntry> filterByDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return _logs;

    return _logs.where((log) {
      if (start != null && log.timestamp.isBefore(start)) return false;
      if (end != null && log.timestamp.isAfter(end)) return false;
      return true;
    }).toList();
  }
}
