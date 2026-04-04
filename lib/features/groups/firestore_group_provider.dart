import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/firestore_service.dart';

final firestoreServiceProvider =
    Provider((ref) => FirestoreService());

final groupExpensesStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, groupId) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getGroupExpenses(groupId);
});