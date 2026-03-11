import 'dart:convert';

class DailyLog {
  final int? id;
  final DateTime date;
  final String moodType;
  final List<String> physicalSymptoms;
  final String notes;

  DailyLog({
    this.id, 
    required this.date, 
    required this.moodType, 
    required this.physicalSymptoms, 
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10), // Store as YYYY-MM-DD for easy querying
      'mood_type': moodType,
      'physical_symptoms': jsonEncode(physicalSymptoms),
      'notes': notes,
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'],
      date: DateTime.parse(map['date']),
      moodType: map['mood_type'],
      physicalSymptoms: List<String>.from(jsonDecode(map['physical_symptoms'])),
      notes: map['notes'],
    );
  }
}
