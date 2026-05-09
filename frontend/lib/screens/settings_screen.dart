import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSection(context, auth),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            context,
            'Preferences',
            [
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: theme.isDarkMode,
                  onChanged: (v) => theme.toggleTheme(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            context,
            'Security',
            [
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Change Password'),
                onTap: () => _showChangePasswordDialog(context, auth),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            context,
            'App Info',
            [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version'),
                trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout),
              label: const Text('LOGOUT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, AuthProvider auth) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.indigo,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.user?['name'] ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(auth.user?['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                  Text(auth.user?['phone'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 16),
            TextField(controller: newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // Note: Add API call here via Provider
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated (Simulation)')));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
