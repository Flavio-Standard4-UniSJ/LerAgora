import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:leragora/services/tts_service.dart';
import 'package:leragora/utils/session_manager.dart';

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
  List<String> _textChunks = [];
  int _currentChunkIndex = 0;
  double _volume = 1.0;
  String _fullText = '';

  @override
  void initState() {
    super.initState();
    _prepareReader();
  }

  Future<void> _prepareReader() async {
    // ⏬ Pega preferências salvas
    final prefs = await SessionManager.preferences;
    final voice = prefs.getString('voice') ?? 'female';
    final rate = prefs.getDouble('speechRate') ?? 0.45;

    // 🔧 Inicializa TTS com essas preferências
    await TTSService.init(voice: voice, rate: rate);
    await _extractTextFromPDF();
  }

  Future<void> _extractTextFromPDF() async {
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
            onPressed: () {
              Navigator.pop(context, _volume);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (newVolume != null) {
      await TTSService.setVolume(newVolume);
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

  @override
  void dispose() {
    TTSService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Ler por parágrafo',
            onPressed: _showParagraphSelection,
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Ajustar volume',
            onPressed: _adjustVolume,
          ),
          if (!isSpeaking && !isPaused)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _isTextLoaded ? () => _speakFromIndex(0) : null,
              tooltip: 'Ouvir audiobook',
            ),
          if (isSpeaking)
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: _pause,
              tooltip: 'Pausar áudio',
            ),
          if (isPaused)
            IconButton(
              icon: const Icon(Icons.play_circle),
              onPressed: _resume,
              tooltip: 'Continuar áudio',
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Remover livro',
            onPressed: _deleteBook,
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(widget.bookPath),
        controller: _pdfViewerController,
      ),
    );
  }
}
