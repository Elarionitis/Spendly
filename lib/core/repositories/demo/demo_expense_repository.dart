import 'dart:async';
import '../../models/expense.dart';
import '../../models/enums.dart';
import '../expense_repository.dart';

/// In-memory expense repository seeded with demo expenses.
class DemoExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [];
  final _controller = StreamController<List<Expense>>.broadcast();

  DemoExpenseRepository() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    _expenses.addAll([
      // Goa Trip (Group)
      Expense(
        id: 'ge1', type: ExpenseType.group, groupId: 'g1', 
        participants: ['u1', 'u2', 'u3', 'u4'],
        description: 'Hotel Booking', amount: 12000, paidById: 'u1',
        splitDetails: {'u1': 3000, 'u2': 3000, 'u3': 3000, 'u4': 3000},
        splitType: SplitType.equal, category: ExpenseCategory.accommodation,
        date: now.subtract(const Duration(days: 28)),
      ),
      Expense(
        id: 'ge2', type: ExpenseType.group, groupId: 'g1',
        participants: ['u1', 'u2', 'u3', 'u4'],
        description: 'Flight Tickets', amount: 24000, paidById: 'u2',
        splitDetails: {'u1': 6000, 'u2': 6000, 'u3': 6000, 'u4': 6000},
        splitType: SplitType.equal, category: ExpenseCategory.travel,
        date: now.subtract(const Duration(days: 27)),
      ),
      // Personal / Non-Group
      Expense(
        id: 'pe1', type: ExpenseType.personal, 
        participants: ['u1', 'u2'],
        description: 'Movie Tickets', amount: 800, paidById: 'u1',
        splitDetails: {'u1': 400, 'u2': 400},
        splitType: SplitType.equal, category: ExpenseCategory.entertainment,
        date: now.subtract(const Duration(days: 10)),
      ),
      Expense(
        id: 'pe2', type: ExpenseType.personal,
        participants: ['u1', 'u3'],
        description: 'Dinner', amount: 1500, paidById: 'u3',
        splitDetails: {'u1': 750, 'u3': 750},
        splitType: SplitType.equal, category: ExpenseCategory.food,
        date: now.subtract(const Duration(days: 5)),
      ),
      // Apartment (Group)
      Expense(
        id: 'ge5', type: ExpenseType.group, groupId: 'g2',
        participants: ['u1', 'u2', 'u3'],
        description: 'Monthly Rent', amount: 45000, paidById: 'u1',
        splitDetails: {'u1': 15000, 'u2': 15000, 'u3': 15000},
        splitType: SplitType.equal, category: ExpenseCategory.accommodation,
        date: now.subtract(const Duration(days: 5)),
      ),
    ]);
  }

  void _emit() => _controller.add(List.unmodifiable(_expenses));

  @override
  Stream<List<Expense>> watchUserExpenses(String userId) {
    final filtered = _expenses.where((e) => e.participants.contains(userId)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // In a real app we'd combine with the stream for updates
    return Stream.value(filtered); 
  }

  @override
  Stream<List<Expense>> watchGroupExpenses(String groupId) {
    final filtered = _expenses.where((e) => e.groupId == groupId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Stream.value(filtered);
  }

  @override
  Future<void> addExpense(Expense expense, {dynamic imageFile}) async {
    _expenses.insert(0, expense);
    _emit();
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx >= 0) {
      _expenses[idx] = expense;
      _emit();
    }
  }

  @override
  Future<void> updateApprovalStatus(
    String id, {
    List<String>? approvals,
    List<String>? rejections,
  }) async {
    final idx = _expenses.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _expenses[idx] = _expenses[idx].copyWith(
        approvals: approvals,
        rejections: rejections,
      );
      _emit();
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    _emit();
  }
}
