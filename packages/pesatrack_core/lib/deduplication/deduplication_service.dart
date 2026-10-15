import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../parser/mpesa_transaction_types.dart';

/// Deduplication service providing deterministic hashing and duplicate detection.
class DeduplicationService {
  /// Generates a deterministic SHA-256 fingerprint for a transaction.
  /// Uses official M-Pesa reference if present.
  /// Falls back to normalized composite fields if reference is unavailable.
  static String generateFingerprint({
    String? mpesaReference,
    required int amountCents,
    required DateTime timestamp,
    String? counterparty,
    TransactionType? type,
    String? accountReference,
  }) {
    if (mpesaReference != null && mpesaReference.trim().isNotEmpty) {
      final normalizedRef = mpesaReference.trim().toUpperCase();
      final bytes = utf8.encode('REF:$normalizedRef');
      return sha256.convert(bytes).toString();
    }

    // Fallback composite deterministic fingerprint
    final normCounterparty = (counterparty ?? '').trim().toLowerCase();
    final normAccount = (accountReference ?? '').trim().toLowerCase();
    final normType = type?.name ?? 'unknown';
    // Normalize timestamp to second resolution
    final normTime = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      timestamp.minute,
      timestamp.second,
    ).toIso8601String();

    final composite =
        'COMP:$normType:$amountCents:$normTime:$normCounterparty:$normAccount';
    final bytes = utf8.encode(composite);
    return sha256.convert(bytes).toString();
  }

  /// Generates a non-reversible SHA-256 hash for raw SMS body auditing.
  static String hashRawSms(String rawMessage) {
    final clean = rawMessage.trim().replaceAll(RegExp(r'\s+'), ' ');
    final bytes = utf8.encode(clean);
    return sha256.convert(bytes).toString();
  }
}
