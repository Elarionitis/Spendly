// Core enums used across the application
enum SplitType { equal, exact, percentage }

enum SettlementStatus { pendingVerification, verified, rejected }

enum ExpenseCategory {
  food,
  transport,
  shopping,
  entertainment,
  accommodation,
  utilities,
  health,
  education,
  travel,
  other;

  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.accommodation:
        return 'Accommodation';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.food:
        return '🍽️';
      case ExpenseCategory.transport:
        return '🚗';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.entertainment:
        return '🎬';
      case ExpenseCategory.accommodation:
        return '🏠';
      case ExpenseCategory.utilities:
        return '⚡';
      case ExpenseCategory.health:
        return '💊';
      case ExpenseCategory.education:
        return '📚';
      case ExpenseCategory.travel:
        return '✈️';
      case ExpenseCategory.other:
        return '💰';
    }
  }
}

enum PaymentMethod {
  cash,
  card,
  upi,
  netBanking,
  wallet,
  other;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}
