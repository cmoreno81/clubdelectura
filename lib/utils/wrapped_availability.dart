class WrappedAvailability {
  WrappedAvailability([DateTime? date]) : date = date ?? DateTime.now();

  final DateTime date;

  bool get isAvailable =>
      date.month == DateTime.november ||
      date.month == DateTime.december ||
      date.month == DateTime.january;

  int get wrappedYear =>
      date.month == DateTime.january ? date.year - 1 : date.year;

  int get daysUntilNovember {
    final today = DateTime(date.year, date.month, date.day);
    final november = DateTime(
      date.month >= DateTime.november ? date.year + 1 : date.year,
      DateTime.november,
    );
    return november.difference(today).inDays;
  }
}
