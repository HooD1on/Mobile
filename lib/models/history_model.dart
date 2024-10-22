// lib/models/history_model.dart
import 'package:flutter/foundation.dart';

class History {
  final int? id;
  final String imagePath;
  final String result;
  final DateTime dateTime;

  History({
    this.id,
    required this.imagePath,
    required this.result,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'result': result,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory History.fromMap(Map<String, dynamic> map) {
    return History(
      id: map['id'],
      imagePath: map['imagePath'],
      result: map['result'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}