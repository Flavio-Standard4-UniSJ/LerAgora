import 'package:flutter_test/flutter_test.dart';

import 'signup_screen_test.dart' as signup_test;
import 'file_picker_test.dart' as picker_test;
import 'tts_text_preprocessing_test.dart' as tts_test;

void main() {
  group('Rodando todos os testes do app', () {
    signup_test.main();
    picker_test.main();
    tts_test.main();
  });
}
