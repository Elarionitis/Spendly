import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_provider.dart';
import '../auth/auth_provider.dart';
import '../group/group_provider.dart';
import '../../core/models/app_models.dart'; 

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(balanceProvider);
    final groups = ref.watch(groupProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Hi, ${user?.name ?? 'User'}!"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context, ref),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-expense'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(balanceProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceRow(balances['owe'] ?? 0.0, balances['owed'] ?? 0.0),
              const SizedBox(height: 24),
              _buildQuickActions(context, ref),
              const SizedBox(height: 24),
              _buildGroupsSection(context, ref, groups),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF1A3B5D)),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Expense'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/add-expense');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Settlement'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settlement');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                ref,
                icon: Icons.add_card,
                label: 'Add Expense',
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/add-expense'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                ref,
                icon: Icons.group_add,
                label: 'New Group',
                color: Colors.green,
                onTap: () => _showAddGroupDialog(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                ref,
                icon: Icons.handshake,
                label: 'Settle Up',
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/settlement'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, WidgetRef ref, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsSection(BuildContext context, WidgetRef ref, List<Group> groups) {
    if (groups.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No groups yet. Tap + to add one!",
            style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Your Groups", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showAddGroupDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.group_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("No groups yet", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Create a group to start tracking shared expenses",
                    style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddGroupDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Group'),
                  ),
                ],
              ),
            ),
          )
        else
          ...groups.map((group) => _buildGroupCard(context, group, ref)),
      ],
    );
  }

  Widget _buildGroupCard(BuildContext context, Group group, WidgetRef ref) {
    final user = ref.read(authProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showGroupOptions(context, ref, group),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      group.description.isNotEmpty 
                          ? group.description 
                          : '${group.memberIds.length} member${group.memberIds.length != 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupOptions(BuildContext context, WidgetRef ref, Group group) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Add Expense'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add-expense');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Members'),
              onTap: () {
                Navigator.pop(context);
                _showAddMemberDialog(context, ref, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/group-detail');
              },
            ),
            if (group.createdById == ref.read(authProvider)?.id)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Group', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(groupProvider.notifier).removeGroup(group.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref, Group group) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Member Name/Email',
            hintText: 'Enter name or email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final updatedGroup = Group(
                  id: group.id,
                  name: group.name,
                  description: group.description,
                  createdById: group.createdById,
                  memberIds: [...group.memberIds, controller.text.trim()],
                  createdAt: group.createdAt,
                );
                ref.read(groupProvider.notifier).updateGroup(updatedGroup);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Member added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g., Trip to Paris',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g., Summer 2024 vacation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final user = ref.read(authProvider);
                final newGroup = Group(
                  id: 'g${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  createdById: user?.id ?? 'unknown',
                  memberIds: [user?.id ?? 'unknown'],
                  createdAt: DateTime.now(),
                );
                ref.read(groupProvider.notifier).addGroup(newGroup);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(double owe, double owed) {
    return Row(
      children: [
        Expanded(child: Card(child: ListTile(title: const Text("Owe"), subtitle: Text("\$$owe", style: const TextStyle(color: Colors.red))))),
        const SizedBox(width: 10),
        Expanded(child: Card(child: ListTile(title: const Text("Owed"), subtitle: Text("\$$owed", style: const TextStyle(color: Colors.green))))),
      ],
    );
  }
}