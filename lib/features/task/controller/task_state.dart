import '../../task/data/task_model.dart';

class TaskState {
  final List<TaskModel> tasks;
  final bool isLoading;

  TaskState({
    required this.tasks,
    required this.isLoading,
  });

  factory TaskState.initial() {
    return TaskState(tasks: [], isLoading: false);
  }

  TaskState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
