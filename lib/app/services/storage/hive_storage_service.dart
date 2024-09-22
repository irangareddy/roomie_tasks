import 'package:hive_flutter/hive_flutter.dart';
import 'package:roomie_tasks/app/services/storage/storage_key.dart';
import 'package:roomie_tasks/app/services/storage/storage_service.dart';

class HiveStorageService implements StorageService {
  // ignore: strict_raw_type
  Box? _hiveBox;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _hiveBox = await Hive.openBox(StorageKey.container);
  }

  @override
  Future<void> remove(String key) async {
    await _hiveBox?.delete(key);
  }

  @override
  dynamic get(String key) {
    return _hiveBox?.get(key);
  }
  @override
  bool has(String key) {
    return _hiveBox?.containsKey(key) ?? false;
  }

  @override
  Future<void> set(String? key, dynamic data) async {
    await _hiveBox?.put(key, data);
  }

  @override
  Future<void> saveIfChanged(
    String key,
    dynamic value,
  ) async {
    final storedValue = await get(key);
    if (storedValue != value) {
      await set(key, value);
    }
  }

  @override
  Future<void> clear() async {
    await _hiveBox?.clear();
  }
}
