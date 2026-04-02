import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/group.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_provider.dart';
import 'group_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class AddGroupScreen extends ConsumerStatefulWidget {
  const AddGroupScreen({super.key});

  @override
  ConsumerState<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends ConsumerState<AddGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedEmoji = '👥';
  final List<String> _selectedMemberIds = [];

  final List<String> _emojis = [
    '👥', '🏖️', '🏠', '🍱', '✈️', '🎉', '💼', '🎓', '🏃', '🎮',
    '🍕', '🎵', '🏕️', '🌍', '💊',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final allUsers = ref.watch(usersDataProvider);
    final otherUsers = allUsers.where((u) => u.id != currentUser?.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji Picker
            Text('Pick an icon',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) {
                final isSelected = e == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SpendlyColors.primary.withAlpha(20)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: SpendlyColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Name
            Text('Group Name',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g., Goa Trip 2025'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // Description
            Text('Description (optional)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(hintText: 'What is this group for?'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Members
            Text('Add Members',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('You will be added automatically.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SpendlyColors.neutral500)),
            const SizedBox(height: 12),
            ...otherUsers.map((u) {
              final isSelected = _selectedMemberIds.contains(u.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedMemberIds.add(u.id);
                    } else {
                      _selectedMemberIds.remove(u.id);
                    }
                  });
                },
                secondary: UserAvatar(name: u.name, userId: u.id),
                title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(u.email),
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            }),
            const SizedBox(height: 32),

            GestureDetector(
              onTap: _createGroup,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: SpendlyColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: SpendlyColors.primary.withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Create Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createGroup() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    final user = ref.read(authProvider);
    final group = Group(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      createdById: user?.id ?? 'u1',
      memberIds: [user?.id ?? 'u1', ..._selectedMemberIds],
      createdAt: DateTime.now(),
      emoji: _selectedEmoji,
    );
    ref.read(groupProvider.notifier).addGroup(group);
    context.go('/groups/${group.id}');
  }
}
