import 'package:gsheets/gsheets.dart';

class ServiceUtils {
  static Future<Worksheet> getOrCreateWorksheet(
    Spreadsheet spreadsheet,
    String title,
  ) async {
    final worksheet = spreadsheet.worksheetByTitle(title);
    return worksheet ?? await spreadsheet.addWorksheet(title);
  }

  static Future<void> ensureHeaders(
    Worksheet sheet,
    List<String> headers,
  ) async {
    final existingHeaders = await sheet.values.row(1);
    if (existingHeaders.isEmpty) {
      await sheet.values.insertRow(1, headers);
    }
  }

  static Future<int?> findRowIndexById(Worksheet sheet, String id) async {
    final column = await sheet.values.column(1, fromRow: 2);
    final rowIndex = column.indexOf(id);
    return rowIndex != -1 ? rowIndex + 2 : null;
  }

  static String generateUniqueId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '$timestamp$random';
  }
}
