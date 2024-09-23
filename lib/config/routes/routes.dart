import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/pages/add_roommates_page.dart';
import 'package:roomie_tasks/app/pages/add_tasks_page.dart';
import 'package:roomie_tasks/app/pages/googlesheets_setup_page.dart';
import 'package:roomie_tasks/app/pages/onboarding/splash_screen.dart';
import 'package:roomie_tasks/app/pages/settings_page.dart';
import 'package:roomie_tasks/app/pages/task_list_page.dart';
import 'package:roomie_tasks/app/providers/googlesheets_setup_provider.dart';
import 'package:roomie_tasks/app/services/onboarding_service.dart';
import 'package:roomie_tasks/dependency_manager.dart';

class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const googleSheetsSetup = '/google-sheet-setup';
  static const addRoommates = '/add-roommates';
  static const addTasks = '/add-tasks';
  static const taskList = '/task-list';
  static const settings = '/settings';
}

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const TaskListPage(),
      redirect: (context, state) async {
        final setupProvider =
            Provider.of<GoogleSheetsSetupProvider>(context, listen: false);
        final isSetupComplete = await setupProvider.isSetupComplete();
        if (!isSetupComplete) {
          return AppRoutes.googleSheetsSetup;
        }
        return AppRoutes.taskList;
      },
    ),
    GoRoute(
      path: AppRoutes.googleSheetsSetup,
      builder: (context, state) => const GoogleSheetsSetupPage(),
    ),
    GoRoute(
      path: AppRoutes.addRoommates,
      builder: (context, state) => const AddRoommatesPage(),
    ),
    GoRoute(
      path: AppRoutes.addTasks,
      builder: (context, state) => const AddTasksPage(),
    ),
    GoRoute(
      path: AppRoutes.taskList,
      builder: (context, state) => const TaskListPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) async {
    final onboardingService = sl<OnboardingService>();
    final isOnboardingCompleted =
        await onboardingService.isOnboardingCompleted();

    // If onboarding is not completed and we're not already on the splash
    // screen, redirect to splash
    if (!isOnboardingCompleted && state.uri.toString() != AppRoutes.splash) {
      return AppRoutes.splash;
    }

    // If onboarding is completed and we're on the splash screen,
    // redirect to home
    if (isOnboardingCompleted && state.uri.toString() == AppRoutes.splash) {
      return AppRoutes.home;
    }

    // In all other cases, don't redirect
    return null;
  },
);
