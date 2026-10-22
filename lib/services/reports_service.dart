
class ReportsDetails {
  final String id;
  final String role; // 'staff' | 'professor'
  final String name;
  final String email;
  final String provider;
  final String employeeId;
  final String username;
  final String? avatarUrl;
  final String? position;
  final String? department;

  /// Full backend payload (middlename, birthday, age, gender, timestamps...).
  final Map<String, dynamic> raw;

  const ReportsDetails({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    required this.provider,
    required this.employeeId,
    required this.username,
    this.avatarUrl,
    this.position,
    this.department,
    required this.raw,
  });

  factory ReportsDetails.fromJson(Map<String, dynamic> j) => ReportsDetails(
    id: j['id'] as String,
    role: j['role'] as String,
    name: '${j['firstname'] ?? ''} ${j['lastname'] ?? ''}'.trim(),
    email: j['email'] as String,
    provider: (j['provider'] ?? 'google') as String,
    employeeId: j['employee_id'] as String,
    username: j['username'] as String,
    avatarUrl: j['avatar_url'] as String?,
    position: j['position'] as String?,
    department: j['department'] as String?,
    raw: j,
  );
}
