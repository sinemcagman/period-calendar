class Reminder {
  final int? id;
  final String text;
  final DateTime triggerTime;
  final bool isActive;
  final String recurrenceType; // 'none', 'daily', 'weekly', 'monthly'

  Reminder({
    this.id, 
    required this.text, 
    required this.triggerTime,
    this.isActive = true,
    this.recurrenceType = 'none',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'trigger_time': triggerTime.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'recurrence_type': recurrenceType,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      text: map['text'],
      triggerTime: DateTime.parse(map['trigger_time']),
      isActive: map['is_active'] == 1,
      recurrenceType: map['recurrence_type'] ?? 'none',
    );
  }
}
