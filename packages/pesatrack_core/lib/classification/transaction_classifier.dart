import '../models/category.dart';
import '../parser/mpesa_transaction_types.dart';
import '../parser/parsed_sms_result.dart';

/// Classifies transactions into appropriate categories using transaction type,
/// counterparty intelligence, and customizable merchant mapping rules.
class TransactionClassifier {
  final Map<String, String> _merchantRules;

  TransactionClassifier({Map<String, String>? merchantRules})
      : _merchantRules = merchantRules ?? {};

  /// Suggests a category ID based on parsed SMS details and user rules.
  String suggestCategory(ParsedSmsResult parsed) {
    final counterparty = (parsed.counterpartyName ?? '').toLowerCase().trim();

    // 1. Check user-defined custom merchant mapping rules
    if (counterparty.isNotEmpty) {
      for (final entry in _merchantRules.entries) {
        if (counterparty.contains(entry.key.toLowerCase())) {
          return entry.value;
        }
      }
    }

    // 2. Type-specific deterministic mappings
    switch (parsed.transactionType) {
      case TransactionType.airtime:
        return 'airtime_data';
      case TransactionType.withdrawAgent:
      case TransactionType.withdrawAtm:
        return 'cash_withdrawals';
      case TransactionType.receiveMoney:
        return 'income';
      case TransactionType.fee:
        return 'fees';
      case TransactionType.deposit:
        return 'other';
      case TransactionType.reversal:
      case TransactionType.refund:
        return 'other';
      case TransactionType.transfer:
        return 'transfers';
      default:
        break;
    }

    // 3. Keyword-based heuristics for PayBill and Buy Goods / Till
    if (counterparty.isNotEmpty) {
      // Food & Groceries
      if (_matchesAny(counterparty, [
        'supermarket',
        'naivas',
        'quickmart',
        'carrefour',
        'chandarana',
        'cleanshelf',
        'grocer',
        'kfc',
        'java',
        'artcaffe',
        'pizza',
        'butchery',
        'bakery',
        'restaurant',
        'cafe',
        'food',
        'hotel',
        'greens',
      ])) {
        return 'food_groceries';
      }

      // Transport & Fuel
      if (_matchesAny(counterparty, [
        'uber',
        'bolt',
        'little',
        'total',
        'shell',
        'rubis',
        'petrol',
        'fuel',
        'oil',
        'matatu',
        'sacco',
        'shuttle',
        'parking',
        'kenya airways',
        'expressway',
      ])) {
        return 'transport';
      }

      // Utilities & Internet
      if (_matchesAny(counterparty, [
        'kplc',
        'power',
        'water',
        'sewerage',
        'zuku',
        'safaricom home',
        'faiba',
        'internet',
        'dstv',
        'gotv',
        'startimes',
      ])) {
        return 'utilities';
      }

      // Health & Medical
      if (_matchesAny(counterparty, [
        'hospital',
        'clinic',
        'pharmacy',
        'chemist',
        'medical',
        'dental',
        'optician',
        'lab',
      ])) {
        return 'health';
      }

      // Education
      if (_matchesAny(counterparty, [
        'school',
        'college',
        'academy',
        'university',
        'tuition',
        'kindergarten',
      ])) {
        return 'education';
      }

      // Rent & Housing
      if (_matchesAny(counterparty, [
        'rent',
        'housing',
        'apartments',
        'estate',
        'landlord',
        'caretaker',
      ])) {
        return 'rent';
      }

      // Shopping
      if (_matchesAny(counterparty, [
        'boutique',
        'fashion',
        'electronics',
        'hardware',
        'jumia',
        'kilimall',
        'store',
        'shop',
      ])) {
        return 'shopping';
      }

      // Entertainment
      if (_matchesAny(counterparty, [
        'cinema',
        'imax',
        'bar',
        'lounge',
        'resort',
        'club',
        'gaming',
      ])) {
        return 'entertainment';
      }
    }

    // Default fallback based on transaction type
    if (parsed.transactionType == TransactionType.sendMoney) {
      return 'transfers';
    }
    return 'other';
  }

  bool _matchesAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  /// Resolves the human-readable category name from ID.
  String getCategoryName(String categoryId) {
    final cat = CategoryModel.defaults.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => const CategoryModel(
        id: 'other',
        name: 'Other',
        iconName: 'category',
        colorValue: 0xFF616161,
      ),
    );
    return cat.name;
  }
}
