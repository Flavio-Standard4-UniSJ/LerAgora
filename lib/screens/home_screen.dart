import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:leragora/db/database_helper.dart';
import 'package:leragora/models/book.dart';
import 'package:leragora/utils/session_manager.dart';
import 'reader_screen.dart';
import 'package:leragora/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const HomeScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Book> _bookList = [];
  List<Book> _filteredBooks = [];
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndBooks();
    AdService.loadInterstitialAd();
  }

  Future<void> _loadUserAndBooks() async {
    final currentUser = await SessionManager.getUserSession();
    if (currentUser != null) {
      setState(() => _username = currentUser);
      await loadBooksFromDB();
    }
  }

  Future<void> loadBooksFromDB() async {
    final books = await DatabaseHelper().getBooks(username: _username);
    setState(() {
      _bookList = books;
      _filteredBooks = books;
    });
  }

  Future<void> pickPDF() async {
    final params = OpenFileDialogParams(
      dialogType: OpenFileDialogType.document,
      fileExtensionsFilter: ['pdf'],
    );

    final path = await FlutterFileDialog.pickFile(params: params);

    if (path == null || !path.toLowerCase().endsWith('.pdf')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Somente arquivos PDF são suportados')),
        );
      }
      return;
    }

    final title = path.split('/').last;
    final newBook = Book(title: title, filePath: path, username: _username);
    await DatabaseHelper().insertBook(newBook);
    await loadBooksFromDB();
  }

  void _filterBooks(String query) {
    final filtered = _bookList.where((book) {
      final title = book.title.toLowerCase();
      final input = query.toLowerCase();
      return title.contains(input);
    }).toList();

    setState(() {
      _filteredBooks = filtered;
    });
  }

  void _openBook(Book book) async {
    await AdService.showInterstitialAd(() {
      Navigator.pushNamed(
        context,
        '/reader',
        arguments: {'title': book.title, 'path': book.filePath},
      );
    });
  }

  void _deleteBook(Book book) async {
    await DatabaseHelper().deleteBook(book.id!);
    await loadBooksFromDB(); // Atualiza lista após exclusão
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LerAgora'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar livro',
            onPressed: pickPDF,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await SessionManager.clearSession();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterBooks,
              decoration: InputDecoration(
                hintText: 'Buscar por título',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredBooks.isEmpty
                  ? const Center(child: Text('Nenhum livro encontrado.'))
                  : ListView.builder(
                      itemCount: _filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = _filteredBooks[index];
                        return Card(
                          child: ListTile(
                            title: Text(book.title),
                            subtitle: Text(book.filePath),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.menu_book),
                                  tooltip: 'Abrir livro',
                                  onPressed: () => _openBook(book),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Remover livro',
                                  onPressed: () => _deleteBook(book),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
