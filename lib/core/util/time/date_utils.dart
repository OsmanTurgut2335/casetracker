class DateUtilsHelper {
  static String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  static String calculateDaysLeft(DateTime date) {
    final currentDate = DateTime.now();
    final daysLeft = daysBetween(currentDate, date);

    if (daysLeft == 0) {
      return 'Bugün';
    } else if (daysLeft < 1) {
      return 'Süresi Geçti';
    } else {
      return '$daysLeft Gün Kaldı';
    }
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
}
