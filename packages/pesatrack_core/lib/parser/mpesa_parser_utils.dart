import 'package:intl/intl.dart';

/// Utility methods for parsing amounts, timestamps, phone numbers, and balances
/// from M-Pesa SMS text.
class MpesaParserUtils {
  /// Parses M-Pesa amount strings to integer cents.
  /// E.g. 'Ksh1,500.00' -> 150000, 'Ksh 250.50' -> 25050.
  static int? parseAmountToCents(String text) {
    try {
      // Extract numeric part with optional commas and decimal point
      final match = RegExp(
        r'(?:Ksh|KES|KSh|\$)\.?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ).firstMatch(text);

      if (match == null) {
        // Fallback: look for plain numbers if format is already stripped
        final fallback = RegExp(r'([\d,]+\.\d{2})').firstMatch(text);
        if (fallback == null) return null;
        final clean = fallback.group(1)!.replaceAll(',', '');
        final val = double.parse(clean);
        return (val * 100).round();
      }

      final rawNum = match.group(1)!.replaceAll(',', '');
      final amountDouble = double.parse(rawNum);
      if (amountDouble < 0) return null;
      return (amountDouble * 100).round();
    } catch (_) {
      return null;
    }
  }

  /// Parses date and time from standard M-Pesa SMS formats.
  /// Supports:
  /// - 'on 15/10/26 at 8:30 PM'
  /// - 'on 15/10/2026 at 8:30 PM'
  /// - 'on 15/10/26 8:30 PM'
  /// - 'on 1/2/26 at 11:05 AM'
  static DateTime? parseDateTime(String text) {
    try {
      // Pattern 1: 'on DD/MM/YY(YY) at H:MM AM/PM'
      final match = RegExp(
        r'on\s+(\d{1,2}/\d{1,2}/\d{2,4})\s+(?:at\s+)?(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM))',
        caseSensitive: false,
      ).firstMatch(text);

      if (match != null) {
        final dateStr = match.group(1)!;
        final timeStr = match.group(2)!.trim();
        return _combineDateAndTime(dateStr, timeStr);
      }

      // Pattern 2: 'at H:MM AM/PM on DD/MM/YY(YY)'
      final matchAlt = RegExp(
        r'at\s+(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM))\s+on\s+(\d{1,2}/\d{1,2}/\d{2,4})',
        caseSensitive: false,
      ).firstMatch(text);

      if (matchAlt != null) {
        final timeStr = matchAlt.group(1)!.trim();
        final dateStr = matchAlt.group(2)!;
        return _combineDateAndTime(dateStr, timeStr);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _combineDateAndTime(String dateStr, String timeStr) {
    try {
      final dateParts = dateStr.split('/');
      if (dateParts.length != 3) return null;

      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);

      if (year < 100) {
        // Assume 2000s for 2-digit years
        year += 2000;
      }

      // Parse time using intl
      final cleanTime = timeStr.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
      DateFormat timeFormat;
      if (cleanTime.contains(':') && cleanTime.split(':').length == 3) {
        timeFormat = DateFormat('h:mm:ss a');
      } else {
        timeFormat = DateFormat('h:mm a');
      }

      final parsedTime = timeFormat.parse(cleanTime);
      return DateTime(
        year,
        month,
        day,
        parsedTime.hour,
        parsedTime.minute,
        parsedTime.second,
      );
    } catch (_) {
      return null;
    }
  }

  /// Extracts transaction cost/fee in cents if present.
  /// E.g. 'Transaction cost, Ksh15.00.' -> 1500
  static int extractFeeCents(String text) {
    try {
      final match = RegExp(
        r'Transaction\s+cost,?\s*(?:Ksh|KES)?\.?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ).firstMatch(text);

      if (match != null) {
        final clean = match.group(1)!.replaceAll(',', '');
        final feeDouble = double.parse(clean);
        return (feeDouble * 100).round();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Extracts post-transaction M-Pesa balance in cents if present.
  /// E.g. 'New M-PESA balance is Ksh12,450.00.' -> 1245000
  static int? extractBalanceAfterCents(String text) {
    try {
      final match = RegExp(
        r'New\s+M-PESA\s+balance\s+is\s+(?:Ksh|KES)?\.?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ).firstMatch(text);

      if (match != null) {
        final clean = match.group(1)!.replaceAll(',', '');
        final balDouble = double.parse(clean);
        return (balDouble * 100).round();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Normalizes Kenyan mobile phone numbers.
  /// Converts +254712345678, 254712345678 -> 0712345678.
  static String? normalizePhoneNumber(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return null;
    var clean = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.startsWith('+254')) {
      clean = '0${clean.substring(4)}';
    } else if (clean.startsWith('254') && clean.length == 12) {
      clean = '0${clean.substring(3)}';
    }
    // Verify valid Kenyan mobile number (07XX or 01XX, 10 digits)
    if (RegExp(r'^0[17]\d{8}$').hasMatch(clean)) {
      return clean;
    }
    return clean;
  }

  /// Extracts M-Pesa reference code (typically 10 alphanumeric chars e.g. QA12BC34DE).
  static String? extractMpesaReference(String text) {
    final match = RegExp(
      r'^([A-Z0-9]{8,12})\s+(?:Confirmed|confirmed)',
      caseSensitive: false,
    ).firstMatch(text.trim());

    if (match != null) {
      return match.group(1)!.toUpperCase();
    }
    return null;
  }
}
