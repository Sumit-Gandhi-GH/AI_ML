import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class OperationsProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters for Kanban columns
  List<Task> get todoTasks =>
      _tasks.where((t) => t.status == TaskStatus.todo).toList();
  List<Task> get inProgressTasks =>
      _tasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<Task> get reviewTasks =>
      _tasks.where((t) => t.status == TaskStatus.review).toList();
  List<Task> get doneTasks =>
      _tasks.where((t) => t.status == TaskStatus.done).toList();

  Future<void> loadTasks(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual Firestore call
      await Future.delayed(const Duration(milliseconds: 500)); // Mock delay

      // Seed some demo data if empty
      if (_tasks.isEmpty) {
        _tasks = [
          Task(
            id: const Uuid().v4(),
            title: 'Finalize Catering Menu',
            description: 'Determine vegan options and confirm headcount.',
            dueDate: DateTime.now().add(const Duration(days: 2)),
            status: TaskStatus.todo,
            priority: TaskPriority.high,
            category: TaskCategory.logistics,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            eventId: eventId,
          ),
          Task(
            id: const Uuid().v4(),
            title: 'Review Keynote Slides',
            description: 'Check for branding compliance.',
            dueDate: DateTime.now().add(const Duration(days: 1)),
            status: TaskStatus.inProgress,
            priority: TaskPriority.critical,
            category: TaskCategory.content,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            eventId: eventId,
          ),
          Task(
            id: const Uuid().v4(),
            title: 'Print Volunteer Badges',
            description: 'Make sure to print extras for walk-ins.',
            dueDate: DateTime.now().add(const Duration(days: 0)),
            status: TaskStatus.todo,
            priority: TaskPriority.medium,
            category: TaskCategory.logistics,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            eventId: eventId,
          ),
          Task(
            id: const Uuid().v4(),
            title: 'Send "Know Before You Go" Email',
            description: 'Include parking info and QR code.',
            dueDate: DateTime.now().subtract(const Duration(days: 1)),
            status: TaskStatus.done,
            priority: TaskPriority.high,
            category: TaskCategory.marketing,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            eventId: eventId,
          ),
        ];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    notifyListeners();
    // TODO: Firestore create
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: newStatus);
      notifyListeners();
      // TODO: Firestore update
    }
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
      // TODO: Firestore update
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    // TODO: Firestore delete
  }
}
