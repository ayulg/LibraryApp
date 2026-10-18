class IssueRecord {
  final String id;
  final String bookId;
  final String studentId;
  final DateTime issueDate;
  final DateTime dueDate;
  DateTime? returnDate;
  double fineAmount;
  bool isFinePaid;

  IssueRecord({
    required this.id,
    required this.bookId,
    required this.studentId,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    this.fineAmount = 0.0,
    this.isFinePaid = false,
  });

  bool get isOverdue => returnDate == null && DateTime.now().isAfter(dueDate);

  double get accruedFine {
    if (isFinePaid) return 0.0;
    if (returnDate != null) return fineAmount;
    
    // For active books, calculate accrued fine
    if (DateTime.now().isAfter(dueDate)) {
      final daysLate = DateTime.now().difference(dueDate).inDays;
      return daysLate * 5.0; // Hardcoded 5.0 matches finePerDay in service, ideally should come from config but model doesn't have access
    }
    return 0.0;
  }

  factory IssueRecord.fromJson(Map<String, dynamic> json) => IssueRecord(
    id: json['id'],
    bookId: json['bookId'],
    studentId: json['studentId'],
    issueDate: DateTime.parse(json['issueDate']),
    dueDate: DateTime.parse(json['dueDate']),
    returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate']) : null,
    fineAmount: (json['fineAmount'] as num).toDouble(),
    isFinePaid: json['isFinePaid'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'studentId': studentId,
    'issueDate': issueDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'returnDate': returnDate?.toIso8601String(),
    'fineAmount': fineAmount,
    'isFinePaid': isFinePaid,
  };

  factory IssueRecord.fromFirestore(Map<String, dynamic> json, String id) {
    return IssueRecord(
      id: id,
      bookId: json['bookId'] ?? '',
      studentId: json['studentId'] ?? '',
      issueDate: (json['issueDate'] as dynamic).toDate(),
      dueDate: (json['dueDate'] as dynamic).toDate(),
      returnDate: json['returnDate'] != null ? (json['returnDate'] as dynamic).toDate() : null,
      fineAmount: (json['fineAmount'] as num?)?.toDouble() ?? 0.0,
      isFinePaid: json['isFinePaid'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'studentId': studentId,
      'issueDate': issueDate,
      'dueDate': dueDate,
      'returnDate': returnDate,
      'fineAmount': fineAmount,
      'isFinePaid': isFinePaid,
    };
  }
}

