import 'package:flutter/material.dart';

TextStyle _getBaseStyle(bool isDark, double fontSize) => TextStyle(
  color: isDark ? const Color(0xffd6c9b3) : const Color(0xff513c2e),
  fontSize: fontSize,
  height: 1.8,
);

TextStyle _getStyleForTag(String tag, bool isDark, double fontSize) {
  switch (tag) {
    case 'X':
      return _getBaseStyle(isDark, fontSize).copyWith(
        color: isDark ? const Color(0xffe09d3c) : const Color(0xff10834b),
      );
    case 'O':
      return _getBaseStyle(isDark, fontSize).copyWith(
        color: isDark ? const Color(0xffb5a7a7) : const Color(0xff912929),
      );
    case 'S':
      return _getBaseStyle(isDark, fontSize).copyWith(
        color: isDark ? const Color(0xffa5947b) : const Color(0xffa37635),
      );
    default:
      return _getBaseStyle(isDark, fontSize);
  }
}

List<TextSpan> parseHadithText(String text, bool isDark, double fontSize) {
  if (text.isEmpty) {
    return [const TextSpan(text: '')];
  }

  final List<TextSpan> spans = [];
  final List<String> tagStack = [];
  int lastIndex = 0;

  final RegExp tagPattern = RegExp(r'[XO\[\]]');

  for (final match in tagPattern.allMatches(text)) {
    if (match.start > lastIndex) {
      final String content = text.substring(lastIndex, match.start);
      final String currentContext = tagStack.isEmpty ? '' : tagStack.last;
      spans.add(
        TextSpan(
          text: content,
          style: _getStyleForTag(currentContext, isDark, fontSize),
        ),
      );
    }

    final String currentTagChar = match.group(0)!;
    final String currentContext = tagStack.isEmpty ? '' : tagStack.last;

    switch (currentTagChar) {
      case '[':
        tagStack.add('S');
        spans.add(
          TextSpan(text: '[', style: _getStyleForTag('S', isDark, fontSize)),
        );
        break;
      case ']':
        if (currentContext == 'S') {
          spans.add(
            TextSpan(text: ']', style: _getStyleForTag('S', isDark, fontSize)),
          );
          tagStack.removeLast();
        }
        break;
      case 'O':
        if (currentContext == 'S') {
        } else {
          if (currentContext == 'O') {
            tagStack.removeLast();
          } else {
            tagStack.add('O');
          }
        }
        break;
      case 'X':
        if (currentContext == 'S' || currentContext == 'O') {
        } else {
          if (currentContext == 'X') {
            tagStack.removeLast();
          } else {
            tagStack.add('X');
          }
        }
        break;
    }
    lastIndex = match.end;
  }
  if (lastIndex < text.length) {
    final String remainingContent = text.substring(lastIndex);
    final String currentContext = tagStack.isEmpty ? '' : tagStack.last;
    spans.add(
      TextSpan(
        text: remainingContent,
        style: _getStyleForTag(currentContext, isDark, fontSize),
      ),
    );
  }

  return spans;
}
