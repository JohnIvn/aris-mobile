/// A single raw punch record from the `attendance_transactions` table,
/// returned by `GET /biometrics/transactions`.
class AttendanceTransaction {
  final String id;
  final String empCode;
  final String? firstName;
  final String? lastName;
  final String? department;
  final String? position;
  final DateTime punchTime;
  final String punchState;
  final String? punchStateDisplay;
  final int verifyType;
  final String? verifyTypeDisplay;
  final String? workCode;
  final String? areaAlias;
  final String terminalSn;
  final String? terminalAlias;
  final DateTime uploadTime;
  final DateTime createdAt;

  const AttendanceTransaction({
    required this.id,
    required this.empCode,
    this.firstName,
    this.lastName,
    this.department,
    this.position,
    required this.punchTime,
    required this.punchState,
    this.punchStateDisplay,
    required this.verifyType,
    this.verifyTypeDisplay,
    this.workCode,
    this.areaAlias,
    required this.terminalSn,
    this.terminalAlias,
    required this.uploadTime,
    required this.createdAt,
  });

  factory AttendanceTransaction.fromJson(Map<String, dynamic> j) {
    DateTime parseWallClock(Object? v) {
      if (v == null) return DateTime.now();
      final s = v.toString().trim();
      final dt = DateTime.tryParse(s);
      if (dt == null) return DateTime.now();
      // The biometric terminal records Manila wall-clock time. If the backend
      // serializes it with a "Z" suffix, do NOT apply .toLocal() as that adds
      // an extra 8 hours. Extract the wall-clock components directly as-is.
      return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    }

    String parseString(Object? v, [String fallback = '']) =>
        v?.toString() ?? fallback;
    int parseInt(Object? v, [int fallback = 0]) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? fallback;

    return AttendanceTransaction(
      id: parseString(j['id']),
      empCode: parseString(j['emp_code']),
      firstName: j['first_name']?.toString(),
      lastName: j['last_name']?.toString(),
      department: j['department']?.toString(),
      position: j['position']?.toString(),
      punchTime: parseWallClock(j['punch_time']),
      punchState: parseString(j['punch_state']),
      punchStateDisplay: j['punch_state_display']?.toString(),
      verifyType: parseInt(j['verify_type']),
      verifyTypeDisplay: j['verify_type_display']?.toString(),
      workCode: j['work_code']?.toString(),
      areaAlias: j['area_alias']?.toString(),
      terminalSn: parseString(j['terminal_sn']),
      terminalAlias: j['terminal_alias']?.toString(),
      uploadTime: parseWallClock(j['upload_time']),
      createdAt: parseWallClock(j['created_at']),
    );
  }
}
