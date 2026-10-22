class PayrollException implements Exception {
  final String message;
  final int? statusCode;
  final bool cancelled;
  PayrollException(this.message, {this.statusCode, this.cancelled = false});

  @override
  String toString() => message;
}
