import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:test/test.dart';
import 'fixtures/mpesa_fixtures.dart';

void main() {
  group('MpesaParser - Comprehensive Format Tests', () {
    late MpesaParser parser;

    setUp(() {
      parser = MpesaParser();
    });

    test('Parses standard Send Money SMS correctly', () {
      final result = parser.parse(MpesaFixtures.sendMoney);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DE'));
      expect(result.transactionType, equals(TransactionType.sendMoney));
      expect(result.classification, equals(FinancialClassification.transfer));
      expect(result.amountCents, equals(150000)); // 1,500.00 KSh
      expect(result.amountInShillings, equals(1500.00));
      expect(result.feeCents, equals(1500)); // 15.00 KSh
      expect(result.counterpartyName, equals('JANE DOE'));
      expect(result.counterpartyPhone, equals('0712345678'));
      expect(result.balanceAfterCents, equals(1245000)); // 12,450.00 KSh
      expect(result.timestamp, isNotNull);
      expect(result.timestamp!.day, equals(15));
      expect(result.timestamp!.month, equals(10));
      expect(result.timestamp!.year, equals(2026));
      expect(result.timestamp!.hour, equals(20)); // 8 PM
      expect(result.timestamp!.minute, equals(30));
    });

    test('Parses Send Money with 254 country code and normalizes phone number',
        () {
      final result = parser.parse(MpesaFixtures.sendMoneyWith254);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34E1'));
      expect(result.amountCents, equals(50000));
      expect(result.counterpartyName, equals('PETER KAMAU'));
      expect(result.counterpartyPhone, equals('0722112233'));
      expect(result.feeCents, equals(700));
    });

    test('Parses Send Money with 01XX Airtel/Safaricom prefix', () {
      final result = parser.parse(MpesaFixtures.sendMoneyWith01Prefix);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34E2'));
      expect(result.amountCents, equals(200000));
      expect(result.counterpartyName, equals('MARY WANJIKU'));
      expect(result.counterpartyPhone, equals('0110123456'));
    });

    test('Parses Receive Money SMS correctly as income', () {
      final result = parser.parse(MpesaFixtures.receiveMoney);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DF'));
      expect(result.transactionType, equals(TransactionType.receiveMoney));
      expect(result.classification, equals(FinancialClassification.income));
      expect(result.amountCents, equals(250000));
      expect(result.counterpartyName, equals('JOHN SMITH'));
      expect(result.counterpartyPhone, equals('0722334455'));
      expect(result.balanceAfterCents, equals(1495000));
      expect(result.timestamp!.hour, equals(14)); // 2 PM
      expect(result.timestamp!.minute, equals(15));
    });

    test('Parses PayBill transaction with merchant and account number', () {
      final result = parser.parse(MpesaFixtures.payBill);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DG'));
      expect(result.transactionType, equals(TransactionType.payBill));
      expect(result.classification, equals(FinancialClassification.expense));
      expect(result.amountCents, equals(320000));
      expect(result.counterpartyName, equals('KPLC PREPAID'));
      expect(result.accountReference, equals('1425364758'));
      expect(result.feeCents, equals(0));
      expect(result.balanceAfterCents, equals(1175000));
    });

    test('Parses Buy Goods / Till transaction correctly', () {
      final result = parser.parse(MpesaFixtures.buyGoods);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DH'));
      expect(result.transactionType, equals(TransactionType.buyGoods));
      expect(result.classification, equals(FinancialClassification.expense));
      expect(result.amountCents, equals(85000));
      expect(result.counterpartyName, equals('NAIVAS SUPERMARKET'));
      expect(result.feeCents, equals(0));
    });

    test('Parses Agent cash withdrawal and separates fee', () {
      final result = parser.parse(MpesaFixtures.withdrawAgent);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DI'));
      expect(result.transactionType, equals(TransactionType.withdrawAgent));
      expect(result.classification, equals(FinancialClassification.withdrawal));
      expect(result.amountCents, equals(500000));
      expect(result.feeCents, equals(8000));
      expect(result.counterpartyName, contains('SAFARICOM AGENT NAIROBI'));
      expect(result.balanceAfterCents, equals(582000));
    });

    test('Parses ATM cash withdrawal correctly', () {
      final result = parser.parse(MpesaFixtures.withdrawAtm);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DJ'));
      expect(result.transactionType, equals(TransactionType.withdrawAtm));
      expect(result.classification, equals(FinancialClassification.withdrawal));
      expect(result.amountCents, equals(1000000));
      expect(result.feeCents, equals(12000));
      expect(result.counterpartyName, contains('EQUITY BANK'));
    });

    test('Parses cash deposit correctly', () {
      final result = parser.parse(MpesaFixtures.depositCash);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DK'));
      expect(result.transactionType, equals(TransactionType.deposit));
      expect(result.classification, equals(FinancialClassification.deposit));
      expect(result.amountCents, equals(1000000));
      expect(result.counterpartyName, contains('TOTAL SERVICE STATION'));
    });

    test('Parses Airtime purchase for self', () {
      final result = parser.parse(MpesaFixtures.airtimeSelf);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DL'));
      expect(result.transactionType, equals(TransactionType.airtime));
      expect(result.classification, equals(FinancialClassification.expense));
      expect(result.amountCents, equals(10000));
      expect(result.feeCents, equals(0));
    });

    test('Parses Airtime purchase for another mobile number', () {
      final result = parser.parse(MpesaFixtures.airtimeOther);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DM'));
      expect(result.transactionType, equals(TransactionType.airtime));
      expect(result.classification, equals(FinancialClassification.expense));
      expect(result.amountCents, equals(20000));
      expect(result.counterpartyPhone, equals('0799887766'));
    });

    test('Parses Reversal and extracts reversed transaction reference', () {
      final result = parser.parse(MpesaFixtures.reversal);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DN'));
      expect(result.transactionType, equals(TransactionType.reversal));
      expect(result.classification, equals(FinancialClassification.adjustment));
      expect(result.reversalReference, equals('QA12BC34DE'));
      expect(result.amountCents, equals(150000));
    });

    test(
        'Safely rejects promotional spam messages without creating transactions',
        () {
      final result = parser.parse(MpesaFixtures.spamPromo);

      expect(result.isMpesa, isFalse);
      expect(result.amountCents, equals(0));
      expect(result.reviewStatus, equals(ReviewStatus.needsReview));
    });

    test('Safely handles malformed SMS messages without throwing exceptions',
        () {
      final result = parser.parse(MpesaFixtures.malformed);

      expect(result.amountCents, equals(0));
      expect(result.reviewStatus, equals(ReviewStatus.needsReview));
      expect(result.failureReason, isNotNull);
    });

    test('Safely handles empty or whitespace messages', () {
      final result = parser.parse('   ');

      expect(result.isMpesa, isFalse);
      expect(result.amountCents, equals(0));
      expect(result.failureReason, contains('Empty'));
    });

    test('Parses Pochi la Biashara transactions correctly with zero fee', () {
      final result = parser.parse(MpesaFixtures.pochiLaBiashara);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DP'));
      expect(result.amountCents, equals(45000));
      expect(result.feeCents, equals(0));
      expect(result.counterpartyName, equals('MAMA MBOGA GROCERIES'));
      expect(result.counterpartyPhone, equals('0723456789'));
      expect(result.balanceAfterCents, equals(455000));
    });

    test('Parses Send Money with recipient name only (no phone number)', () {
      final result = parser.parse(MpesaFixtures.sendMoneyNoPhone);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DQ'));
      expect(result.amountCents, equals(120000));
      expect(result.counterpartyName, equals('KENNETH OCHIENG'));
      expect(result.feeCents, equals(1200));
      expect(result.balanceAfterCents, equals(335000));
    });

    test('Parses zero fee PayBill with alphanumeric account reference', () {
      final result = parser.parse(MpesaFixtures.zeroFeePaybill);

      expect(result.isMpesa, isTrue);
      expect(result.mpesaReference, equals('QA12BC34DR'));
      expect(result.amountCents, equals(50000));
      expect(result.counterpartyName, equals('NAIROBI WATER'));
      expect(result.accountReference, equals('NW-90210'));
      expect(result.feeCents, equals(0));
      expect(result.balanceAfterCents, equals(285000));
    });
  });
}
