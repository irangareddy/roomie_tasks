import 'package:flutter/foundation.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/services/services.dart';

class TaskProvider with ChangeNotifier {
  TaskProvider(this._sheetsService);
  final GoogleSheetsService _sheetsService;

  List<Task> _taskTemplates = [];
  List<Task> _assignedTasks = [];

  List<Task> get taskTemplates => _taskTemplates;
  List<Task> get assignedTasks => _assignedTasks;

  Future<void> loadTaskTemplates() async {
    _taskTemplates = await _sheetsService.taskService.loadTaskTemplates();
    notifyListeners();
  }

  Future<void> loadAssignedTasks() async {
    _assignedTasks = await _sheetsService.taskService.loadAssignedTasks();
    notifyListeners();
  }

  Future<void> addTaskTemplate(Task task) async {
    await _sheetsService.taskService.addTaskTemplate(task);
    _taskTemplates.add(task);
    notifyListeners();
  }

  Future<void> updateTaskTemplate(Task task) async {
    await _sheetsService.taskService.updateTaskTemplate(task);
    final index = _taskTemplates.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _taskTemplates[index] = task;
      notifyListeners();
    }
  }

  Future<void> deleteTaskTemplate(String id) async {
    await _sheetsService.taskService.deleteTaskTemplate(id);
    _taskTemplates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> updateAssignedTask(Task task) async {
    await _sheetsService.taskService.updateAssignedTask(task);
    final index = _assignedTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _assignedTasks[index] = task;
      notifyListeners();
    }
  }

  Future<void> deleteAssignedTask(String id) async {
    await _sheetsService.taskService.deleteAssignedTask(id);
    _assignedTasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> generateWeeklyTasks(
    List<String> roommates,
    DateTime startDate,
  ) async {
    final newTasks = await _sheetsService.taskService
        .generateWeeklyTasks(roommates, startDate);
    _assignedTasks.addAll(newTasks);
    notifyListeners();
  }

  Future<void> swapTask(String taskId, String newAssignee) async {
    final taskIndex = _assignedTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _assignedTasks[taskIndex];
      final updatedTask = Task(
        id: task.id,
        templateId: task.templateId,
        name: task.name,
        frequency: task.frequency,
        startDate: task.startDate,
        endDate: task.endDate,
        assignedTo: newAssignee,
        status: task.status,
        originalAssignee: task.originalAssignee ?? task.assignedTo,
      );
      await updateAssignedTask(updatedTask);
    }
  }

  Future<void> wipeOffAssignedTasks() async {
    await _sheetsService.taskService.wipeOffAssignedTasks();
    _assignedTasks.clear();
    notifyListeners();
  }
}
