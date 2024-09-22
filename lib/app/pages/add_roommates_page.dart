import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gsheets/gsheets.dart';
import 'package:roomie_tasks/config/routes/routes.dart';

class AddRoommatesPage extends StatefulWidget {
  const AddRoommatesPage({required this.spreadsheet, super.key});
  final Spreadsheet spreadsheet;

  @override
  State<AddRoommatesPage> createState() => _AddRoommatesPageState();
}

class _AddRoommatesPageState extends State<AddRoommatesPage> {
  List<String> roommates = [];
  final TextEditingController _roommateController = TextEditingController();
  Worksheet? _worksheet;

  @override
  void initState() {
    super.initState();
    _initWorksheet();
  }

  Future<void> _initWorksheet() async {
    _worksheet = widget.spreadsheet.worksheetByTitle('Roommates');
    _worksheet ??= await widget.spreadsheet.addWorksheet('Roommates');
    await _loadRoommates();
  }

  Future<void> _loadRoommates() async {
    if (_worksheet == null) return;
    final values = await _worksheet!.values.column(1, fromRow: 2);
    setState(() {
      roommates = values;
    });
  }

  Future<void> _addRoommate() async {
    if (_roommateController.text.isNotEmpty && _worksheet != null) {
      await _worksheet!.values.appendRow([_roommateController.text]);
      setState(() {
        roommates.add(_roommateController.text);
        _roommateController.clear();
      });
    }
  }

  Future<void> _removeRoommate(int index) async {
    if (_worksheet != null) {
      await _worksheet!.deleteRow(
        index + 2,
      ); // +2 because sheet is 1-indexed and we have a header row
      setState(() {
        roommates.removeAt(index);
      });
    }
  }

  Future<void> _editRoommate(int index) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Roommate'),
        content: TextField(
          controller: TextEditingController(text: roommates[index]),
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () => Navigator.pop(context, _roommateController.text),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _worksheet!.values.insertValue(result, column: 1, row: index + 2);
      setState(() {
        roommates[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Roommates'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _roommateController,
              decoration: const InputDecoration(
                labelText: 'Roommate Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addRoommate,
              child: const Text('Add Roommate'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: roommates.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(roommates[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editRoommate(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeRoommate(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: roommates.isNotEmpty
                  ? () => context.go(
                        AppRoutes.addTasks,
                        extra: widget.spreadsheet,
                      )
                  : null,
              child: const Text('Next: Add Tasks'),
            ),
          ],
        ),
      ),
    );
  }
}
