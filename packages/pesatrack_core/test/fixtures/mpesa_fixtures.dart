/// Test fixtures representing genuine M-Pesa SMS message patterns.
class MpesaFixtures {
  /// Send money to mobile number
  static const String sendMoney =
      'QA12BC34DE Confirmed. Ksh1,500.00 sent to JANE DOE 0712345678 on 15/10/26 at 8:30 PM. New M-PESA balance is Ksh12,450.00. Transaction cost, Ksh15.00. Amount you can transact within the day is 498,500.00.';

  /// Send money with 254 phone prefix
  static const String sendMoneyWith254 =
      'QA12BC34E1 Confirmed. Ksh500.00 sent to PETER KAMAU 254722112233 on 14/10/26 at 10:15 AM. New M-PESA balance is Ksh10,950.00. Transaction cost, Ksh7.00.';

  /// Send money with 01XX Safaricom/Airtel prefix
  static const String sendMoneyWith01Prefix =
      'QA12BC34E2 Confirmed. Ksh2,000.00 sent to MARY WANJIKU 0110123456 on 13/10/26 at 4:20 PM. New M-PESA balance is Ksh8,943.00. Transaction cost, Ksh15.00.';

  /// Money received from individual
  static const String receiveMoney =
      'QA12BC34DF Confirmed. You have received Ksh2,500.00 from JOHN SMITH 0722334455 on 15/10/26 at 2:15 PM. New M-PESA balance is Ksh14,950.00. Separate personal and business funds on Pochi la Biashara today.';

  /// PayBill payment
  static const String payBill =
      'QA12BC34DG Confirmed. Ksh3,200.00 paid to KPLC PREPAID. for account 1425364758 on 14/10/26 at 9:45 AM. New M-PESA balance is Ksh11,750.00. Transaction cost, Ksh0.00.';

  /// Buy Goods / Till payment
  static const String buyGoods =
      'QA12BC34DH Confirmed. Ksh850.00 paid to NAIVAS SUPERMARKET. on 14/10/26 at 1:20 PM. New M-PESA balance is Ksh10,900.00. Transaction cost, Ksh0.00.';

  /// Cash withdrawal from Safaricom Agent
  static const String withdrawAgent =
      'QA12BC34DI Confirmed. on 13/10/26 at 11:10 AM Withdraw Ksh5,000.00 from 123456 - SAFARICOM AGENT NAIROBI. New M-PESA balance is Ksh5,820.00. Transaction cost, Ksh80.00.';

  /// Cash withdrawal from ATM
  static const String withdrawAtm =
      'QA12BC34DJ Confirmed. on 12/10/26 at 4:30 PM Withdraw Ksh10,000.00 from ATM 555666 - EQUITY BANK. New M-PESA balance is Ksh15,700.00. Transaction cost, Ksh120.00.';

  /// Cash deposit at agent
  static const String depositCash =
      'QA12BC34DK Confirmed. on 11/10/26 at 10:00 AM Give Ksh10,000.00 cash to 654321 - TOTAL SERVICE STATION. New M-PESA balance is Ksh25,820.00. Transaction cost, Ksh0.00.';

  /// Airtime purchase for self
  static const String airtimeSelf =
      'QA12BC34DL Confirmed.You bought Ksh100.00 of airtime on 15/10/26 at 6:40 PM. New M-PESA balance is Ksh12,350.00. Transaction cost, Ksh0.00.';

  /// Airtime purchase for other number
  static const String airtimeOther =
      'QA12BC34DM Confirmed. You bought Ksh200.00 of airtime for 0799887766 on 15/10/26 at 7:15 PM. New M-PESA balance is Ksh12,150.00. Transaction cost, Ksh0.00.';

  /// Transaction Reversal
  static const String reversal =
      'QA12BC34DN Confirmed. Transaction QA12BC34DE has been reversed on 15/10/26 at 9:00 PM and Ksh1,500.00 is credited to your M-PESA account. New M-PESA balance is Ksh13,650.00.';

  /// Unrecognized / Spam promotional message
  static const String spamPromo =
      'Dear Customer, spin the wheel today to win 100,000 KSH airtime! Click safaricom.com/spin to play.';

  /// Malformed confirmation message (corrupted text)
  static const String malformed =
      'QA12BC34DX Confirmed. Some random truncated text with no amount or date.';
}
