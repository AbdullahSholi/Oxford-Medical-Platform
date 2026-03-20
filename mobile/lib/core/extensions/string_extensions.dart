extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get capitalizeWords {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  bool get isValidPhone {
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(this);
  }

  String get initials {
    final words = trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}
