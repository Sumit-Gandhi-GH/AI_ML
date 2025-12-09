import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../providers/operations_provider.dart';
import '../../providers/event_provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventId = context.read<EventProvider>().selectedEvent?.id;
      if (eventId != null) {
        context.read<OperationsProvider>().loadTasks(eventId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<OperationsProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Operations Command Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Task',
            onPressed: () {
              // TODO: Add Task Dialog
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              final eventId = context.read<EventProvider>().selectedEvent?.id;
              if (eventId != null) provider.loadTasks(eventId);
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KanbanColumn(
                    title: 'TO DO',
                    status: TaskStatus.todo,
                    tasks: provider.todoTasks,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 16),
                  _KanbanColumn(
                    title: 'IN PROGRESS',
                    status: TaskStatus.inProgress,
                    tasks: provider.inProgressTasks,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _KanbanColumn(
                    title: 'DONE',
                    status: TaskStatus.done,
                    tasks: provider.doneTasks,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final TaskStatus status;
  final List<Task> tasks;
  final Color color;

  const _KanbanColumn({
    required this.title,
    required this.status,
    required this.tasks,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 300,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Task List
          Expanded(
            child: DragTarget<Task>(
              onWillAccept: (task) =>
                  task != null &&
                  task.status != status, // Only accept from other cols
              onAccept: (task) {
                context
                    .read<OperationsProvider>()
                    .updateTaskStatus(task.id, status);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? color.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _DraggableTaskCard(task: tasks[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableTaskCard extends StatelessWidget {
  final Task task;

  const _DraggableTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Draggable<Task>(
      data: task,
      feedback: Transform.rotate(
        angle: 0.05,
        child: SizedBox(
          width: 280,
          child: _TaskCard(task: task, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _TaskCard(task: task),
      ),
      child: _TaskCard(task: task),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final bool isDragging;

  const _TaskCard({required this.task, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d');

    return Card(
      elevation: isDragging ? 8 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      surfaceTintColor: theme.colorScheme.surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.category.name.toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (task.priority == TaskPriority.high ||
                    task.priority == TaskPriority.critical)
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: task.priority == TaskPriority.critical
                        ? Colors.purple
                        : Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(task.dueDate),
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11),
                ),
                const Spacer(),
                if (task.assigneeName != null)
                  Tooltip(
                    message: task.assigneeName!,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        task.assigneeName![0].toUpperCase(),
                        style: TextStyle(
                            color: theme.colorScheme.primary, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
