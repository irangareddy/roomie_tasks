// task.dart
enum TaskStatus {
  pending,
  inProgress,
  done,
  skipped,
  needHelp,
}

class Task {

  Task({
    required this.id,
    required this.name,
    required this.assignedTo,
    required this.startDate,
    required this.endDate,
    this.status = TaskStatus.pending,
  }) : originalAssignee = assignedTo;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      assignedTo: json['assignedTo'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == 'TaskStatus.${json['status']}',
        orElse: () => TaskStatus.pending,
      ),
    );
  }
  String id;
  String name;
  String assignedTo;
  String originalAssignee;
  DateTime startDate;
  DateTime endDate;
  TaskStatus status;

  static Task Function(List<String> e) fromRow = (List<String> e) {
    return Task(
      id: e[0],
      name: e[1],
      assignedTo: e[2],
      startDate: DateTime.parse(e[3]),
      endDate: DateTime.parse(e[4]),
      status: TaskStatus.values.firstWhere(
        (s) => s.toString() == 'TaskStatus.${e[5]}',
        orElse: () => TaskStatus.pending,
      ),
    );
  };

  bool get isSwapped => assignedTo != originalAssignee;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assignedTo': assignedTo,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'originalAssignee': originalAssignee,
    };
  }
}
