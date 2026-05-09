import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/contact_list_screen.dart';
import '../screens/task_list_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(authProvider.user?['name'] ?? 'User'),
            accountEmail: Text(authProvider.user?['email'] ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40),
            ),
            decoration: const BoxDecoration(color: Colors.indigo),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Check if we are already on DashboardScreen
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen(), settings: const RouteSettings(name: '/')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Contacts'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/contacts') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactListScreen(), settings: const RouteSettings(name: '/contacts')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.task),
            title: const Text('Tasks'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/tasks') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TaskListScreen(), settings: const RouteSettings(name: '/tasks')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/settings') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen(), settings: const RouteSettings(name: '/settings')),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              authProvider.logout();
            },
          ),
        ],
      ),
    );
  }
}
