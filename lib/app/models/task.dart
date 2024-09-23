// lib/app/models/task.dart
import 'package:uuid/uuid.dart';

enum TaskStatus { pending, inProgress, done, skipped, needHelp }

class TaskFrequency {
  const TaskFrequency(this.name, this.timesPerWeek);
  final String name;
  final int timesPerWeek;

  static const daily = TaskFrequency('Daily', 7);
  static const weekly = TaskFrequency('Weekly', 1);
  static const twiceWeekly = TaskFrequency('Twice a week', 2);
  static const thriceWeekly = TaskFrequency('Thrice a week', 3);
  static const monthly = TaskFrequency('Monthly', 0);

  static const List<TaskFrequency> values = [
    daily,
    weekly,
    twiceWeekly,
    thriceWeekly,
    monthly,
  ];

  @override
  String toString() => name;
}

class Task {
  Task({
    required this.name, required this.frequency, String? id,
    this.templateId,
    this.startDate,
    this.endDate,
    this.assignedTo,
    this.status = TaskStatus.pending,
    this.originalAssignee,
  }) : id = id ?? const Uuid().v4();
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      templateId: json['templateId'] as String?,
      name: json['name'] as String,
      frequency: TaskFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => TaskFrequency.weekly,
      ),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      assignedTo: json['assignedTo'] as String?,
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == 'TaskStatus.${json['status']}',
        orElse: () => TaskStatus.pending,
      ),
      originalAssignee: json['originalAssignee'] as String?,
    );
  }

  final String id;
  final String? templateId;
  final String name;
  final TaskFrequency frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  String? assignedTo;
  TaskStatus status;
  String? originalAssignee;

  bool get isAssigned => assignedTo != null;
  bool get isSwapped =>
      assignedTo != originalAssignee && originalAssignee != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'name': name,
      'frequency': frequency.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'assignedTo': assignedTo,
      'status': status.toString().split('.').last,
      'originalAssignee': originalAssignee,
    };
  }

  Task copyWith({
    String? id,
    String? templateId,
    String? name,
    TaskFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? assignedTo,
    TaskStatus? status,
    String? originalAssignee,
  }) {
    return Task(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      originalAssignee: originalAssignee ?? this.originalAssignee,
    );
  }
}
