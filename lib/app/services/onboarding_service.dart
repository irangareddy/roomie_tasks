import 'package:roomie_tasks/app/services/services.dart';

class OnboardingService {
  OnboardingService(this._storageService);
  final StorageService _storageService;

  Future<bool> isOnboardingCompleted() async {
    // setOnboardingCompleted();
    return await _storageService.get(StorageKey.onboardingCompleted) as bool? ??
        false;
  }

  Future<void> setOnboardingCompleted() async {
    await _storageService.set(StorageKey.onboardingCompleted, true);
  }
}
