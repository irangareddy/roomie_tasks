import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/pages/add_roommates_page.dart';
import 'package:roomie_tasks/app/pages/add_tasks_page.dart';
import 'package:roomie_tasks/app/pages/googlesheets_setup_page.dart';
import 'package:roomie_tasks/app/pages/onboarding/splash_screen.dart';
import 'package:roomie_tasks/app/pages/settings_page.dart';
import 'package:roomie_tasks/app/pages/stats_page.dart';
import 'package:roomie_tasks/app/pages/task_detail_page.dart';
import 'package:roomie_tasks/app/pages/task_list_page.dart';
import 'package:roomie_tasks/app/providers/googlesheets_setup_provider.dart';
import 'package:roomie_tasks/app/services/onboarding_service.dart';
import 'package:roomie_tasks/dependency_manager.dart';

class AppRoutes {
  static const splash = '/splash';
  static const googleSheetsSetup = '/google-sheet-setup';
  static const addRoommates = '/add-roommates';
  static const addTasks = '/add-tasks';
  static const taskList = '/task-list';
  static const settings = '/settings';
  static const stats = '/stats';
  static const taskDetail = '/task-detail';
}

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
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
      path: AppRoutes.taskDetail,
      builder: (context, state) {
        final task = state.extra! as Task;
        return TaskDetailPage(task: task);
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.stats,
      builder: (context, state) => const StatsPage(),
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) async {
    final onboardingService = sl<OnboardingService>();
    final isOnboardingCompleted = await onboardingService.isOnboardingCompleted();

    if (!isOnboardingCompleted) {
      return AppRoutes.splash;
    }

    // Remove the Google Sheets setup check from here
    if (state.uri.toString() == AppRoutes.splash) {
      return AppRoutes.taskList;
    }

    // In all other cases, don't redirect
    return null;
  },
);
