class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final String userId;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.userId,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> json, String id) {
    return NotificationModel(
      id: id,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      date: (json['date'] as dynamic).toDate(),
      userId: json['userId'] ?? '',
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'date': date,
      'userId': userId,
      'isRead': isRead,
    };
  }
}
