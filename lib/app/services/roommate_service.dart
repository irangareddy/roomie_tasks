import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:roomie_tasks/app/models/roommate.dart';
import 'package:roomie_tasks/app/services/service_utils.dart';
import 'package:roomie_tasks/app/services/task_service.dart';

class RoommateService {
  RoommateService(this._roommatesSheet);
  final Worksheet _roommatesSheet;
  late TaskService _taskService;

  Future<void> initialize(TaskService taskService) async {
    _taskService = taskService;
    await ServiceUtils.ensureHeaders(_roommatesSheet, [
      'Id',
      'Name',
      'Email',
      'Phone Number',
      'Profile Picture',
    ]);
  }

  Future<List<Roommate>> loadRoommates() async {
    debugPrint('Loading roommates...');
    final rows = await _roommatesSheet.values.allRows(fromRow: 2);
    debugPrint('Loaded ${rows.length} rows');

    return rows.map((row) {
      debugPrint('Processing row: $row');
      return Roommate(
        id: row[0],
        name: row[1],
        email: row.length > 2 ? row[2] : null,
        phoneNumber: row.length > 3 ? row[3] : null,
        profilePictureUrl: row.length > 4 ? row[4] : null,
      );
    }).toList();
  }

  Future<bool> addRoommate(Roommate roommate) async {
    final existingRoommates = await loadRoommates();
    if (existingRoommates.any(
      (r) => r.name.toLowerCase() == roommate.name.toLowerCase(),
    )) {
      return false;
    }

    await _roommatesSheet.values.appendRow(_roommateToRow(roommate));
    await _taskService.reviseSchedule();
    return true;
  }

  Future<void> updateRoommate(Roommate roommate) async {
    final rowIndex = await ServiceUtils.findRowIndexById(
      _roommatesSheet,
      roommate.id,
    );
    if (rowIndex != null) {
      await _roommatesSheet.values.insertRow(
        rowIndex,
        _roommateToRow(roommate),
      );
    }
    await _taskService.reviseSchedule();
  }

  Future<void> deleteRoommate(String id) async {
    final rowIndex = await ServiceUtils.findRowIndexById(_roommatesSheet, id);
    if (rowIndex != null) {
      await _roommatesSheet.deleteRow(rowIndex);
    }
    await _taskService.reviseSchedule();
  }

  List<String> _roommateToRow(Roommate roommate) {
    return [
      roommate.id,
      roommate.name,
      roommate.email ?? '',
      roommate.phoneNumber ?? '',
      roommate.profilePictureUrl ?? '',
    ];
  }
}
