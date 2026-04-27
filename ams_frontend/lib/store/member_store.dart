// Author: JDM
// Updated on: 2026-03-22

import 'dart:convert';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Member {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? suffixName;
  final String? extensionName;
  final String cccId;
  final String email;
  final String? course;
  final String? profileLink;
  final int? targetHours;
  final String role;
  final bool isAdmin;
  final int current_sy;
  final DateTime createdAt;

  final String? customId;
  final String? status;

  final double? completedHours;
  final double? remainingHours;
  final int? totalSchedules;
  final double? progress;
  final bool? isDone;

  Member({
    required this.id,
    required this.firstName,
    this.middleName,
    this.suffixName,
    this.extensionName,
    required this.lastName,
    required this.cccId,
    required this.email,
    this.course,
    this.profileLink,
    this.targetHours,
    required this.role,
    required this.isAdmin,
    required this.current_sy,
    required this.createdAt,

    this.customId,
    this.status,
    this.completedHours,
    this.remainingHours,
    this.totalSchedules,
    this.progress,
    this.isDone,
  });

  // ─── copyWith ─────────────────────────────────────────────────────────────

  Member copyWith({
    String? id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? suffixName,
    String? extensionName,
    String? cccId,
    String? email,
    String? course,
    String? profileLink,
    int? targetHours,
    String? role,
    bool? isAdmin,
    int? current_sy,
    DateTime? createdAt,
    String? customId,
    String? status,
    double? completedHours,
    double? remainingHours,
    int? totalSchedules,
    double? progress,
    bool? isDone,
  }) {
    return Member(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      suffixName: suffixName ?? this.suffixName,
      extensionName: extensionName ?? this.extensionName,
      cccId: cccId ?? this.cccId,
      email: email ?? this.email,
      course: course ?? this.course,
      profileLink: profileLink ?? this.profileLink,
      targetHours: targetHours ?? this.targetHours,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      current_sy: current_sy ?? this.current_sy,
      createdAt: createdAt ?? this.createdAt,
      customId: customId ?? this.customId,
      status: status ?? this.status,
      completedHours: completedHours ?? this.completedHours,
      remainingHours: remainingHours ?? this.remainingHours,
      totalSchedules: totalSchedules ?? this.totalSchedules,
      progress: progress ?? this.progress,
      isDone: isDone ?? this.isDone,
    );
  }

  bool get isSupervisor => role == 'supervisor';
  String get progressLabel {
    if (progress == null) return '';
    return '${(progress! * 100).toStringAsFixed(1)}%';
  }

  String get hoursLabel {
    final completed = completedHours?.toStringAsFixed(1) ?? '0';
    final target = targetHours?.toString() ?? '0';
    return '$completed / $target hrs';
  }

  String get fullName {
    String base = _buildBaseName();
    if (suffixName != null && suffixName!.isNotEmpty) {
      base = '$base, ${suffixName!}';
    }
    return base;
  }

  String get fullNameExtended {
    String base = _buildBaseName();
    if (suffixName != null && suffixName!.isNotEmpty) {
      base = '$base, ${suffixName!}';
    }
    if (extensionName != null && extensionName!.isNotEmpty) {
      base = '$base, ${extensionName!}';
    }
    return base;
  }

  String _buildBaseName() {
    if (middleName != null && middleName!.isNotEmpty) {
      final initials = middleName!
          .trim()
          .split(RegExp(r'\s+'))
          .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
          .join('.');
      return '$firstName $initials. $lastName';
    }
    return '$firstName $lastName';
  }

  String get initials {
    String first = firstName.isNotEmpty ? firstName[0] : '';
    String last = lastName.isNotEmpty ? lastName[0] : '';
    return (first + last).toUpperCase();
  }

  // ─── Serialisation ────────────────────────────────────────────────────────

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'].toString(),
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'],
      lastName: json['last_name'] ?? '',
      suffixName: json['suffix_name'],
      extensionName: json['extension_name'],
      cccId: json['ccc_id'] ?? '',
      email: json['email'] ?? '',
      course: json['course'],
      profileLink: json['profile_link'],
      targetHours: json['target_hours'],
      role: json['role'] ?? 'student',
      isAdmin: json['isAdmin'] ?? false,
      current_sy: json['current_sy'] ?? 0,
      customId: json['custom_id'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      completedHours: (json['completed_hours'] as num?)?.toDouble(),
      remainingHours: (json['remaining_hours'] as num?)?.toDouble(),
      totalSchedules: json['total_schedules'] as int?,
      progress: (json['progress'] as num?)?.toDouble(),
      isDone: json['is_done'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'suffix_name': suffixName,
      'extension_name': extensionName,
      'ccc_id': cccId,
      'email': email,
      'course': course,
      'profile_link': profileLink,
      'target_hours': targetHours,
      'role': role,
      'isAdmin': isAdmin,
      'current_sy': current_sy,
      'custom_id': customId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completed_hours': completedHours,
      'remaining_hours': remainingHours,
      'total_schedules': totalSchedules,
      'progress': progress,
      'is_done': isDone,
    };
  }
}

// ─── MembersStore ─────────────────────────────────────────────────────────────

class MembersStore extends ChangeNotifier {
  static const String _storageKey = 'members_cache';

  List<Member> _members = [];
  Member? _supervisor;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetched;

  List<Member> get members => _members;
  Member? get supervisor => _supervisor;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetched => _lastFetched;

  List<Member> get students => _members.where((m) => !m.isSupervisor).toList();
  List<Member> get coSupervisors => _members.where((m) => m.isSupervisor).toList();
  List<Member> get studentsByProgress {
    final s = [...students];
    s.sort((a, b) => (b.progress ?? 0).compareTo(a.progress ?? 0));
    return s;
  }

  List<Member> get completedStudents => students.where((m) => m.isDone == true).toList();

  Future<void> loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_storageKey);
      final String? supervisorData = prefs.getString('${_storageKey}_supervisor');
      final String? lastFetchedStr = prefs.getString('${_storageKey}_last_fetched');

      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        _members = jsonList.map((json) => Member.fromJson(json)).toList();
      }
      if (supervisorData != null) {
        _supervisor = Member.fromJson(jsonDecode(supervisorData));
      }
      if (lastFetchedStr != null) {
        _lastFetched = DateTime.parse(lastFetchedStr);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading members from local storage: $e');
    }
  }

  Future<void> saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _members.map((m) => m.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));

      if (_supervisor != null) {
        await prefs.setString('${_storageKey}_supervisor', jsonEncode(_supervisor!.toJson()));
      }

      await prefs.setString('${_storageKey}_last_fetched', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving members to local storage: $e');
    }
  }

  Future<void> fetchMembers(String cccId, int currentIteration) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requestHandler = RequestHandler();
      final response = await requestHandler.handleRequest('user/get-all-users/$cccId/$currentIteration', method: 'GET');

      if (response['success'] == true) {
        if (response['supervisorUser'] != null) {
          _supervisor = Member.fromJson(response['supervisorUser']);
        } else {
          _supervisor = null;
        }

        if (response['users'] != null) {
          final List<dynamic> usersJson = response['users'];
          _members = usersJson.map((json) => Member.fromJson(json)).toList();
        } else {
          _members = [];
        }

        _lastFetched = DateTime.now();
        await saveToLocal();
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to fetch members';
      }
    } catch (e) {
      _error = 'Network error: $e';
      debugPrint('Error fetching members: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editMember(Member updatedMember) async {
    try {
      final index = _members.indexWhere((m) => m.cccId == updatedMember.cccId);
      if (index != -1) {
        _members[index] = updatedMember;
      } else {
        debugPrint('Member not found locally: ${updatedMember.cccId}');
        return;
      }

      notifyListeners();
      await saveToLocal();

      final requestHandler = RequestHandler();
      final response = await requestHandler.handleRequest(
        'user/update-student/${updatedMember.id}',
        method: 'POST',
        body: updatedMember.toJson(),
      );

      if (response['success'] != true) {
        debugPrint('Failed to sync member update: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Error editing member: $e');
    }
  }

  Future<void> clearAll() async {
    _members = [];
    _supervisor = null;
    _lastFetched = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove('${_storageKey}_supervisor');
    await prefs.remove('${_storageKey}_last_fetched');
    notifyListeners();
  }
}
