import 'package:gsheets/gsheets.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/services/service_utils.dart';

class TaskService {
  TaskService(this._tasksSheet);
  final Worksheet _tasksSheet;

  Future<void> initialize() async {
    await ServiceUtils.ensureHeaders(_tasksSheet, [
      'Id',
      'Name',
      'AssignedTo',
      'StartDate',
      'EndDate',
      'Status',
      'OriginalAssignee',
    ]);
  }

  Future<List<Task>> loadTasks() async {
    final rows = await _tasksSheet.values.allRows(fromRow: 2);
    return rows
        .map(
          (row) => Task.fromJson({
            'id': row[0],
            'name': row[1],
            'assignedTo': row[2],
            'startDate': row[3],
            'endDate': row[4],
            'status': row[5],
            'originalAssignee': row[6],
          }),
        )
        .toList();
  }

  Future<void> addTask(Task task) async {
    await _tasksSheet.values.appendRow(_taskToRow(task));
  }

  Future<void> updateTask(Task task) async {
    final rowIndex = await ServiceUtils.findRowIndexById(_tasksSheet, task.id);
    if (rowIndex != null) {
      await _tasksSheet.values.insertRow(rowIndex, _taskToRow(task));
    }
  }

  Future<void> deleteTask(String taskId) async {
    final rowIndex = await ServiceUtils.findRowIndexById(_tasksSheet, taskId);
    if (rowIndex != null) {
      await _tasksSheet.deleteRow(rowIndex);
    }
  }

  List<String> _taskToRow(Task task) {
    return [
      task.id,
      task.name,
      task.assignedTo,
      task.startDate.toIso8601String(),
      task.endDate.toIso8601String(),
      task.status.toString().split('.').last,
      task.originalAssignee,
    ];
  }
}
