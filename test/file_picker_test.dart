import 'package:flutter_test/flutter_test.dart';

bool isPdfFile(String filePath) {
  return filePath.toLowerCase().endsWith('.pdf');
}

void main() {
  test('Deve aceitar apenas arquivos .pdf', () {
    expect(isPdfFile('documento.pdf'), true);
    expect(isPdfFile('livro.PDF'), true);
    expect(isPdfFile('imagem.jpg'), false);
    expect(isPdfFile('texto.docx'), false);
  });
}
