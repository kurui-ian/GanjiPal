/// SMS import audit record.
/// Preserves import status, error diagnosis, and transaction association
/// without exposing sensitive full message bodies in persistent logs.
enum SmsImportStatus {
  success,
  duplicate,
  unrecognizedFormat,
  parseError,
  skipped;

  String get displayName {
    switch (this) {
      case SmsImportStatus.success:
        return 'Imported';
      case SmsImportStatus.duplicate:
        return 'Duplicate';
      case SmsImportStatus.unrecognizedFormat:
        return 'Unrecognized Format';
      case SmsImportStatus.parseError:
        return 'Parse Error';
      case SmsImportStatus.skipped:
        return 'Skipped';
    }
  }
}

class SmsImportRecord {
  final String id;
  final String messageFingerprint;
  final String? mpesaReference;
  final SmsImportStatus status;
  final String? errorMessage;
  final DateTime importedAt;
  final String? transactionId;

  const SmsImportRecord({
    required this.id,
    required this.messageFingerprint,
    this.mpesaReference,
    required this.status,
    this.errorMessage,
    required this.importedAt,
    this.transactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message_fingerprint': messageFingerprint,
      'mpesa_reference': mpesaReference,
      'status': status.name,
      'error_message': errorMessage,
      'imported_at': importedAt.millisecondsSinceEpoch,
      'transaction_id': transactionId,
    };
  }

  factory SmsImportRecord.fromMap(Map<String, dynamic> map) {
    return SmsImportRecord(
      id: map['id'] as String,
      messageFingerprint: map['message_fingerprint'] as String,
      mpesaReference: map['mpesa_reference'] as String?,
      status: SmsImportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SmsImportStatus.parseError,
      ),
      errorMessage: map['error_message'] as String?,
      importedAt:
          DateTime.fromMillisecondsSinceEpoch(map['imported_at'] as int),
      transactionId: map['transaction_id'] as String?,
    );
  }
}
