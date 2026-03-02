import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_models.dart';

// Manages the list of all groups
class GroupNotifier extends StateNotifier<List<Group>> {
  GroupNotifier() : super([]);

  void addGroup(Group group) {
    state = [...state, group];
  }

  void updateGroup(Group updatedGroup) {
    state = [
      for (final g in state)
        if (g.id == updatedGroup.id) updatedGroup else g,
    ];
  }

  void removeGroup(String id) {
    state = state.where((g) => g.id != id).toList();
  }
}

final groupProvider = StateNotifierProvider<GroupNotifier, List<Group>>((ref) {
  return GroupNotifier();
});