import 'dart:async';
import '../../models/group.dart';
import '../group_repository.dart';


/// In-memory group repository seeded with demo groups.
class DemoGroupRepository implements GroupRepository {
  final List<Group> _groups = [];
  final _controller = StreamController<List<Group>>.broadcast();

  DemoGroupRepository() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    _groups.addAll([
      Group(
        id: 'g1',
        name: 'Goa Trip 2025',
        description: 'Beach holiday with friends',
        createdById: 'u1',
        memberIds: ['u1', 'u2', 'u3', 'u4'],
        createdAt: now.subtract(const Duration(days: 30)),
        emoji: '🏖️',
      ),
      Group(
        id: 'g2',
        name: 'Apartment Rent',
        description: 'Monthly shared expenses',
        createdById: 'u1',
        memberIds: ['u1', 'u2', 'u3'],
        createdAt: now.subtract(const Duration(days: 60)),
        emoji: '🏠',
      ),
      Group(
        id: 'g3',
        name: 'Office Lunch',
        description: 'Daily office meals',
        createdById: 'u2',
        memberIds: ['u1', 'u2', 'u4'],
        createdAt: now.subtract(const Duration(days: 15)),
        emoji: '🍱',
      ),
    ]);
  }

  void _emit() => _controller.add(List.unmodifiable(_groups));

  @override
  Stream<List<Group>> watchGroups(String userId) {
    // Emit current state immediately when subscribed
    final filtered = _groups.where((g) => g.memberIds.contains(userId)).toList();
    return Stream.fromFuture(Future.value(filtered)).mergeWith([
      _controller.stream
          .map((all) => all.where((g) => g.memberIds.contains(userId)).toList()),
    ]);
  }

  @override
  Future<List<Group>> getGroups(String userId) async =>
      _groups.where((g) => g.memberIds.contains(userId)).toList();

  @override
  Future<void> createGroup(Group group) async {
    _groups.add(group);
    _emit();
  }

  @override
  Future<void> updateGroup(Group group) async {
    final idx = _groups.indexWhere((g) => g.id == group.id);
    if (idx >= 0) {
      _groups[idx] = group;
      _emit();
    }
  }

  @override
  Future<void> deleteGroup(String id) async {
    _groups.removeWhere((g) => g.id == id);
    _emit();
  }
}

// Small helper extension to merge two streams
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
