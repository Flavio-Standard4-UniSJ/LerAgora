// 📁 lib/models/book.dart
class Book {
  final int? id;
  final String title;
  final String filePath;
  final String username; // <- NOVO CAMPO

  Book({
    this.id,
    required this.title,
    required this.filePath,
    required this.username,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'username': username,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      filePath: map['file_path'],
      username: map['username'],
    );
  }
}
