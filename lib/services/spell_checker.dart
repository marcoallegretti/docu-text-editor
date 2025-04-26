class SpellChecker {
  // A basic list of commonly misspelled words and their corrections
  // In a real app, this would be much more extensive or use a dictionary API
  static final Map<String, String> _commonErrors = {
    'teh': 'the',
    'adn': 'and',
    'taht': 'that',
    'waht': 'what',
    'wiht': 'with',
    'becuase': 'because',
    'recieve': 'receive',
    'beleive': 'believe',
    'occurence': 'occurrence',
    'definately': 'definitely',
    'seperate': 'separate',
    'accomodate': 'accommodate',
    'embarass': 'embarrass',
    'harrass': 'harass',
    'independant': 'independent',
    'decembre': 'december',
    'freind': 'friend',
    'wierd': 'weird',
    'wich': 'which',
    'untill': 'until',
    'goverment': 'government',
    'knowlege': 'knowledge',
    'probaly': 'probably',
    'suprise': 'surprise',
    'tommorrow': 'tomorrow',
    'neccessary': 'necessary',
  };

  // Check if a word is misspelled and return the correction if available
  static String? checkWord(String word) {
    final lowerWord = word.toLowerCase();
    return _commonErrors[lowerWord];
  }

  // Check a text and return a list of misspelled words with their positions
  static List<SpellError> checkText(String text) {
    final wordPattern = RegExp(r'\b[a-zA-Z]+\b');
    final matches = wordPattern.allMatches(text);
    final errors = <SpellError>[];

    for (final match in matches) {
      final word = text.substring(match.start, match.end);
      final correction = checkWord(word);
      if (correction != null) {
        errors.add(SpellError(
          word: word,
          startPosition: match.start,
          endPosition: match.end,
          suggestion: correction,
        ));
      }
    }

    return errors;
  }
}

class SpellError {
  final String word;
  final int startPosition;
  final int endPosition;
  final String suggestion;

  SpellError({
    required this.word,
    required this.startPosition,
    required this.endPosition,
    required this.suggestion,
  });
}