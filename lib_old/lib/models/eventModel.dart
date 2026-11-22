class Event {
  final String title;
  final DateTime date;
  final String idOs;

  Event({required this.title, required this.date, required this.idOs});

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['status'],
      date: DateTime.parse(json['dataInicial']),
      idOs: json['idOs'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': title,
      'dataInicial': date.toIso8601String(),
      'idOs': idOs,
    };
  }
}
