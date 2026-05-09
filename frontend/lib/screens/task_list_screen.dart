import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';

class TaskListScreen extends StatefulWidget {
  final int initialIndex;
  const TaskListScreen({super.key, this.initialIndex = 1});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
      Provider.of<AuthProvider>(context, listen: false).fetchAllUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'To Me'),
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Follow Up'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => taskProvider.fetchTasks(search: v),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (v) {
                    taskProvider.fetchTasks(priority: v);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: '', child: Text('All Priorities')),
                    const PopupMenuItem(value: 'hot', child: Text('Hot')),
                    const PopupMenuItem(value: 'warm', child: Text('Warm')),
                    const PopupMenuItem(value: 'cold', child: Text('Cold')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => taskProvider.fetchTasks(search: _searchController.text),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(taskProvider.tasks.where((t) => t['assigned_to'] == auth.user?['id']).toList()),
                  _buildTaskList(taskProvider.tasks),
                  _buildTaskList(taskProvider.tasks.where((t) => t['status'] == 'pending').toList()),
                  _buildTaskList(taskProvider.tasks.where((t) => t['status'] == 'follow_up').toList()),
                  _buildTaskList(taskProvider.tasks.where((t) => t['status'] == 'completed').toList()),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 300), Center(child: Text('No tasks found.'))]);
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            title: Text(task['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Due: ${task['due_date'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(task['due_date'])) : 'No date'}'),
            leading: _getPriorityIcon(task['priority']),
            trailing: _getStatusChip(task['status']),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task['description'] ?? 'No description'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('By: ${task['created_by_name']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('To: ${task['assigned_to_name']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showEditTaskDialog(context, task),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: Colors.blue.shade700,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showStatusUpdateDialog(context, task),
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Update Status'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getPriorityIcon(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'hot':
        return const Icon(Icons.whatshot, color: Colors.red);
      case 'warm':
        return const Icon(Icons.wb_sunny, color: Colors.orange);
      case 'cold':
        return const Icon(Icons.ac_unit, color: Colors.blue);
      default:
        return const Icon(Icons.info_outline, color: Colors.grey);
    }
  }

  Widget _getStatusChip(String? status) {
    Color color = Colors.grey;
    if (status == 'completed') color = Colors.green;
    if (status == 'pending') color = Colors.amber;
    if (status == 'follow_up') color = Colors.purple;

    return Chip(
      label: Text(status?.toUpperCase() ?? 'PENDING', style: const TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: color,
    );
  }

  void _showStatusUpdateDialog(BuildContext context, dynamic task) {
    String selectedStatus = task['status'];
    final commentController = TextEditingController();
    DateTime? nextFollowupDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Task Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: ['pending', 'completed', 'follow_up'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                onChanged: (v) => setDialogState(() => selectedStatus = v!),
              ),
              if (selectedStatus == 'follow_up') ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setDialogState(() => nextFollowupDate = date);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(nextFollowupDate == null ? 'Select Follow-up Date' : DateFormat('MMM dd, yyyy').format(nextFollowupDate!)),
                ),
              ],
              const SizedBox(height: 16),
              TextField(controller: commentController, decoration: const InputDecoration(labelText: 'Comment/Note')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedStatus == 'follow_up' && nextFollowupDate == null) return;
                final success = await Provider.of<TaskProvider>(context, listen: false).updateTask(
                  task['id'],
                  selectedStatus,
                  comment: commentController.text,
                  nextFollowupDate: nextFollowupDate,
                );
                if (success && context.mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, dynamic task) {
    final titleController = TextEditingController(text: task['title']);
    final descController = TextEditingController(text: task['description']);
    DateTime? dueDate = task['due_date'] != null ? DateTime.parse(task['due_date']) : null;
    String selectedPriority = task['priority'] ?? 'warm';
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final users = authProvider.allUsers;
    dynamic selectedUser;
    
    try {
      selectedUser = users.firstWhere((u) => u['id'] == task['assigned_to']);
    } catch (e) {
      if (users.isNotEmpty) selectedUser = users.first;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Task', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 20),
                const Text('Priority', style: TextStyle(fontSize: 12, color: Colors.grey)),
                DropdownButton<String>(
                  value: selectedPriority,
                  isExpanded: true,
                  items: ['hot', 'warm', 'cold'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          _getPriorityIcon(value),
                          const SizedBox(width: 10),
                          Text(value.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedPriority = v!),
                ),
                const SizedBox(height: 20),
                const Text('Assign To', style: TextStyle(fontSize: 12, color: Colors.grey)),
                DropdownButton<dynamic>(
                  value: selectedUser,
                  isExpanded: true,
                  items: users.map((user) {
                    return DropdownMenuItem<dynamic>(
                      value: user,
                      child: Text(user['name']),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedUser = v),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setDialogState(() => dueDate = date);
                    },
                    icon: const Icon(Icons.calendar_today, color: Colors.indigo),
                    label: Text(
                      dueDate == null ? 'Set Due Date' : DateFormat('MMM dd, yyyy').format(dueDate!),
                      style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  // Reusing the existing update logic but with more fields
                  final success = await Provider.of<TaskProvider>(context, listen: false).updateTaskFull({
                    'id': task['id'],
                    'title': titleController.text,
                    'description': descController.text,
                    'due_date': dueDate?.toIso8601String(),
                    'priority': selectedPriority,
                    'assigned_to': selectedUser?['id'],
                  });
                  if (success && context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? dueDate;
    String selectedPriority = 'warm'; // Default to warm
    dynamic selectedUser;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final users = authProvider.allUsers;
    
    // Default to current user
    try {
      selectedUser = users.firstWhere((u) => u['id'] == authProvider.user?['id']);
    } catch (e) {
      if (users.isNotEmpty) selectedUser = users.first;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Task', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 20),
                const Text('Priority', style: TextStyle(fontSize: 12, color: Colors.grey)),
                DropdownButton<String>(
                  value: selectedPriority,
                  isExpanded: true,
                  items: ['hot', 'warm', 'cold'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          _getPriorityIcon(value),
                          const SizedBox(width: 10),
                          Text(value.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedPriority = v!),
                ),
                const SizedBox(height: 20),
                const Text('Assign To', style: TextStyle(fontSize: 12, color: Colors.grey)),
                DropdownButton<dynamic>(
                  value: selectedUser,
                  isExpanded: true,
                  hint: const Text('Select User'),
                  items: users.map((user) {
                    return DropdownMenuItem<dynamic>(
                      value: user,
                      child: Text(user['name']),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedUser = v),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setDialogState(() => dueDate = date);
                    },
                    icon: const Icon(Icons.calendar_today, color: Colors.indigo),
                    label: Text(
                      dueDate == null ? 'Set Due Date' : DateFormat('MMM dd, yyyy').format(dueDate!),
                      style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final success = await Provider.of<TaskProvider>(context, listen: false).createTask({
                    'title': titleController.text,
                    'description': descController.text,
                    'due_date': dueDate?.toIso8601String(),
                    'priority': selectedPriority,
                    'assigned_to': selectedUser?['id'],
                  });
                  if (success && context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
