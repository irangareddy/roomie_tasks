import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/roommate.dart';
import 'package:roomie_tasks/app/providers/rooommate_provider.dart';
import 'package:roomie_tasks/app/providers/theme_provider.dart';
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Roommates'),
          ),
          body: Consumer<RoommateProvider>(
            builder: (context, provider, child) {
              if (provider.roommates.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/no_roommates.svg',
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Your Squad's Missing!",
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          // ignore: lines_longer_than_80_chars
                          'Hit the + and add your roommates to get things done together!',
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 200),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: provider.roommates.length,
                itemBuilder: (context, index) {
                  final roommate = provider.roommates[index];
                  return ListTile(
                    title: Text(
                      roommate.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      roommate.email ?? 'No email',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () => _editRoommate(roommate),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: theme.colorScheme.error,
                          ),
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
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.addTasks),
              child: const Text('Next: Add Tasks'),
            ),
          ),
        );
      },
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
  bool _isLoading = false;

  Future<void> _addRoommate() async {
    if (_nameController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      final roommate = Roommate(
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phoneNumber:
            _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );

      try {
        final success =
            await context.read<RoommateProvider>().addRoommate(roommate);
        if (success) {
          Navigator.pop(context);
        } else {
          _showErrorSnackBar('A roommate with this name already exists.');
        }
      } catch (e) {
        _showErrorSnackBar('An error occurred while adding the roommate.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            onPressed: _isLoading ? null : _addRoommate,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Add Roommate'),
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
