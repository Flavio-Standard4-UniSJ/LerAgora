import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:leragora/services/tts_service.dart';
import 'package:leragora/utils/session_manager.dart';
import 'package:crypto/crypto.dart';

class ReaderScreen extends StatefulWidget {
  final String bookTitle;
  final String bookPath;

  const ReaderScreen({
    Key? key,
    required this.bookTitle,
    required this.bookPath,
  }) : super(key: key);

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();

  bool isSpeaking = false;
  bool isPaused = false;
  bool _isTextLoaded = false;
  bool _isDark = false;

  List<String> _textChunks = [];
  int _currentChunkIndex = 0;
  double _volume = 1.0;
  int _lastPage = 0;
  String _fullText = '';

  String get _bookHash {
    final bytes = utf8.encode(widget.bookPath);
    return sha1.convert(bytes).toString();
  }

  String get _progressKey => 'progress_$_bookHash';
  final String _themeKey = 'reader_theme';

  @override
  void initState() {
    super.initState();
    _prepareReader();
  }

  Future<void> _prepareReader() async {
    final prefs = await SessionManager.preferences;

    _lastPage = prefs.getInt(_progressKey) ?? 0;
    _isDark = prefs.getBool(_themeKey) ?? false;
    _volume = prefs.getDouble('speechVolume') ?? 1.0;
    final voice = prefs.getString('voice') ?? 'female';
    final rate = prefs.getDouble('speechRate') ?? 0.45;

    await TTSService.init(voice: voice, rate: rate, volume: _volume);

    await _extractTextFromPDF();

    if (_lastPage > 0) {
      _pdfViewerController.jumpToPage(_lastPage);
    }
  }

  Future<void> _extractTextFromPDF() async {
    try {
      final fileBytes = File(widget.bookPath).readAsBytesSync();
      final document = PdfDocument(inputBytes: fileBytes);
      String fullText = '';

      for (int i = 0; i < document.pages.count; i++) {
        final pageText = PdfTextExtractor(
          document,
        ).extractText(startPageIndex: i, endPageIndex: i);
        fullText += '\n$pageText';
      }

      document.dispose();
      _fullText = fullText.trim();
      _textChunks = _splitTextIntoChunks(_fullText, 2000);
      setState(() => _isTextLoaded = _textChunks.isNotEmpty);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao abrir PDF: $e')));
        Navigator.pop(context);
      }
    }
  }

  List<String> _splitTextIntoChunks(String text, int chunkSize) {
    final lines = text.split(RegExp(r'\n|\r|\r\n'));
    return lines.where((p) => p.trim().isNotEmpty).toList();
  }

  Future<void> _speakFromIndex(int index) async {
    if (_textChunks.isEmpty || index >= _textChunks.length) return;

    _currentChunkIndex = index;
    isPaused = false;
    setState(() => isSpeaking = true);

    TTSService.setOnComplete(() async {
      if (isPaused) return;
      _currentChunkIndex++;
      if (_currentChunkIndex < _textChunks.length) {
        await TTSService.speak(_textChunks[_currentChunkIndex]);
      } else {
        setState(() => isSpeaking = false);
      }
    });

    await TTSService.speak(_textChunks[_currentChunkIndex]);
  }

  Future<void> _pause() async {
    await TTSService.pause();
    setState(() {
      isPaused = true;
      isSpeaking = false;
    });
  }

  Future<void> _resume() async {
    isPaused = false;
    setState(() => isSpeaking = true);
    await TTSService.speak(_textChunks[_currentChunkIndex]);
  }

  Future<void> _stop() async {
    await TTSService.stop();
    setState(() {
      isSpeaking = false;
      isPaused = false;
    });
  }

  Future<void> _saveProgress({bool manual = false}) async {
    final prefs = await SessionManager.preferences;
    final page = _pdfViewerController.pageNumber;
    await prefs.setInt(_progressKey, page);
    if (manual && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Progresso salvo!')));
    }
  }

  void _deleteBook() async {
    final file = File(widget.bookPath);
    if (await file.exists()) {
      await file.delete();
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _adjustVolume() async {
    final newVolume = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajustar Volume'),
        content: Slider(
          value: _volume,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: (value) => setState(() => _volume = value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _volume),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (newVolume != null) {
      await TTSService.setVolume(newVolume);
      final prefs = await SessionManager.preferences;
      await prefs.setDouble('speechVolume', newVolume);
    }
  }

  void _showParagraphSelection() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: _textChunks.length,
        itemBuilder: (context, index) {
          final chunk = _textChunks[index];
          return ListTile(
            title: Text(chunk, maxLines: 3, overflow: TextOverflow.ellipsis),
            onTap: () {
              Navigator.pop(context);
              _speakFromIndex(index);
            },
          );
        },
      ),
    );
  }

  void _toggleTheme() async {
    final prefs = await SessionManager.preferences;
    setState(() => _isDark = !_isDark);
    await prefs.setBool(_themeKey, _isDark);
  }

  @override
  void dispose() {
    TTSService.stop();
    _saveProgress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDark ? ThemeData.dark() : ThemeData.light(),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            return Scaffold(
              appBar: AppBar(
                title: Text(widget.bookTitle),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      semanticLabel: 'Configurações',
                    ),
                    tooltip: 'Configurações',
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.menu_book,
                      semanticLabel: 'Ler por parágrafo',
                    ),
                    tooltip: 'Ler por parágrafo',
                    onPressed: _showParagraphSelection,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up,
                      semanticLabel: 'Ajustar volume',
                    ),
                    tooltip: 'Ajustar volume',
                    onPressed: _adjustVolume,
                  ),
                  IconButton(
                    icon: Icon(_isDark ? Icons.light_mode : Icons.dark_mode),
                    tooltip: 'Alternar tema',
                    onPressed: _toggleTheme,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.save,
                      semanticLabel: 'Salvar leitura',
                    ),
                    tooltip: 'Salvar progresso',
                    onPressed: () => _saveProgress(manual: true),
                  ),
                  if (!isSpeaking && !isPaused)
                    IconButton(
                      icon: const Icon(
                        Icons.play_arrow,
                        semanticLabel: 'Iniciar leitura',
                      ),
                      tooltip: 'Ouvir audiobook',
                      onPressed: _isTextLoaded
                          ? () => _speakFromIndex(0)
                          : null,
                    ),
                  if (isSpeaking)
                    IconButton(
                      icon: const Icon(
                        Icons.pause,
                        semanticLabel: 'Pausar leitura',
                      ),
                      tooltip: 'Pausar áudio',
                      onPressed: _pause,
                    ),
                  if (isPaused)
                    IconButton(
                      icon: const Icon(
                        Icons.play_circle,
                        semanticLabel: 'Retomar leitura',
                      ),
                      tooltip: 'Continuar áudio',
                      onPressed: _resume,
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      semanticLabel: 'Remover livro',
                    ),
                    tooltip: 'Remover livro',
                    onPressed: _deleteBook,
                  ),
                ],
              ),
              body: isWide
                  ? Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SfPdfViewer.file(
                            File(widget.bookPath),
                            controller: _pdfViewerController,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _isTextLoaded
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Trecho atual:',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            _textChunks[_currentChunkIndex],
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                          ),
                        ),
                      ],
                    )
                  : SfPdfViewer.file(
                      File(widget.bookPath),
                      controller: _pdfViewerController,
                    ),
            );
          },
        ),
      ),
    );
  }
}
