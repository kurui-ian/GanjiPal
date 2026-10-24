import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../repositories/sms_repository.dart';
import '../repositories/transaction_repository.dart';

class ImportBatchResult {
  final int totalScanned;
  final int successfullyImported;
  final int duplicatesSkipped;
  final int unrecognizedSkipped;
  final List<String> errors;

  const ImportBatchResult({
    required this.totalScanned,
    required this.successfullyImported,
    required this.duplicatesSkipped,
    required this.unrecognizedSkipped,
    required this.errors,
  });
}

/// Service managing SMS retrieval, parsing handoff, and import batching.
class SmsImportService {
  static const MethodChannel _channel = MethodChannel(
    'com.pesatrack.app/sms_channel',
  );

  final TransactionRepository _txRepo;
  final SmsRepository _smsRepo;
  final MpesaParser _parser;
  final TransactionClassifier _classifier;

  final StreamController<TransactionModel> _incomingTransactionController =
      StreamController<TransactionModel>.broadcast();

  TransactionClassifier get classifier => _classifier;
  MpesaParser get parser => _parser;
  SmsRepository get smsRepo => _smsRepo;
  TransactionRepository get txRepo => _txRepo;

  Stream<TransactionModel> get onNewTransaction =>
      _incomingTransactionController.stream;

  SmsImportService({
    TransactionRepository? txRepo,
    SmsRepository? smsRepo,
    MpesaParser? parser,
    TransactionClassifier? classifier,
  }) : _txRepo = txRepo ?? TransactionRepository(),
       _smsRepo = smsRepo ?? SmsRepository(),
       _parser = parser ?? MpesaParser(),
       _classifier = classifier ?? TransactionClassifier() {
    _initChannelListener();
  }

  void _initChannelListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final body = call.arguments as String?;
        if (body != null && body.isNotEmpty) {
          final tx = await processSingleMessage(
            body,
            source: TransactionSource.autoSms,
          );
          if (tx != null) {
            _incomingTransactionController.add(tx);
          }
        }
      }
    });
  }

  /// Processes queued background SMS messages upon app startup.
  Future<int> processPendingBackgroundMessages() async {
    try {
      final List<dynamic>? list = await _channel.invokeMethod('getPendingSms');
      if (list == null || list.isEmpty) return 0;

      int importedCount = 0;
      for (final raw in list) {
        final body = raw.toString();
        final tx = await processSingleMessage(
          body,
          source: TransactionSource.autoSms,
        );
        if (tx != null) {
          importedCount++;
          _incomingTransactionController.add(tx);
        }
      }
      return importedCount;
    } catch (_) {
      return 0;
    }
  }

  /// Imports historical M-Pesa SMS messages from the device inbox.
  Future<ImportBatchResult> importFromDeviceInbox({
    int limit = 200,
    DateTime? sinceDate,
  }) async {
    int total = 0;
    int imported = 0;
    int duplicates = 0;
    int unrecognized = 0;
    final List<String> errors = [];

    try {
      final sinceTs = sinceDate?.millisecondsSinceEpoch ?? 0;
      final List<dynamic>? rawMessages = await _channel.invokeMethod(
        'queryInboxSms',
        {'limit': limit, 'sinceTimestamp': sinceTs},
      );

      if (rawMessages == null || rawMessages.isEmpty) {
        return const ImportBatchResult(
          totalScanned: 0,
          successfullyImported: 0,
          duplicatesSkipped: 0,
          unrecognizedSkipped: 0,
          errors: [],
        );
      }

      total = rawMessages.length;

      for (final item in rawMessages) {
        if (item is Map) {
          final body = item['body'] as String? ?? '';
          if (body.isEmpty) continue;

          final tx = await processSingleMessage(
            body,
            source: TransactionSource.importedSms,
            smsReceivedTimestamp: item['date'] != null
                ? DateTime.fromMillisecondsSinceEpoch(item['date'] as int)
                : null,
          );

          if (tx != null) {
            imported++;
          } else {
            // Check why it wasn't imported
            final parsed = _parser.parse(body);
            if (!parsed.isMpesa || parsed.amountCents == 0) {
              unrecognized++;
            } else {
              duplicates++;
            }
          }
        }
      }
    } catch (e) {
      errors.add(e.toString());
    }

    return ImportBatchResult(
      totalScanned: total,
      successfullyImported: imported,
      duplicatesSkipped: duplicates,
      unrecognizedSkipped: unrecognized,
      errors: errors,
    );
  }

  /// Parses and optionally previews a single raw message without committing.
  ParsedSmsResult previewMessage(String rawMessage) {
    return _parser.parse(rawMessage);
  }

  /// Parses multiple pasted M-Pesa messages for preview.
  List<ParsedSmsResult> previewPastedBatch(String text) {
    final List<String> segments = splitMultipleMessages(text);
    return segments.map((s) => _parser.parse(s)).toList();
  }

  /// Splits text containing one or multiple pasted SMS messages.
  List<String> splitMultipleMessages(String text) {
    // M-Pesa messages typically start with reference e.g. QA12BC34DE Confirmed.
    final matches = RegExp(
      r'([A-Z0-9]{8,12}\s+Confirmed[\s\S]+?)(?=[A-Z0-9]{8,12}\s+Confirmed|$)',
      caseSensitive: false,
    ).allMatches(text);

    if (matches.isNotEmpty) {
      return matches
          .map((m) => m.group(1)!.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Fallback: split by double newlines
    return text
        .split(RegExp(r'\n\s*\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Processes a single message: parses, deduplicates, and commits if valid.
  Future<TransactionModel?> processSingleMessage(
    String rawMessage, {
    required TransactionSource source,
    DateTime? smsReceivedTimestamp,
  }) async {
    final parsed = _parser.parse(rawMessage);
    final smsFp = DeduplicationService.hashRawSms(rawMessage);

    if (!parsed.isMpesa || parsed.amountCents <= 0) {
      await _smsRepo.recordImport(
        SmsImportRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          messageFingerprint: smsFp,
          mpesaReference: parsed.mpesaReference,
          status: SmsImportStatus.unrecognizedFormat,
          errorMessage: parsed.failureReason,
          importedAt: DateTime.now(),
        ),
      );
      return null;
    }

    final txTimestamp = parsed.timestamp ?? DateTime.now();
    final txFingerprint = DeduplicationService.generateFingerprint(
      mpesaReference: parsed.mpesaReference,
      amountCents: parsed.amountCents,
      timestamp: txTimestamp,
      counterparty: parsed.counterpartyName,
      type: parsed.transactionType,
      accountReference: parsed.accountReference,
    );

    // Check duplicate
    final existing = await _txRepo.getTransactionByFingerprint(txFingerprint);
    if (existing != null) {
      await _smsRepo.recordImport(
        SmsImportRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          messageFingerprint: smsFp,
          mpesaReference: parsed.mpesaReference,
          status: SmsImportStatus.duplicate,
          importedAt: DateTime.now(),
          transactionId: existing.id,
        ),
      );
      return null;
    }

    // Determine category
    final categoryId = _classifier.suggestCategory(parsed);
    final categoryName = _classifier.getCategoryName(categoryId);
    final txId = DateTime.now().microsecondsSinceEpoch.toString();

    final tx = TransactionModel(
      id: txId,
      mpesaReference: parsed.mpesaReference,
      transactionType: parsed.transactionType,
      classification: parsed.classification,
      amountCents: parsed.amountCents,
      feeCents: parsed.feeCents,
      currency: 'KES',
      timestamp: txTimestamp,
      smsReceivedTimestamp: smsReceivedTimestamp ?? DateTime.now(),
      counterpartyName: parsed.counterpartyName,
      counterpartyPhone: parsed.counterpartyPhone,
      accountReference: parsed.accountReference,
      description: parsed.description,
      categoryId: categoryId,
      categoryName: categoryName,
      source: source,
      fingerprint: txFingerprint,
      reviewStatus: parsed.reviewStatus,
      reversalReference: parsed.reversalReference,
      balanceAfterCents: parsed.balanceAfterCents,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final inserted = await _txRepo.insertTransaction(tx);
    if (inserted) {
      await _smsRepo.recordImport(
        SmsImportRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          messageFingerprint: smsFp,
          mpesaReference: parsed.mpesaReference,
          status: SmsImportStatus.success,
          importedAt: DateTime.now(),
          transactionId: tx.id,
        ),
      );
      return tx;
    } else {
      await _smsRepo.recordImport(
        SmsImportRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          messageFingerprint: smsFp,
          mpesaReference: parsed.mpesaReference,
          status: SmsImportStatus.duplicate,
          importedAt: DateTime.now(),
        ),
      );
      return null;
    }
  }

  /// Opens application settings on Android device.
  Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (_) {}
  }

  void dispose() {
    _incomingTransactionController.close();
  }
}
