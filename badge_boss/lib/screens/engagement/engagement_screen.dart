import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/engagement.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';

class EngagementScreen extends StatefulWidget {
  const EngagementScreen({super.key});

  @override
  State<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends State<EngagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventId = context.read<EventProvider>().selectedEvent?.id;
      if (eventId != null) {
        final provider = context.read<EngagementProvider>();
        provider.loadPolls(eventId);
        provider.loadQuestions(eventId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EngagementProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Engagement'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Polls'),
            Tab(text: 'Q&A'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _PollsTab(polls: provider.activePolls),
                _QATab(questions: provider.visibleQuestions),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreatePollDialog(context);
          } else {
            _showAskQuestionDialog(context);
          }
        },
        icon: Icon(
            _tabController.index == 0 ? Icons.poll : Icons.question_answer),
        label: Text(_tabController.index == 0 ? 'New Poll' : 'Ask Question'),
      ),
    );
  }

  void _showCreatePollDialog(BuildContext context) {
    final questionController = TextEditingController();
    final option1Controller = TextEditingController();
    final option2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Live Poll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: questionController,
              decoration: const InputDecoration(
                  labelText: 'Question', hintText: 'e.g. Rate this session'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: option1Controller,
              decoration: const InputDecoration(labelText: 'Option 1'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: option2Controller,
              decoration: const InputDecoration(labelText: 'Option 2'),
            ),
            const SizedBox(height: 8),
            const Text('Simple 2-option poll for demo',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (questionController.text.isEmpty) return;

              final eventId =
                  context.read<EventProvider>().selectedEvent?.id ?? 'demo';
              final poll = Poll(
                id: const Uuid().v4(),
                eventId: eventId,
                question: questionController.text,
                type: PollType.singleChoice,
                options: [option1Controller.text, option2Controller.text],
                status: PollStatus.active,
                createdAt: DateTime.now(),
                results: {option1Controller.text: 0, option2Controller.text: 0},
              );

              context.read<EngagementProvider>().createPoll(poll);
              Navigator.pop(context);
            },
            child: const Text('Launch Poll'),
          ),
        ],
      ),
    );
  }

  void _showAskQuestionDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ask a Question'),
        content: TextField(
          controller: textController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Your Question',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isEmpty) return;

              final eventId =
                  context.read<EventProvider>().selectedEvent?.id ?? 'demo';
              final user = context.read<AuthProvider>().currentUser;

              final question = Question(
                id: const Uuid().v4(),
                eventId: eventId,
                authorName: user?.displayName ?? 'Anonymous',
                authorId: user?.id ?? 'anon',
                text: textController.text,
                createdAt: DateTime.now(),
              );

              context.read<EngagementProvider>().submitQuestion(question);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _PollsTab extends StatelessWidget {
  final List<Poll> polls;

  const _PollsTab({required this.polls});

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      return const Center(child: Text('No active polls'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: polls.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _PollCard(poll: polls[index]);
      },
    );
  }
}

class _PollCard extends StatelessWidget {
  final Poll poll;

  const _PollCard({required this.poll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVotes = poll.totalVotes;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(poll.question,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 16),
            ...poll.results.entries.map((entry) {
              final percentage =
                  totalVotes > 0 ? entry.value / totalVotes : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                            '${entry.value} votes (${(percentage * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage == 0 ? 0.01 : percentage,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text('$totalVotes total votes',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QATab extends StatelessWidget {
  final List<Question> questions;

  const _QATab({required this.questions});

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Center(child: Text('No questions yet. Be the first!'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _QuestionCard(question: questions[index]);
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;

  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: () {
                    context
                        .read<EngagementProvider>()
                        .upvoteQuestion(question.id);
                  },
                ),
                Text('${question.upvotes}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(question.authorName[0],
                            style: const TextStyle(fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      Text(question.authorName,
                          style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('•',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.3))),
                      const SizedBox(width: 8),
                      Text('2m ago',
                          style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12)),
                      const Spacer(),
                      if (question.isAnswered)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('ANSWERED',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(question.text, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
