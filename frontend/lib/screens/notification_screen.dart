import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../widgets/app_drawer.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAsRead(),
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchNotifications(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.notifications.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 300), Center(child: Text('No notifications.'))])
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.notifications.length,
                    itemBuilder: (context, index) {
                      final notif = provider.notifications[index];
                      return Card(
                        color: notif['is_read'] == 0 ? Colors.indigo.shade50 : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(notif['message']),
                          subtitle: Text(DateFormat('MMM dd, hh:mm a').format(DateTime.parse(notif['created_at']))),
                          leading: Icon(
                            notif['is_read'] == 0 ? Icons.notifications_active : Icons.notifications_none,
                            color: notif['is_read'] == 0 ? Colors.indigo : Colors.grey,
                          ),
                          onTap: () {
                            if (notif['is_read'] == 0) {
                              provider.markAsRead(id: notif['id']);
                            }
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
