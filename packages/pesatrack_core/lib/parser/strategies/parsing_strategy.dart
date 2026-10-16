import '../mpesa_parser_utils.dart';
import '../mpesa_transaction_types.dart';
import '../parsed_sms_result.dart';

abstract class ParsingStrategy {
  bool canParse(String message);
  ParsedSmsResult parse(String message);
}

/// Strategy for "Send Money" transactions.
/// E.g. "QA12BC34DE Confirmed. Ksh1,500.00 sent to JANE DOE 0712345678 on 15/10/26 at 8:30 PM..."
class SendMoneyStrategy implements ParsingStrategy {
  @override
  bool canParse(String message) {
    return RegExp(r'\b(?:sent|transferred)\s+to\b', caseSensitive: false)
            .hasMatch(message) &&
        !RegExp(r'\bairtime\b', caseSensitive: false).hasMatch(message);
  }

  @override
  ParsedSmsResult parse(String message) {
    final ref = MpesaParserUtils.extractMpesaReference(message);
    final timestamp = MpesaParserUtils.parseDateTime(message);
    final feeCents = MpesaParserUtils.extractFeeCents(message);
    final balanceAfterCents =
        MpesaParserUtils.extractBalanceAfterCents(message);

    // Extract amount before "sent to" or "transferred to"
    final amountMatch = RegExp(
      r'(?:Ksh|KES)\.?\s*([\d,]+(?:\.\d{1,2})?)\s+(?:sent|transferred)\s+to',
      caseSensitive: false,
    ).firstMatch(message);

    int amountCents = 0;
    if (amountMatch != null) {
      amountCents =
          MpesaParserUtils.parseAmountToCents(amountMatch.group(1)!) ?? 0;
    } else {
      amountCents = MpesaParserUtils.parseAmountToCents(message) ?? 0;
    }

    // Extract recipient name and phone number
    // E.g. "sent to JANE DOE 0712345678 on" or "transferred to ZIIDI on"
    String? recipientName;
    String? recipientPhone;

    final recipientMatch = RegExp(
      r'(?:sent|transferred)\s+to\s+([A-Za-z0-9\s\.\-]+?)\s+(?:(\+?254\d{9}|0[17]\d{8})\s+)?on\s+\d',
      caseSensitive: false,
    ).firstMatch(message);

    if (recipientMatch != null) {
      recipientName = recipientMatch.group(1)?.trim();
      recipientPhone =
          MpesaParserUtils.normalizePhoneNumber(recipientMatch.group(2));
    } else {
      // Fallback pattern
      final fallbackMatch = RegExp(
        r'(?:sent|transferred)\s+to\s+(.+?)\s+on\s+\d',
        caseSensitive: false,
      ).firstMatch(message);
      if (fallbackMatch != null) {
        final raw = fallbackMatch.group(1)!.trim();
        // Check if ends with phone number
        final phoneExtract =
            RegExp(r'(?:(\+?254\d{9}|0[17]\d{8}))$').firstMatch(raw);
        if (phoneExtract != null) {
          recipientPhone =
              MpesaParserUtils.normalizePhoneNumber(phoneExtract.group(1));
          recipientName = raw.substring(0, phoneExtract.start).trim();
        } else {
          recipientName = raw;
        }
      }
    }

    // Strip trailing punctuation from name
    if (recipientName != null) {
      recipientName =
          recipientName.replaceAll(RegExp(r'[\.\,\;]+$'), '').trim();
    }

    return ParsedSmsResult(
      isMpesa: true,
      mpesaReference: ref,
      transactionType: TransactionType.sendMoney,
      classification: FinancialClassification.transfer,
      amountCents: amountCents,
      feeCents: feeCents,
      timestamp: timestamp,
      counterpartyName: recipientName,
      counterpartyPhone: recipientPhone,
      description:
          recipientName != null ? 'Sent money to $recipientName' : 'Sent money',
      balanceAfterCents: balanceAfterCents,
      confidenceScore:
          (ref != null && amountCents > 0 && timestamp != null) ? 1.0 : 0.85,
      reviewStatus: ReviewStatus.verified,
      rawMessage: message,
    );
  }
}

/// Strategy for "Money Received" transactions.
/// E.g. "QA12BC34DF Confirmed. You have received Ksh2,500.00 from JOHN SMITH 0722334455 on 15/10/26 at 2:15 PM..."
class ReceiveMoneyStrategy implements ParsingStrategy {
  @override
  bool canParse(String message) {
    return RegExp(r'\breceived\b', caseSensitive: false).hasMatch(message) &&
        RegExp(r'\bfrom\b', caseSensitive: false).hasMatch(message);
  }

  @override
  ParsedSmsResult parse(String message) {
    final ref = MpesaParserUtils.extractMpesaReference(message);
    final timestamp = MpesaParserUtils.parseDateTime(message);
    final balanceAfterCents =
        MpesaParserUtils.extractBalanceAfterCents(message);

    // Amount received
    final amountMatch = RegExp(
      r'received\s+(?:Ksh|KES)\.?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(message);

    int amountCents = 0;
    if (amountMatch != null) {
      amountCents =
          MpesaParserUtils.parseAmountToCents(amountMatch.group(1)!) ?? 0;
    } else {
      amountCents = MpesaParserUtils.parseAmountToCents(message) ?? 0;
    }

    // Sender details
    String? senderName;
    String? senderPhone;

    final senderMatch = RegExp(
      r'from\s+([A-Za-z0-9\s\.\-]+?)\s+(?:(\+?254\d{9}|0[17]\d{8})\s+)?on\s+\d',
      caseSensitive: false,
    ).firstMatch(message);

    if (senderMatch != null) {
      senderName = senderMatch.group(1)?.trim();
      senderPhone = MpesaParserUtils.normalizePhoneNumber(senderMatch.group(2));
    } else {
      final fallbackMatch = RegExp(
        r'from\s+(.+?)\s+on\s+\d',
        caseSensitive: false,
      ).firstMatch(message);
      if (fallbackMatch != null) {
        final raw = fallbackMatch.group(1)!.trim();
        final phoneExtract =
            RegExp(r'(?:(\+?254\d{9}|0[17]\d{8}))$').firstMatch(raw);
        if (phoneExtract != null) {
          senderPhone =
              MpesaParserUtils.normalizePhoneNumber(phoneExtract.group(1));
          senderName = raw.substring(0, phoneExtract.start).trim();
        } else {
          senderName = raw;
        }
      }
    }

    if (senderName != null) {
      senderName = senderName.replaceAll(RegExp(r'[\.\,\;]+$'), '').trim();
    }

    return ParsedSmsResult(
      isMpesa: true,
      mpesaReference: ref,
      transactionType: TransactionType.receiveMoney,
      classification: FinancialClassification.income,
      amountCents: amountCents,
      feeCents: 0,
      timestamp: timestamp,
      counterpartyName: senderName,
      counterpartyPhone: senderPhone,
      description: senderName != null
          ? 'Received money from $senderName'
          : 'Received money',
      balanceAfterCents: balanceAfterCents,
      confidenceScore:
          (ref != null && amountCents > 0 && timestamp != null) ? 1.0 : 0.85,
      reviewStatus: ReviewStatus.verified,
      rawMessage: message,
    );
  }
}

/// Strategy for "PayBill" transactions.
/// E.g. "QA12BC34DG Confirmed. Ksh3,200.00 paid to KPLC PREPAID. for account 1425364758 on 14/10/26 at 9:45 AM..."
class PayBillStrategy implements ParsingStrategy {
  @override
  bool canParse(String message) {
    return RegExp(r'\bpaid to\b', caseSensitive: false).hasMatch(message) &&
        RegExp(r'\bfor account\b', caseSensitive: false).hasMatch(message);
  }

  @override
  ParsedSmsResult parse(String message) {
    final ref = MpesaParserUtils.extractMpesaReference(message);
    final timestamp = MpesaParserUtils.parseDateTime(message);
    final feeCents = MpesaParserUtils.extractFeeCents(message);
    final balanceAfterCents =
        MpesaParserUtils.extractBalanceAfterCents(message);

    // Amount paid
    final amountMatch = RegExp(
      r'(?:Ksh|KES)\.?\s*([\d,]+(?:\.\d{1,2})?)\s+paid to',
      caseSensitive: false,
    ).firstMatch(message);

    int amountCents = 0;
    if (amountMatch != null) {
      amountCents =
          MpesaParserUtils.parseAmountToCents(amountMatch.group(1)!) ?? 0;
    } else {
      amountCents = MpesaParserUtils.parseAmountToCents(message) ?? 0;
    }

    // Merchant and account
    String? merchant;
    String? account;

    final detailMatch = RegExp(
      r'paid to\s+(.+?)\.?\s+for account\s+(.+?)\s+on\s+\d',
      caseSensitive: false,
    ).firstMatch(message);

    if (detailMatch != null) {
      merchant = detailMatch.group(1)?.trim();
      account = detailMatch.group(2)?.trim();
    }

    if (merchant != null) {
      merchant = merchant.replaceAll(RegExp(r'[\.\,\;]+$'), '').trim();
    }
    if (account != null) {
      account = account.replaceAll(RegExp(r'[\.\,\;]+$'), '').trim();
    }

    return ParsedSmsResult(
      isMpesa: true,
      mpesaReference: ref,
      transactionType: TransactionType.payBill,
      classification: FinancialClassification.expense,
      amountCents: amountCents,
      feeCents: feeCents,
      timestamp: timestamp,
      counterpartyName: merchant,
      accountReference: account,
      description: merchant != null
          ? 'PayBill to $merchant${account != null ? " (Acc: $account)" : ""}'
          : 'PayBill payment',
      balanceAfterCents: balanceAfterCents,
      confidenceScore:
          (ref != null && amountCents > 0 && timestamp != null) ? 1.0 : 0.85,
      reviewStatus: ReviewStatus.verified,
      rawMessage: message,
    );
  }
}

/// Strategy for "Buy Goods / Till" transactions.
/// E.g. "QA12BC34DH Confirmed. Ksh850.00 paid to NAIVAS SUPERMARKET. on 14/10/26 at 1:20 PM..."
class BuyGoodsStrategy implements ParsingStrategy {
  @override
  bool canParse(String message) {
    return RegExp(r'\bpaid to\b', caseSensitive: false).hasMatch(message) &&
        !RegExp(r'\bfor account\b', caseSensitive: false).hasMatch(message);
  }

  @override
  ParsedSmsResult parse(String message) {
    final ref = MpesaParserUtils.extractMpesaReference(message);
    final timestamp = MpesaParserUtils.parseDateTime(message);
    final feeCents = MpesaParserUtils.extractFeeCents(message);
    final balanceAfterCents =
        MpesaParserUtils.extractBalanceAfterCents(message);

    // Amount paid
    final amountMatch = RegExp(
      r'(?:Ksh|KES)\.?\s*([\d,]+(?:\.\d{1,2})?)\s+paid to',
      caseSensitive: false,
    ).firstMatch(message);

    int amountCents = 0;
    if (amountMatch != null) {
      amountCents =
          MpesaParserUtils.parseAmountToCents(amountMatch.group(1)!) ?? 0;
    } else {
      amountCents = MpesaParserUtils.parseAmountToCents(message) ?? 0;
    }

    // Merchant name
    String? merchant;
    final merchantMatch = RegExp(
      r'paid to\s+(.+?)\.?\s+on\s+\d',
      caseSensitive: false,
    ).firstMatch(message);

    if (merchantMatch != null) {
      merchant = merchantMatch.group(1)?.trim();
      merchant = merchant?.replaceAll(RegExp(r'[\.\,\;]+$'), '').trim();
    }

    return ParsedSmsResult(
      isMpesa: true,
      mpesaReference: ref,
      transactionType: TransactionType.buyGoods,
      classification: FinancialClassification.expense,
      amountCents: amountCents,
      feeCents: feeCents,
      timestamp: timestamp,
      counterpartyName: merchant,
      description:
          merchant != null ? 'Paid $merchant (Buy Goods)' : 'Buy Goods payment',
      balanceAfterCents: balanceAfterCents,
      confidenceScore:
          (ref != null && amountCents > 0 && timestamp != null) ? 1.0 : 0.85,
      reviewStatus: ReviewStatus.verified,
      rawMessage: message,
    );
  }
}

/// Strategy for Agent and ATM cash withdrawals.
/// E.g. "QA12BC34DI Confirmed. on 13/10/26 at 11:10 AM Withdraw Ksh5,000.00 from 123456 - SAFARICOM AGENT..."
class WithdrawStrategy implements ParsingStrategy {
  @override
  bool canParse(String message) {
    return RegExp(r'\bwithdraw\b|\bwithdrawn\b', caseSensitive: false)
        .hasMatch(message);
  }

  @override
  ParsedSmsResult parse(String message) {
    final ref = MpesaParserUtils.extractMpesaReference(message);
    final timestamp = MpesaParserUtils.parseDateTime(message);
    final feeCents = MpesaParserUtils.extractFeeCents(message);
    final balanceAfterCents =
        MpesaParserUtils.extractBalanceAfterCents(message);

    // Is ATM or Agent?
    final isAtm = RegExp(r'\bATM\b', caseSensitive: false).hasMatch(message);

    // Extract amount
    final amountMatch = RegExp(
      r'(?:Withdraw|withdrawn)\s+(?:Ksh|KES)\.?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(message);

    int amountCents = 0;
    if (amountMatch != null) {
      amountCents =
          MpesaParserUtils.parseAmountToCents(amountMatch.group(1)!) ?? 0;
    } else {
      amountCents = MpesaParserUtils.parseAmountToCents(message) ?? 0;
    }

    // Extract Agent / ATM name
    String? agentName;
    final agentMatch = RegExp(
      r'from\s+(.+?)\.?\s+New M-PESA balance',
      caseSensitive: false,
    ).firstMatch(message);

    if (agentMatch != null) {
      agentName = agentMatch.group(1)?.trim();
    } else {
      final fallbackAgent =
          RegExp(r'from\s+(.+?)\.?$', caseSensitive: false).firstMatch(message);
      if (fallbackAgent != null) {
        agentName = fallbackAgent.group(1)?.trim();
      }
    }

    if (agentName != null) {
      agentName = agentName.replaceAll(RegExp(r'[\.\,\;]+$'), '').trim();
    }

    return ParsedSmsResult(
      isMpesa: true,
      mpesaReference: ref,
      transactionType:
          isAtm ? TransactionType.withdrawAtm : TransactionType.withdrawAgent,
      classification: FinancialClassification.withdrawal,
      amountCents: amountCents,
      feeCents: feeCents,
      timestamp: timestamp,
      counterpartyName: agentName,
      description: agentName != null
          ? 'Cash withdrawal from $agentName'
          : 'Cash withdrawal',
      balanceAfterCents: balanceAfterCents,
      confidenceScore:
          (ref != null && amountCents > 0 && timestamp != null) ? 1.0 : 0.85,
      reviewStatus: ReviewStatus.verified,
      rawMessage: message,
    );
  }
}

/// Strategy for Cash Deposits.
/// E.g. "QA12BC34DK Confirmed. on 11/10/26 at 10:00 AM Give Ksh10,000.00 cash to 654321 - TOTAL..."
class DepositStrategy implements ParsingStrategy {
  @override
  bool canParse(String message) {
    return RegExp(r'\bGive\b.*?\bcash to\b', caseSensitive: false)
            .hasMatch(message) ||
        RegExp(r'\bDeposit of\b', caseSensitive: false).hasMatch(message);
  }

  @override
  ParsedSmsResult parse(String message) {
    final ref = MpesaParserUtils.extractMpesaReference(message);
    final timestamp = MpesaParserUtils.parseDateTime(message);
    final balanceAfterCents =
        MpesaParserUtils.extractBalanceAfterCents(message);

    final amountMatch = RegExp(
      r'(?:Give|Deposit of)\s+(?:Ksh|KES)\.?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(message);

    int amountCents = 0;
    if (amountMatch != null) {
      amountCents =
          MpesaParserUtils.parseAmountToCents(amountMatch.group(1)!) ?? 0;
    } else {
      amountCents = MpesaParserUtils.parseAmountToCents(message) ?? 0;
    }

    String? agent;
    final agentMatch = RegExp(
      r'cash to\s+(.+?)\.?\s+New M-PESA balance',
      caseSensitive: false,
    ).firstMatch(message);

    if (agentMatch != null) {
      agent = agentMatch.group(1)?.trim();
      agent = agent?.replaceAll(RegExp(r'[\.\,\;]+$'), '').trim();
    }

    return ParsedSmsResult(
      isMpesa: true,
      mpesaReference: ref,
      transactionType: TransactionType.deposit,
      classification: FinancialClassification.deposit,
      amountCents: amountCents,
      feeCents: 0,
      timestamp: timestamp,
      counterpartyName: agent,
      description: agent != null ? 'Cash deposit at $agent' : 'Cash deposit',
      balanceAfterCents: balanceAfterCents,
      confidenceScore:
          (ref != null && amountCents > 0 && timestamp != null) ? 1.0 : 0.85,
      reviewStatus: ReviewStatus.verified,
      rawMessage: message,
    );
  }
}

/// Strategy for Airtime purchases.
/// E.g. "QA12BC34DL Confirmed.You bought Ksh100.00 of airtime on 15/10/26 at 6:40 PM..."
/// or "You bought Ksh200.00 of airtime for 0799887766 on..."
class AirtimeStrategy implements ParsingStrategy {
  @override
  bool canParse(String message) {
    return RegExp(r'\bairtime\b', caseSensitive: false).hasMatch(message);
  }

  @override
  ParsedSmsResult parse(String message) {
    final ref = MpesaParserUtils.extractMpesaReference(message);
    final timestamp = MpesaParserUtils.parseDateTime(message);
    final balanceAfterCents =
        MpesaParserUtils.extractBalanceAfterCents(message);
    final feeCents = MpesaParserUtils.extractFeeCents(message);

    final amountMatch = RegExp(
      r'bought\s+(?:Ksh|KES)\.?\s*([\d,]+(?:\.\d{1,2})?)\s+of airtime',
      caseSensitive: false,
    ).firstMatch(message);

    int amountCents = 0;
    if (amountMatch != null) {
      amountCents =
          MpesaParserUtils.parseAmountToCents(amountMatch.group(1)!) ?? 0;
    } else {
      amountCents = MpesaParserUtils.parseAmountToCents(message) ?? 0;
    }

    // Airtime for someone else?
    String? recipientPhone;
    final otherMatch = RegExp(
      r'of airtime for\s+(\+?254\d{9}|0[17]\d{8})',
      caseSensitive: false,
    ).firstMatch(message);

    if (otherMatch != null) {
      recipientPhone =
          MpesaParserUtils.normalizePhoneNumber(otherMatch.group(1));
    }

    return ParsedSmsResult(
      isMpesa: true,
      mpesaReference: ref,
      transactionType: TransactionType.airtime,
      classification: FinancialClassification.expense,
      amountCents: amountCents,
      feeCents: feeCents,
      timestamp: timestamp,
      counterpartyName: recipientPhone != null
          ? 'Airtime ($recipientPhone)'
          : 'Airtime (Self)',
      counterpartyPhone: recipientPhone,
      description: recipientPhone != null
          ? 'Airtime purchase for $recipientPhone'
          : 'Airtime purchase for self',
      balanceAfterCents: balanceAfterCents,
      confidenceScore:
          (ref != null && amountCents > 0 && timestamp != null) ? 1.0 : 0.85,
      reviewStatus: ReviewStatus.verified,
      rawMessage: message,
    );
  }
}

/// Strategy for Reversals & Refunds.
/// E.g. "QA12BC34DN Confirmed. Transaction QA12BC34DE has been reversed on 15/10/26 at 9:00 PM and Ksh1,500.00 is credited..."
class ReversalStrategy implements ParsingStrategy {
  @override
  bool canParse(String message) {
    return RegExp(r'\breversed\b|\breversal\b', caseSensitive: false)
        .hasMatch(message);
  }

  @override
  ParsedSmsResult parse(String message) {
    final ref = MpesaParserUtils.extractMpesaReference(message);
    final timestamp = MpesaParserUtils.parseDateTime(message);
    final balanceAfterCents =
        MpesaParserUtils.extractBalanceAfterCents(message);

    // Reversed reference
    String? originalRef;
    final origMatch = RegExp(
      r'Transaction\s+([A-Z0-9]{8,12})\s+has been reversed',
      caseSensitive: false,
    ).firstMatch(message);

    if (origMatch != null) {
      originalRef = origMatch.group(1)!.toUpperCase();
    }

    // Amount credited
    final amountMatch = RegExp(
      r'(?:Ksh|KES)\.?\s*([\d,]+(?:\.\d{1,2})?)\s+(?:is|has been)\s+credited',
      caseSensitive: false,
    ).firstMatch(message);

    int amountCents = 0;
    if (amountMatch != null) {
      amountCents =
          MpesaParserUtils.parseAmountToCents(amountMatch.group(1)!) ?? 0;
    } else {
      amountCents = MpesaParserUtils.parseAmountToCents(message) ?? 0;
    }

    return ParsedSmsResult(
      isMpesa: true,
      mpesaReference: ref,
      transactionType: TransactionType.reversal,
      classification: FinancialClassification.adjustment,
      amountCents: amountCents,
      feeCents: 0,
      timestamp: timestamp,
      reversalReference: originalRef,
      description: originalRef != null
          ? 'Reversal of transaction $originalRef'
          : 'Transaction reversal',
      balanceAfterCents: balanceAfterCents,
      confidenceScore: (ref != null && amountCents > 0) ? 1.0 : 0.80,
      reviewStatus: ReviewStatus.verified,
      rawMessage: message,
    );
  }
}
