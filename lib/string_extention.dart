extension Capitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
