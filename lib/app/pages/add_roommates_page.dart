import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/roommate.dart';
import 'package:roomie_tasks/app/providers/rooommate_provider.dart';
import 'package:roomie_tasks/config/routes/routes.dart';

class AddRoommatesPage extends StatefulWidget {
  const AddRoommatesPage({super.key});

  @override
  State<AddRoommatesPage> createState() => _AddRoommatesPageState();
}

class _AddRoommatesPageState extends State<AddRoommatesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoommateProvider>().loadRoommates();
    });
  }

  void _showAddRoommateSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddRoommateSheet(),
    );
  }

  Future<void> _editRoommate(Roommate roommate) async {
    final result = await showDialog<Roommate>(
      context: context,
      builder: (context) => _EditRoommateDialog(roommate: roommate),
    );

    if (result != null) {
      await context.read<RoommateProvider>().updateRoommate(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roommates'),
      ),
      body: Consumer<RoommateProvider>(
        builder: (context, provider, child) {
          if (provider.roommates.isEmpty) {
            return const Center(child: Text('No roommates added yet.'));
          }
          return ListView.builder(
            itemCount: provider.roommates.length,
            itemBuilder: (context, index) {
              final roommate = provider.roommates[index];
              return ListTile(
                title: Text(roommate.name),
                subtitle: Text(roommate.email ?? 'No email'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editRoommate(roommate),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => provider.deleteRoommate(roommate.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoommateSheet,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () => context.go(AppRoutes.addTasks),
          child: const Text('Next: Add Tasks'),
        ),
      ),
    );
  }
}

class _AddRoommateSheet extends StatefulWidget {
  const _AddRoommateSheet();

  @override
  __AddRoommateSheetState createState() => __AddRoommateSheetState();
}

class __AddRoommateSheetState extends State<_AddRoommateSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _addRoommate() async {
    if (_nameController.text.isNotEmpty) {
      final roommate = Roommate(
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phoneNumber:
            _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );
      final success =
          await context.read<RoommateProvider>().addRoommate(roommate);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A roommate with this name already exists.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addRoommate,
            child: const Text('Add Roommate'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _EditRoommateDialog extends StatefulWidget {
  const _EditRoommateDialog({required this.roommate});

  final Roommate roommate;

  @override
  __EditRoommateDialogState createState() => __EditRoommateDialogState();
}

class __EditRoommateDialogState extends State<_EditRoommateDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.roommate.name);
    _emailController = TextEditingController(text: widget.roommate.email);
    _phoneController = TextEditingController(text: widget.roommate.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Roommate'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            final updatedRoommate = widget.roommate.copyWith(
              name: _nameController.text,
              email: _emailController.text,
              phoneNumber: _phoneController.text,
            );
            Navigator.pop(context, updatedRoommate);
          },
        ),
      ],
    );
  }
}
