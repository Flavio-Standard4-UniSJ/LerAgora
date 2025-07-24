import 'dart:ui';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();

  static Future<void> init({
    String? voice,
    double? rate,
    double? volume,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final voicePref = voice ?? prefs.getString('voice') ?? 'female';
    final speechRate = rate ?? prefs.getDouble('speechRate') ?? 0.45;
    final speechVolume = volume ?? prefs.getDouble('speechVolume') ?? 1.0;

    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(speechRate);
    await _flutterTts.setVolume(speechVolume);

    final voices = await _flutterTts.getVoices;
    final filtered = voices.where(
      (v) =>
          v['locale'] == 'pt-BR' &&
          v['name'].toString().toLowerCase().contains(voicePref),
    );

    if (filtered.isNotEmpty) {
      await _flutterTts.setVoice(filtered.first);
    }
  }

  /// Corrige símbolos jurídicos e formatações que atrapalham a fala
  static String cleanText(String text) {
    return text
        .replaceAll('Art. ', 'Artigo ')
        .replaceAll('Art.', 'Artigo')
        .replaceAll('art. ', 'artigo ')
        .replaceAll('art.', 'artigo')
        .replaceAll('1º', 'primeiro')
        .replaceAll('2º', 'segundo')
        .replaceAll('3º', 'terceiro')
        .replaceAll('4º', 'quarto')
        .replaceAll('5º', 'quinto')
        .replaceAll('6º', 'sexto')
        .replaceAll('7º', 'sétimo')
        .replaceAll('8º', 'oitavo')
        .replaceAll('9º', 'nono')
        .replaceAll('0º', 'zero')
        .replaceAll('§', 'parágrafo ')
        .replaceAll(RegExp(r'Inc\.\s?'), 'inciso ')
        .replaceAllMapped(RegExp(r'(\d+)º'), (match) {
          final number = match.group(1);
          switch (number) {
            case '1':
              return 'primeiro';
            case '2':
              return 'segundo';
            case '3':
              return 'terceiro';
            case '4':
              return 'quarto';
            case '5':
              return 'quinto';
            case '6':
              return 'sexto';
            case '7':
              return 'sétimo';
            case '8':
              return 'oitavo';
            case '9':
              return 'nono';
            case '10':
              return 'décimo';
            default:
              return '$number';
          }
        })
        .replaceAllMapped(
          RegExp(r'Alínea\s+([a-z])'),
          (match) => 'alínea ${match.group(1)}',
        )
        .replaceAll(RegExp(r'[–—-]'), ' ') // travessão, hífen etc.
        .replaceAll('\$', '') // remove cifrão
        .replaceAll(RegExp(r'\s+'), ' ') // limpa espaços duplicados
        .trim();
  }

  static Future<void> speak(String text) async {
    final cleaned = cleanText(text);
    await _flutterTts.speak(cleaned);
  }

  static Future<void> stop() async => await _flutterTts.stop();
  static Future<void> pause() async => await _flutterTts.pause();
  static Future<void> setRate(double rate) async =>
      await _flutterTts.setSpeechRate(rate);
  static Future<void> setVolume(double volume) async =>
      await _flutterTts.setVolume(volume);

  static void setOnComplete(VoidCallback onComplete) {
    _flutterTts.setCompletionHandler(() => onComplete());
  }
}
