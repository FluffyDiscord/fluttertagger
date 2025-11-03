/// Represents a tag with information about the
/// [text]'s position ([startIndex], [endIndex]) in the TextField.
class TaggedText {
  final int startIndex;
  final int endIndex;
  final String text;
  final dynamic extra;

  const TaggedText({
    required this.startIndex,
    required this.endIndex,
    required this.text,
    this.extra = null,
  });

  @override
  bool operator ==(Object other) {
    return other is TaggedText &&
        other.endIndex == endIndex &&
        other.startIndex == startIndex &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hashAll([startIndex, endIndex, text]);

  @override
  String toString() {
    return "TaggedText(startIndex: $startIndex, endIndex: $endIndex, text: $text)";
  }
}
