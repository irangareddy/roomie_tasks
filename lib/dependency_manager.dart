import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:roomie_tasks/app/providers/providers.dart';
import 'package:roomie_tasks/app/services/services.dart';

final sl = GetIt.instance;

class DependencyManager {
  static Future<void> init() async {
    debugPrint('Started Dependency Manager');
    // Services
    final StorageService hiveStorageService = HiveStorageService();
    await hiveStorageService.init();
    sl
      ..registerSingleton<StorageService>(hiveStorageService)
      ..registerSingleton<GoogleSheetsService>(GoogleSheetsService())
      ..registerSingleton<OnboardingService>(
          OnboardingService(hiveStorageService),)

      // Providers
      ..registerSingleton<GoogleSheetsSetupProvider>(
        GoogleSheetsSetupProvider(sl()),
      )
      ..registerSingleton<RoommateProvider>(RoommateProvider(sl()))
      ..registerSingleton<TaskProvider>(TaskProvider(sl()));
  }
}
