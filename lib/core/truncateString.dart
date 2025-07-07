import 'package:characters/characters.dart';

/// Provides extension methods on [String].
extension StringExtensions on String {
  String truncate(int maxChars) {
    final chars = characters;
    if (chars.length <= maxChars) return this;
    return chars.take(maxChars).toString() + '…';
  }
}
