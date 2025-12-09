import 'package:flutter/material.dart';

enum TaskStatus { todo, inProgress, review, done }

enum TaskPriority { low, medium, high, critical }

enum TaskCategory {
  logistics,
  content,
  marketing,
  sponsorships,
  tech,
  teardown,
  other
}

class Task {
  final String id;
  final String title;
  final String description;
  final String? assigneeId;
  final String? assigneeName; // Denormalized for rapid display
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final TaskCategory category;
  final List<String> comments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String eventId;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.assigneeId,
    this.assigneeName,
    required this.dueDate,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.other,
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.eventId,
  });

  Task copyWith({
    String? title,
    String? description,
    String? assigneeId,
    String? assigneeName,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    TaskCategory? category,
    List<String>? comments,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      comments: comments ?? this.comments,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      eventId: eventId,
    );
  }

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.critical:
        return Colors.purple;
    }
  }

  String get priorityLabel {
    return priority.name.toUpperCase();
  }

  // To/From Map for Firestore (Mock for now or real if integrated)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'dueDate': dueDate.toIso8601String(),
      'status': status.index,
      'priority': priority.index,
      'category': category.index,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'eventId': eventId,
    };
  }

  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      assigneeId: map['assigneeId'],
      assigneeName: map['assigneeName'],
      dueDate: DateTime.parse(map['dueDate']),
      status: TaskStatus.values[map['status'] ?? 0],
      priority: TaskPriority.values[map['priority'] ?? 1],
      category: TaskCategory.values[map['category'] ?? 6],
      comments: List<String>.from(map['comments'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      eventId: map['eventId'],
    );
  }
}
