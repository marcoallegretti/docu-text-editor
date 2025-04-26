import 'package:flutter_quill/flutter_quill.dart';

class WordCounter {
  // Count words in a QuillController
  static int countWords(QuillController controller) {
    final text = controller.document.toPlainText();
    return countWordsInText(text);
  }

  // Count words in a string
  static int countWordsInText(String text) {
    if (text.isEmpty) return 0;
    
    // Remove trailing whitespace
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    
    // Split by whitespace and count non-empty words
    final words = trimmed.split(RegExp(r'\s+'));
    return words.where((word) => word.isNotEmpty).length;
  }

  // Estimate page count (roughly 250 words per page)
  static int estimatePageCount(int wordCount) {
    const wordsPerPage = 250;
    final pages = (wordCount / wordsPerPage).ceil();
    return pages > 0 ? pages : 1;
  }

  // Format the word and page count for display
  static String formatWordCount(int wordCount, int pageCount) {
    final wordText = wordCount == 1 ? 'word' : 'words';
    final pageText = pageCount == 1 ? 'page' : 'pages';
    return '$wordCount $wordText | $pageCount $pageText';
  }

  // Calculate character count (with and without spaces)
  static Map<String, int> countCharacters(QuillController controller) {
    final text = controller.document.toPlainText();
    final withSpaces = text.length;
    final withoutSpaces = text.replaceAll(RegExp(r'\s+'), '').length;
    
    return {
      'withSpaces': withSpaces,
      'withoutSpaces': withoutSpaces,
    };
  }
}