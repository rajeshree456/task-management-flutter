import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:task_app/features/auth/controller/auth_controller.dart';
import '../../task/controller/task_controller.dart';
import '../../task/data/task_model.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String selectedPriority = 'All';
  String selectedStatus = 'All';
  String searchQuery = '';
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(taskControllerProvider.notifier).getTasks();
    });
  }

  void _confirmDelete(
      BuildContext context, String taskId, TaskController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteTask(taskId);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskControllerProvider);
    final taskController = ref.read(taskControllerProvider.notifier);

    final filteredTasks = taskState.tasks.where((task) {
      final matchesSearch = task.title
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesPriority = selectedPriority == 'All' ||
          (selectedPriority == 'Low' &&
              (task.priority == 'Low' || task.priority.isEmpty)) ||
          task.priority == selectedPriority;

      final matchesStatus = selectedStatus == 'All' ||
          (selectedStatus == 'Completed' && task.isDone) ||
          (selectedStatus == 'Incomplete' && !task.isDone);

      return matchesSearch && matchesPriority && matchesStatus;
    }).toList();

    filteredTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(const Duration(days: 7));

    final todayTasks =
        filteredTasks.where((t) => isSameDay(t.dueDate, today)).toList();
    final tomorrowTasks =
        filteredTasks.where((t) => isSameDay(t.dueDate, tomorrow)).toList();
    final thisWeekTasks = filteredTasks
        .where((t) =>
            t.dueDate.isAfter(today) &&
            t.dueDate.isBefore(endOfWeek) &&
            !isSameDay(t.dueDate, tomorrow))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF6C63FF),
          elevation: 0,
          flexibleSpace: Padding(
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 16, 16, 16),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Let's make progress!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today, ${DateFormat('d MMMM').format(DateTime.now())}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => searchQuery = value),
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search tasks...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.filter_list,
                                color: Colors.black54),
                            onPressed: () => _showFilterBottomSheet(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content:
                              const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        await ref.read(authControllerProvider).signOut();
                        if (!mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login', (route) => false);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: taskState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSection('Today', todayTasks, taskController),
                  buildSection('Tomorrow', tomorrowTasks, taskController),
                  buildSection('This Week', thisWeekTasks, taskController),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showAddTaskDialog(context, taskController),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (ctx) {
        String tempPriority = selectedPriority;
        String tempStatus = selectedStatus;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: tempPriority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: ['All', 'Low', 'Medium', 'High']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() => tempPriority = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tempStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: ['All', 'Completed', 'Incomplete']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() => tempStatus = value!);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedPriority = tempPriority;
                          selectedStatus = tempStatus;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildSection(
      String title, List<TaskModel> tasks, TaskController controller) {
    if (tasks.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...tasks.map((task) => buildStyledTaskCard(task, controller)),
      ],
    );
  }

  Widget buildStyledTaskCard(TaskModel task, TaskController controller) {
    Color backgroundColor;

    switch (task.priority) {
      case 'High':
        backgroundColor = Colors.red.shade100;

        break;
      case 'Medium':
        backgroundColor = Colors.yellow.shade100;

        break;
      case 'Low':
      default:
        backgroundColor = Colors.green.shade100;

        break;
    }

    return Slidable(
      key: ValueKey(task.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          CustomSlidableAction(
            onPressed: (_) => _confirmDelete(context, task.id, controller),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.delete, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _showEditTaskDialog(context, controller, task),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => controller.toggleTaskStatus(task.id),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 2),
                  child: task.isDone
                      ? Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(255, 196, 26, 26),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      : const Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.grey,
                          size: 22,
                        ),
                ),
              ),
              Expanded(
                child: Opacity(
                  opacity: task.isDone ? 0.3 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(task.dueDate),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, TaskController controller) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDueDate = DateTime.now();
    String selectedPriority = 'Low';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Task',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    maxLines: 1,
                    maxLength: 25,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: selectedPriority,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['Low', 'Medium', 'High']
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('Priority: $e'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedPriority = value!);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate.isBefore(now) ||
                                selectedDueDate
                                    .isAfter(now.add(const Duration(days: 7)))
                            ? now
                            : selectedDueDate,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 7)),
                      );
                      if (picked != null) {
                        setState(() => selectedDueDate = picked);
                      }
                    },
                    icon: const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Due: ${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final description = descriptionController.text.trim();
                          if (title.isNotEmpty && description.isNotEmpty) {
                            controller.addTask(
                              title: title,
                              description: description,
                              dueDate: selectedDueDate,
                              priority: selectedPriority,
                            );
                            Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTaskDialog(
      BuildContext context, TaskController controller, TaskModel task) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime selectedDueDate = task.dueDate;
    String selectedPriority =
        ['Low', 'Medium', 'High'].contains(task.priority) &&
                task.priority.isNotEmpty
            ? task.priority
            : 'Low';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Task',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    maxLines: 1,
                    maxLength: 25,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: selectedPriority,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['Low', 'Medium', 'High']
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('Priority: $e'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedPriority = value!);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate.isBefore(now) ||
                                selectedDueDate
                                    .isAfter(now.add(const Duration(days: 7)))
                            ? now
                            : selectedDueDate,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 7)),
                      );
                      if (picked != null) {
                        setState(() => selectedDueDate = picked);
                      }
                    },
                    icon: const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Due: ${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final description = descriptionController.text.trim();
                          if (title.isNotEmpty && description.isNotEmpty) {
                            controller.updateTask(
                              id: task.id,
                              newTitle: title,
                              newDescription: description,
                              newDueDate: selectedDueDate,
                              newPriority: selectedPriority,
                            );
                            Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
