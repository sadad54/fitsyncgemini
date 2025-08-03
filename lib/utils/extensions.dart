extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  String capitalizeWords() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
}

extension DateTimeExtensions on DateTime {
  String toTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} week${difference.inDays ~/ 7 == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

extension ListExtensions<T> on List<T> {
  List<T> uniqueBy<R>(R Function(T) selector) {
    final seen = <R>{};
    return where((element) => seen.add(selector(element))).toList();
  }
}
