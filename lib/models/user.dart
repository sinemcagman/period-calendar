class User {
  final int? id;
  final String name;
  final bool isDarkMode;

  User({this.id, required this.name, required this.isDarkMode});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dark_mode': isDarkMode ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      isDarkMode: map['dark_mode'] == 1,
    );
  }
}
