import 'package:flutter/material.dart';
import 'package:leragora/models/book.dart';

class BookTile extends StatelessWidget {
  final Book book;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const BookTile({
    Key? key,
    required this.book,
    required this.onOpen,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(book.title),
        subtitle: Text(book.filePath),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.menu_book),
              onPressed: onOpen,
              tooltip: 'Abrir livro',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              tooltip: 'Remover livro',
            ),
          ],
        ),
      ),
    );
  }
}
