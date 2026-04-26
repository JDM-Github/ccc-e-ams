
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScheduleRecord {
  final int? id;
  final DateTime date;
  final TimeOfDay timeIn;
  TimeOfDay? timeOut;
  final String? proofIn;
  String? proofOut;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  XFile? proofInFile;
  XFile? proofOutFile;

  bool alreadyInDatabase = false;
  bool isInOffice = false; // if false, it means it is work from home
  bool isAcceptedEarly = true; // if not accepted, the clock will automatically set to 8, even if the time in is below 8
  bool isAcceptedWorkFromHome = true; // if false or not accepted, the time in and time out hours is not included

  ScheduleRecord({
    this.id,
    required this.date,
    required this.timeIn,
    this.timeOut,
    this.proofIn,
    this.proofOut,
    this.createdAt,
    this.updatedAt,
    this.alreadyInDatabase=false,
    this.proofInFile,
    this.proofOutFile,
  });

  static bool isEarly(TimeOfDay timeIn) {
    return timeIn.hour < 8;
  }

  factory ScheduleRecord.fromJson(Map<String, dynamic> json, {bool isFetchedFromDatabase = false}) {
    TimeOfDay? parseTime(String? timeString) {
      if (timeString == null) return null;
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    final scheduleRecord = ScheduleRecord(
      id: json['id'],
      date: DateTime.parse(json['date']).toLocal(),
      timeIn: parseTime(json['time_in'])!,
      timeOut: parseTime(json['time_out']),
      proofIn: json['proof_in'],
      proofOut: json['proof_out'],
      alreadyInDatabase: isFetchedFromDatabase,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
    scheduleRecord.isAcceptedEarly = json['isAcceptedEarly'];
    scheduleRecord.isAcceptedWorkFromHome = json['isAcceptedWorkFromHome'];
    scheduleRecord.isInOffice = !json['isWorkFromHome'];
    return scheduleRecord;
  }

  Map<String, dynamic> toJson() {
    String timeToString(TimeOfDay time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'time_in': timeToString(timeIn),
      'time_out': timeOut != null ? timeToString(timeOut!) : null,
      'proof_in': proofIn,
      'proof_out': proofOut,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

