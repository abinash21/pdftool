class HistoryItem {
  final String action;
  final String outputPath;
  final DateTime dateTime;
  final String details;

  HistoryItem({
    required this.action,
    required this.outputPath,
    required this.dateTime,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
    'action': action,
    'outputPath': outputPath,
    'dateTime': dateTime.toIso8601String(),
    'details': details,
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      action: json['action'],
      outputPath: json['outputPath'],
      dateTime: DateTime.parse(json['dateTime']),
      details: json['details'],
    );
  }
}
