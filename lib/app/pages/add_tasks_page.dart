import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gsheets/gsheets.dart';
import 'package:roomie_tasks/config/routes/routes.dart';

class AddTasksPage extends StatefulWidget {
  const AddTasksPage({required this.spreadsheet, super.key});
  final Spreadsheet spreadsheet;

  @override
  State<AddTasksPage> createState() => _AddTasksPageState();
}

class _AddTasksPageState extends State<AddTasksPage> {
  List<Map<String, dynamic>> tasks = [];
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  Worksheet? _worksheet;

  @override
  void initState() {
    super.initState();
    _initWorksheet();
  }

  Future<void> _initWorksheet() async {
    _worksheet = widget.spreadsheet.worksheetByTitle('Tasks');
    _worksheet ??= await widget.spreadsheet.addWorksheet('Tasks');
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (_worksheet == null) return;
    final values = await _worksheet!.values.allRows(fromRow: 2);
    setState(() {
      tasks = values
          .map(
            (row) => {
              'name': row[0],
              'frequency': int.parse(row[1]),
            },
          )
          .toList();
    });
  }

  Future<void> _addTask() async {
    if (_taskNameController.text.isNotEmpty &&
        _frequencyController.text.isNotEmpty &&
        _worksheet != null) {
      final newTask = {
        'name': _taskNameController.text,
        'frequency': int.parse(_frequencyController.text),
      };
      await _worksheet!.values
          .appendRow([newTask['name'], newTask['frequency'].toString()]);
      setState(() {
        tasks.add(newTask);
        _taskNameController.clear();
        _frequencyController.clear();
      });
    }
  }

  Future<void> _removeTask(int index) async {
    if (_worksheet != null) {
      await _worksheet!.deleteRow(
        index + 2,
      ); // +2 because sheet is 1-indexed and we have a header row
      setState(() {
        tasks.removeAt(index);
      });
    }
  }

  Future<void> _editTask(int index) async {
    _taskNameController.text = tasks[index]['name'] as String;
    _frequencyController.text = tasks[index]['frequency'].toString();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskNameController,
              decoration: const InputDecoration(labelText: 'Task Name'),
            ),
            TextField(
              controller: _frequencyController,
              decoration:
                  const InputDecoration(labelText: 'Frequency (in days)'),
              keyboardType: TextInputType.number,
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
            onPressed: () => Navigator.pop(context, {
              'name': _taskNameController.text,
              'frequency': int.parse(_frequencyController.text),
            }),
          ),
        ],
      ),
    );

    if (result != null) {
      await _worksheet!.values.insertRow(
        index + 2,
        [result['name'], result['frequency'].toString()],
      );
      setState(() {
        tasks[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tasks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _taskNameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _frequencyController,
              decoration: const InputDecoration(
                labelText: 'Frequency (in days)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addTask,
              child: const Text('Add Task'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(tasks[index]['name'] as String),
                    subtitle: Text('Every ${tasks[index]['frequency']} days'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editTask(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeTask(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: tasks.isNotEmpty
                  ? () => context.go(AppRoutes.addRoommates,
                      extra: widget.spreadsheet,)
                  : null,
              child: const Text('Next: View Task List'),
            ),
          ],
        ),
      ),
    );
  }
}
