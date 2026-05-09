import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'themes/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/notification_service.dart';
import 'package:workmanager/workmanager.dart';

const taskName = "hourlyReminderTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // This runs in the background
    await NotificationService.init();
    await NotificationService.showNotification(
      999,
      "Task Reminder",
      "Check your pending tasks for today!",
    );
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.init();
  
  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: const Duration(hours: 1),
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, auth, theme, _) {
        return MaterialApp(
          key: ValueKey(auth.isAuthenticated), // Force rebuild on auth change
          title: 'Task Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: auth.isAuthenticated ? const DashboardScreen() : const LoginScreen(),
        );
      },
    );
  }
}
