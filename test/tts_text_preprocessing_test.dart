import 'package:flutter_test/flutter_test.dart';
import 'package:leragora/services/tts_service.dart';

void main() {
  group('TTSService.cleanText', () {
    test('Remove hífens e espaços duplos', () {
      const input = 'livrai-nos   do   mal';
      const expected = 'livrai nos do mal';
      expect(TTSService.cleanText(input), expected);
    });

    test('Remove espaços extras no início e fim', () {
      const input = '  exemplo de texto   ';
      const expected = 'exemplo de texto';
      expect(TTSService.cleanText(input), expected);
    });

    test('Corrige múltiplos hífens', () {
      const input = 'palavra-com-hifen';
      const expected = 'palavra com hifen';
      expect(TTSService.cleanText(input), expected);
    });

    test('Preserva frases simples', () {
      const input = 'Essa é uma frase comum.';
      expect(TTSService.cleanText(input), input);
    });
  });
}
