class TaskModel {
  final String id;
  final String title;
  final String description;
  final bool isDone;
  final DateTime createdAt;
  final DateTime dueDate;
  final String priority;
  final String userId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.createdAt,
    required this.dueDate,
    required this.priority,
    required this.userId,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    return TaskModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isDone: map['isDone'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      dueDate: DateTime.parse(map['dueDate']),
      priority: map['priority'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'userId': userId,
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    bool? isDone,
    DateTime? dueDate,
    String? priority,
    String? userId,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
    );
  }
}
