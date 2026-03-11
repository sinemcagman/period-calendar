class WaterIntake {
  final int? id;
  final DateTime date;
  final int amount; // in ml, or just count of glasses (e.g. 1 glass = 250ml)

  WaterIntake({this.id, required this.date, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'amount': amount,
    };
  }

  factory WaterIntake.fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      id: map['id'],
      date: DateTime.parse(map['date']),
      amount: map['amount'],
    );
  }
}
