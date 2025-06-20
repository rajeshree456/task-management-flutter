import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_app/features/task/controller/task_state.dart';
import '../data/task_model.dart';

final taskControllerProvider =
    StateNotifierProvider<TaskController, TaskState>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) {
    throw Exception("User not logged in");
  }
  return TaskController(user.uid);
});
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class TaskController extends StateNotifier<TaskState> {
  final String userId;
  TaskController(this.userId) : super(TaskState.initial());

  Future<void> getTasks() async {
    try {
      state = state.copyWith(isLoading: true);
      print("Fetching tasks for user: $userId");

      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();

      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('tasks').doc();

    final newTask = TaskModel(
      id: docRef.id,
      title: title,
      description: description,
      isDone: false,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priority: priority,
      userId: userId,
    );
    print('Saving task: ${newTask.toMap()}');

    await docRef.set(newTask.toMap());
    getTasks();
  }

  Future<void> deleteTask(String id) async {
    await FirebaseFirestore.instance.collection('tasks').doc(id).delete();
    getTasks();
  }

  Future<void> updateTask({
    required String id,
    required String newTitle,
    required String newDescription,
    required DateTime newDueDate,
    required String newPriority,
  }) async {
    await FirebaseFirestore.instance.collection('tasks').doc(id).update({
      'title': newTitle,
      'description': newDescription,
      'dueDate': newDueDate.toIso8601String(),
      'priority': newPriority,
    });
    getTasks();
  }

  Future<void> toggleTaskStatus(String id) async {
    final task = state.tasks.firstWhere((t) => t.id == id);
    final updatedStatus = !task.isDone;

    await FirebaseFirestore.instance.collection('tasks').doc(id).update({
      'isDone': updatedStatus,
    });

    getTasks();
  }
}
