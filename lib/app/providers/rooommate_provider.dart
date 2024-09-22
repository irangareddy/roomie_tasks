import 'package:flutter/foundation.dart';
import 'package:roomie_tasks/app/models/roommate.dart';
import 'package:roomie_tasks/app/services/googlesheets_service.dart';

class RoommateProvider with ChangeNotifier {
  RoommateProvider(this._sheetsService);
  final GoogleSheetsService _sheetsService;
  List<Roommate> _roommates = [];

  List<Roommate> get roommates => _roommates;

  Future<void> loadRoommates() async {
    _roommates = await _sheetsService.roommateService.loadRoommates();
    notifyListeners();
  }

  Future<bool> addRoommate(Roommate roommate) async {
    final success = await _sheetsService.roommateService.addRoommate(roommate);
    if (success) {
      _roommates.add(roommate);
      notifyListeners();
    }
    return success;
  }

  Future<void> updateRoommate(Roommate roommate) async {
    await _sheetsService.roommateService.updateRoommate(roommate);
    final index = _roommates.indexWhere((r) => r.id == roommate.id);
    if (index != -1) {
      _roommates[index] = roommate;
      notifyListeners();
    }
  }

  Future<void> deleteRoommate(String id) async {
    await _sheetsService.roommateService.deleteRoommate(id);
    _roommates.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
