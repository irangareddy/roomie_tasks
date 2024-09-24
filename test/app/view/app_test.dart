import 'package:flutter_test/flutter_test.dart';
import 'package:roomie_tasks/app/models/models.dart';

void main() {
  group('Roommate', () {
    test('creates instance with required parameters', () {
      final roommate = Roommate(name: 'John Doe');
      expect(roommate.name, 'John Doe');
      expect(roommate.id, isNotEmpty);
    });

    test('creates instance from JSON', () {
      final json = {
        'id': '123',
        'name': 'Jane Doe',
        'email': 'jane@example.com',
      };
      final roommate = Roommate.fromJson(json);
      expect(roommate.id, '123');
      expect(roommate.name, 'Jane Doe');
      expect(roommate.email, 'jane@example.com');
    });

    test('converts to JSON', () {
      final roommate = Roommate(
        id: '456',
        name: 'Bob Smith',
        email: 'bob@example.com',
      );
      final json = roommate.toJson();
      expect(json['id'], '456');
      expect(json['name'], 'Bob Smith');
      expect(json['email'], 'bob@example.com');
    });

    test('creates copy with new values', () {
      final original = Roommate(name: 'Alice');
      final copy = original.copyWith(email: 'alice@example.com');
      expect(copy.id, original.id);
      expect(copy.name, 'Alice');
      expect(copy.email, 'alice@example.com');
    });
  });

  group('Task', () {
    test('creates instance with required parameters', () {
      final task = Task(name: 'Clean', frequency: TaskFrequency.weekly);
      expect(task.name, 'Clean');
      expect(task.frequency, TaskFrequency.weekly);
      expect(task.id, isNotEmpty);
    });

    test('creates instance from JSON', () {
      final json = {
        'id': '123',
        'name': 'Dishes',
        'frequency': 'Daily',
        'status': 'pending',
      };
      final task = Task.fromJson(json);
      expect(task.id, '123');
      expect(task.name, 'Dishes');
      expect(task.frequency, TaskFrequency.daily);
      expect(task.status, TaskStatus.pending);
    });

    test('converts to JSON', () {
      final task = Task(
        id: '456',
        name: 'Laundry',
        frequency: TaskFrequency.weekly,
        status: TaskStatus.inProgress,
      );
      final json = task.toJson();
      expect(json['id'], '456');
      expect(json['name'], 'Laundry');
      expect(json['frequency'], 'Weekly');
      expect(json['status'], 'inProgress');
    });

    test('creates copy with new values', () {
      final original = Task(name: 'Vacuum', frequency: TaskFrequency.weekly);
      final copy = original.copyWith(status: TaskStatus.done);
      expect(copy.id, original.id);
      expect(copy.name, 'Vacuum');
      expect(copy.frequency, TaskFrequency.weekly);
      expect(copy.status, TaskStatus.done);
    });

    test('isAssigned property', () {
      final task = Task(name: 'Cook', frequency: TaskFrequency.daily);
      expect(task.isAssigned, false);
      task.assignedTo = 'John';
      expect(task.isAssigned, true);
    });

    test('isSwapped property', () {
      final task = Task(
        name: 'Mop',
        frequency: TaskFrequency.weekly,
        assignedTo: 'Alice',
        originalAssignee: 'Alice',
      );
      expect(task.isSwapped, false);
      task.assignedTo = 'Bob';
      expect(task.isSwapped, true);
    });
  });
}
