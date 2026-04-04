import 'dart:async';
import '../../models/group_expense.dart';
import '../../models/enums.dart';
import '../expense_repository.dart';

/// In-memory expense repository seeded with demo expenses.
class DemoExpenseRepository implements ExpenseRepository {
  final List<GroupExpense> _expenses = [];
  final _controller = StreamController<List<GroupExpense>>.broadcast();

  DemoExpenseRepository() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    _expenses.addAll([
      // Goa Trip
      GroupExpense(
        id: 'ge1', groupId: 'g1', description: 'Hotel Booking',
        amount: 12000, paidById: 'u1',
        splitDetails: {'u1': 3000, 'u2': 3000, 'u3': 3000, 'u4': 3000},
        splitType: SplitType.equal, category: ExpenseCategory.accommodation,
        date: now.subtract(const Duration(days: 28)),
      ),
      GroupExpense(
        id: 'ge2', groupId: 'g1', description: 'Flight Tickets',
        amount: 24000, paidById: 'u2',
        splitDetails: {'u1': 6000, 'u2': 6000, 'u3': 6000, 'u4': 6000},
        splitType: SplitType.equal, category: ExpenseCategory.travel,
        date: now.subtract(const Duration(days: 27)),
      ),
      GroupExpense(
        id: 'ge3', groupId: 'g1', description: 'Beach Restaurant',
        amount: 4500, paidById: 'u3',
        splitDetails: {'u1': 1125, 'u2': 1125, 'u3': 1125, 'u4': 1125},
        splitType: SplitType.equal, category: ExpenseCategory.food,
        date: now.subtract(const Duration(days: 25)),
      ),
      GroupExpense(
        id: 'ge4', groupId: 'g1', description: 'Water Sports',
        amount: 3000, paidById: 'u1',
        splitDetails: {'u1': 750, 'u2': 1500, 'u4': 750},
        splitType: SplitType.exact, category: ExpenseCategory.entertainment,
        date: now.subtract(const Duration(days: 24)),
      ),
      // Apartment
      GroupExpense(
        id: 'ge5', groupId: 'g2', description: 'Monthly Rent',
        amount: 45000, paidById: 'u1',
        splitDetails: {'u1': 15000, 'u2': 15000, 'u3': 15000},
        splitType: SplitType.equal, category: ExpenseCategory.accommodation,
        date: now.subtract(const Duration(days: 5)),
      ),
      GroupExpense(
        id: 'ge6', groupId: 'g2', description: 'Electricity Bill',
        amount: 3600, paidById: 'u2',
        splitDetails: {'u1': 1200, 'u2': 1200, 'u3': 1200},
        splitType: SplitType.equal, category: ExpenseCategory.utilities,
        date: now.subtract(const Duration(days: 3)),
      ),
      // Office Lunch
      GroupExpense(
        id: 'ge7', groupId: 'g3', description: 'Pizza Party',
        amount: 1800, paidById: 'u2',
        splitDetails: {'u1': 600, 'u2': 600, 'u4': 600},
        splitType: SplitType.equal, category: ExpenseCategory.food,
        date: now.subtract(const Duration(days: 2)),
      ),
      GroupExpense(
        id: 'ge8', groupId: 'g3', description: 'Coffee & Snacks',
        amount: 450, paidById: 'u1',
        splitDetails: {'u1': 150, 'u2': 150, 'u4': 150},
        splitType: SplitType.equal, category: ExpenseCategory.food,
        date: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  void _emit() => _controller.add(List.unmodifiable(_expenses));

  @override
  Stream<List<GroupExpense>> watchExpenses(String groupId) {
    final filtered = _expenses.where((e) => e.groupId == groupId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Stream.value(filtered).mergeWith([
      _controller.stream.map((all) => all
          .where((e) => e.groupId == groupId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date))),
    ]);
  }

  /// [imageFile] is ignored in demo mode — no Cloudinary upload.
  @override
  Future<void> addExpense(GroupExpense expense, {dynamic imageFile}) async {
    _expenses.insert(0, expense);
    _emit();
  }

  @override
  Future<void> updateExpense(GroupExpense expense) async {
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx >= 0) {
      _expenses[idx] = expense;
      _emit();
    }
  }

  @override
  Future<void> deleteExpense(String groupId, String id) async {
    _expenses.removeWhere((e) => e.id == id);
    _emit();
  }
}

extension _StreamMerge<T> on Stream<T> {
  Stream<T> mergeWith(List<Stream<T>> others) {
    final controller = StreamController<T>.broadcast();
    listen(controller.add, onError: controller.addError);
    for (final s in others) {
      s.listen(controller.add, onError: controller.addError);
    }
    return controller.stream;
  }
}
