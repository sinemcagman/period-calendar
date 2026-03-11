class Cycle {
  final int? id;
  final DateTime startDate;
  final DateTime? endDate;

  Cycle({this.id, required this.startDate, this.endDate});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  factory Cycle.fromMap(Map<String, dynamic> map) {
    return Cycle(
      id: map['id'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
    );
  }
  
  int get lengthInDays {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }
}
