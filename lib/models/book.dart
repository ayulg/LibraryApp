class Book {
  final String id;
  final String title;
  final String author;
  final String genre;
  final String isbn;
  final int quantity;
  final String coverImageUrl;
  List<String> reservationQueue;
  int issueCount;
  final String pdfAssetPath;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    this.isbn = '',
    this.quantity = 1,
    this.coverImageUrl = '',
    this.reservationQueue = const [],
    this.issueCount = 0,
    this.pdfAssetPath = '',
  });

  factory Book.fromFirestore(Map<String, dynamic> json, String id) {
    return Book(
      id: id,
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      genre: json['genre'] ?? '',
      isbn: json['isbn'] ?? '',
      quantity: json['quantity'] ?? 1,
      coverImageUrl: json['coverImageUrl'] ?? '',
      reservationQueue: List<String>.from(json['reservationQueue'] ?? []),
      issueCount: json['issueCount'] ?? 0,
      pdfAssetPath: json['pdfAssetPath'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'genre': genre,
      'isbn': isbn,
      'quantity': quantity,
      'coverImageUrl': coverImageUrl,
      'reservationQueue': reservationQueue,
      'issueCount': issueCount,
      'pdfAssetPath': pdfAssetPath,
    };
  }
}
