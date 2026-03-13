import 'dart:convert';

class DailyLog {
  final int? id;
  final DateTime date;
  final List<String> moodTypes;
  final List<String> physicalSymptoms;
  final String notes;

  DailyLog({
    this.id, 
    required this.date, 
    required this.moodTypes, 
    required this.physicalSymptoms, 
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'mood_type': jsonEncode(moodTypes),
      'physical_symptoms': jsonEncode(physicalSymptoms),
      'notes': notes,
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    // Handle both old format (plain string) and new format (JSON array)
    List<String> parseMoods(dynamic raw) {
      if (raw == null || raw == '') return [];
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return List<String>.from(decoded);
        return [raw.toString()];
      } catch (_) {
        // Old format: single mood string
        return raw.toString().isEmpty ? [] : [raw.toString()];
      }
    }

    return DailyLog(
      id: map['id'],
      date: DateTime.parse(map['date']),
      moodTypes: parseMoods(map['mood_type']),
      physicalSymptoms: List<String>.from(jsonDecode(map['physical_symptoms'])),
      notes: map['notes'] ?? '',
    );
  }
}
