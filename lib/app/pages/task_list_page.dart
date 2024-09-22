import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({required this.spreadsheet, super.key});
  final Spreadsheet spreadsheet;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<Map<String, dynamic>> assignedTasks = [];
  Worksheet? _worksheet;
  List<String> roommates = [];
  List<Map<String, dynamic>> tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWorksheet();
  }

  Future<void> _initWorksheet() async {
    setState(() => _isLoading = true);
    _worksheet = widget.spreadsheet.worksheetByTitle('AssignedTasks');
    if (_worksheet == null) {
      _worksheet = await widget.spreadsheet.addWorksheet('AssignedTasks');
    } else {}
    await _loadRoommates();
    await _loadTasks();
    await _loadAssignedTasks();
    setState(() => _isLoading = false);
    debugPrint('TaskListPage: _initWorksheet completed');
  }

  Future<void> _loadRoommates() async {
    debugPrint('TaskListPage: _loadRoommates started');
    final roommatesSheet = widget.spreadsheet.worksheetByTitle('Roommates');
    if (roommatesSheet != null) {
      final values = await roommatesSheet.values.column(1, fromRow: 2);
      debugPrint('TaskListPage: Roommates loaded: $values');
      setState(() {
        roommates = values;
      });
    } else {
      debugPrint("TaskListPage: 'Roommates' worksheet not found");
    }
  }

  Future<void> _loadTasks() async {
    debugPrint('TaskListPage: _loadTasks started');
    final tasksSheet = widget.spreadsheet.worksheetByTitle('Tasks');
    if (tasksSheet != null) {
      final values = await tasksSheet.values.allRows(fromRow: 2);
      debugPrint('TaskListPage: Tasks loaded: $values');
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
    } else {
      debugPrint("TaskListPage: 'Tasks' worksheet not found");
    }
  }

  Future<void> _loadAssignedTasks() async {
    debugPrint('TaskListPage: _loadAssignedTasks started');
    if (_worksheet == null) {
      debugPrint(
        'TaskListPage: _worksheet is null, cannot load assigned tasks',
      );
      return;
    }

    try {
      final values = await _worksheet!.values.allRows();
      debugPrint('TaskListPage: Raw assigned tasks loaded: $values');

      if (values.isEmpty) {
        debugPrint('TaskListPage: No data found in the worksheet');
        setState(() {
          assignedTasks = [];
        });
        return;
      }

      // Skip the header row if it exists
      // ignore: inference_failure_on_collection_literal
      final dataRows = values.length > 1 ? values.sublist(1) : [];
      debugPrint('TaskListPage: Data rows (excluding header): $dataRows');

      setState(() {
        assignedTasks = dataRows
            .map((row) {
              try {
                return {
                  // ignore: avoid_dynamic_calls
                  'taskName': row[0],
                  // ignore: avoid_dynamic_calls
                  'assignedTo': row[1],
                  // ignore: avoid_dynamic_calls
                  'dueDate': DateTime.parse(row[2] as String),
                  // ignore: avoid_dynamic_calls
                  'status': row[3],
                };
              } catch (e) {
                debugPrint('TaskListPage: Error parsing row: $row. Error: $e');
                return null;
              }
            })
            .where((task) => task != null)
            .cast<Map<String, dynamic>>()
            .toList();
      });

      debugPrint('TaskListPage: Parsed assigned tasks: $assignedTasks');

      if (assignedTasks.isEmpty) {
        debugPrint(
          'TaskListPage: No valid assigned tasks found, calling '
          '_assignTasksToRoommates',
        );
        await _assignTasksToRoommates();
      }
    } catch (e) {
      debugPrint('TaskListPage: Error loading assigned tasks: $e');
      setState(() {
        assignedTasks = [];
      });
    }
  }

  Future<void> _assignTasksToRoommates() async {
    debugPrint('TaskListPage: _assignTasksToRoommates started');
    debugPrint('TaskListPage: Roommates: $roommates');
    debugPrint('TaskListPage: Tasks: $tasks');
    if (roommates.isEmpty || tasks.isEmpty) {
      debugPrint(
        'TaskListPage: Roommates or tasks are empty, cannot assign tasks',
      );
      return;
    }

    final now = DateTime.now();
    var roommateIndex = 0;

    final newTasks = <Map<String, dynamic>>[];

    for (final task in tasks) {
      newTasks.add({
        'taskName': task['name'],
        'assignedTo': roommates[roommateIndex],
        'dueDate': now.add(Duration(days: task['frequency'] as int)),
        'status': 'Pending',
      });

      roommateIndex = (roommateIndex + 1) % roommates.length;
    }

    debugPrint('TaskListPage: New tasks created: $newTasks');

    setState(() {
      assignedTasks = newTasks; // Replace existing tasks instead of adding
    });

    await _saveAssignedTasks();
    debugPrint('TaskListPage: Tasks saved after assignment');
    await _verifySheetContents();
  }

  Future<void> _saveAssignedTasks() async {
    debugPrint('TaskListPage: _saveAssignedTasks started');
    if (_worksheet == null) {
      debugPrint(
        'TaskListPage: _worksheet is null, cannot save assigned tasks',
      );
      return;
    }

    try {
      debugPrint('TaskListPage: Clearing worksheet');
      await _worksheet!.clear();

      debugPrint('TaskListPage: Appending header row');
      await _worksheet!.values
          .appendRow(['Task Name', 'Assigned To', 'Due Date', 'Status']);

      debugPrint('TaskListPage: Saving ${assignedTasks.length} tasks');
      final rows = assignedTasks
          .map(
            (task) => [
              task['taskName'] as String,
              task['assignedTo'] as String,
              (task['dueDate'] as DateTime).toIso8601String(),
              task['status'] as String,
            ],
          )
          .toList();

      await _worksheet!.values.appendRows(rows);

      debugPrint('TaskListPage: All assigned tasks saved to worksheet');

      // Verify that the data was written correctly
      final savedValues = await _worksheet!.values.allRows();
      debugPrint('TaskListPage: Saved values in sheet: $savedValues');
    } catch (e) {
      debugPrint('TaskListPage: Error saving assigned tasks: $e');
    }
  }

  Future<void> _updateTaskStatus(int index, String newStatus) async {
    debugPrint(
      'TaskListPage: _updateTaskStatus called for index $index with '
      'new status $newStatus',
    );
    setState(() {
      assignedTasks[index]['status'] = newStatus;
    });
    await _saveAssignedTasks();
    debugPrint('TaskListPage: Tasks saved after status update');
    await _verifySheetContents();
  }

  Future<void> _verifySheetContents() async {
    debugPrint('TaskListPage: Verifying sheet contents');
    if (_worksheet == null) {
      debugPrint('TaskListPage: _worksheet is null, cannot verify contents');
      return;
    }

    final sheetContents = await _worksheet!.values.allRows();
    debugPrint('TaskListPage: Current sheet contents:');
    for (final row in sheetContents) {
      debugPrint(row as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'TaskListPage: build method called. isLoading: $_isLoading, '
      'assignedTasks count: ${assignedTasks.length}',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : assignedTasks.isEmpty
              ? const Center(
                  child: Text(
                    'No tasks available. Tap the refresh button to generate '
                    'tasks.',
                  ),
                )
              : ListView.builder(
                  itemCount: assignedTasks.length,
                  itemBuilder: (context, index) {
                    final task = assignedTasks[index];
                    return Card(
                      child: ListTile(
                        title: Text(task['taskName'] as String),
                        subtitle: Text(
                          'Assigned to: ${task['assignedTo']}\n'
                          'Due: ${task['dueDate'].toString().split(' ')[0]}',
                        ),
                        trailing: DropdownButton<String>(
                          value: task['status'] as String,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _updateTaskStatus(index, newValue);
                            }
                          },
                          items: <String>[
                            'Pending',
                            'In Progress',
                            'Completed',
                            'Overdue',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          debugPrint('TaskListPage: Refresh button pressed');
          setState(() => _isLoading = true);
          await _loadRoommates(); // Reload roommates
          await _loadTasks(); // Reload tasks
          await _assignTasksToRoommates();
          setState(() => _isLoading = false);
          debugPrint('TaskListPage: Refresh complete, tasks should be saved');
          await _verifySheetContents();
        },
        tooltip: 'Generate New Tasks',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
