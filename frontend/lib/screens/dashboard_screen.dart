import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/notification_provider.dart';
import 'notification_screen.dart';
import 'task_list_screen.dart';
import 'contact_list_screen.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await Provider.of<TaskProvider>(context, listen: false).fetchDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final stats = taskProvider.dashboardStats;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notif, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, size: 28),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                ),
                if (notif.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('${notif.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(authProvider.user?['name'] ?? 'User'),
              const SizedBox(height: 30),
              (taskProvider.isLoading && stats == null)
                  ? _buildShimmerGrid()
                  : _buildStatsGrid(stats),
              const SizedBox(height: 30),
              if (stats != null) _buildCharts(stats),
              const SizedBox(height: 30),
              const Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildRecentActivity(stats?['recent_tasks']),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back,', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        Text('$name 👋', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Contacts',
          stats['total_contacts'].toString(),
          Icons.people_rounded,
          Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactListScreen())),
        ),
        _buildStatCard(
          'Total Tasks',
          stats['total_tasks'].toString(),
          Icons.assignment_rounded,
          Colors.indigo,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskListScreen(initialIndex: 1))),
        ),
        _buildStatCard(
          'To Others',
          stats['assigned_to_others'].toString(),
          Icons.send_rounded,
          Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskListScreen(initialIndex: 1))),
        ),
        _buildStatCard(
          'To Me',
          stats['assigned_to_me'].toString(),
          Icons.person_pin_rounded,
          Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskListScreen(initialIndex: 0))),
        ),
        _buildStatCard(
          'Follow Ups',
          stats['total_followups'].toString(),
          Icons.calendar_today_rounded,
          Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskListScreen(initialIndex: 3))),
        ),
        _buildStatCard(
          'Pending',
          stats['pending_tasks'].toString(),
          Icons.hourglass_empty_rounded,
          Colors.amber,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskListScreen(initialIndex: 2))),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharts(Map<String, dynamic> stats) {
    int pending = int.tryParse(stats['pending_tasks'].toString()) ?? 0;
    int completed = int.tryParse(stats['completed_tasks'].toString()) ?? 0;
    int total = pending + completed;
    double percentage = total > 0 ? (completed / total * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Task Completion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}% Done',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 8,
                    centerSpaceRadius: 65,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: completed.toDouble(),
                        color: Colors.greenAccent[700],
                        title: '',
                        radius: touchedIndex == 0 ? 30 : 25,
                        badgeWidget: _buildBadge('✅', Colors.greenAccent[700]!),
                        badgePositionPercentageOffset: 1.1,
                      ),
                      PieChartSectionData(
                        value: pending.toDouble(),
                        color: Colors.orangeAccent[400],
                        title: '',
                        radius: touchedIndex == 1 ? 30 : 25,
                        badgeWidget: _buildBadge('⏳', Colors.orangeAccent[400]!),
                        badgePositionPercentageOffset: 1.1,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  Text('Total Tasks', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Completed', Colors.greenAccent[700]!),
              const SizedBox(width: 30),
              _buildLegendItem('Pending', Colors.orangeAccent[400]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String emoji, Color color) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)],
        border: Border.all(color: color, width: 2),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRecentActivity(List<dynamic>? tasks) {
    if (tasks == null || tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text('No recent activity', style: TextStyle(color: Colors.grey))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded, color: Colors.blue, size: 20),
            ),
            title: Text(task['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${task['status']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            trailing: Text(
              task['created_at'].toString().split(' ')[0],
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        children: List.generate(6, (index) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
      ),
    );
  }
}
