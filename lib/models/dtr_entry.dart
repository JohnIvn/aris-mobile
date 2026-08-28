enum DtrDayStatus { present, late, missing, absent }

class DtrEntry {
  final DateTime date;
  final String? timeIn;
  final String? timeOut;
  final DtrDayStatus status;

  const DtrEntry({
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.status,
  });
}
