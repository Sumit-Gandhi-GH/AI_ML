import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/engagement.dart';

class EngagementProvider with ChangeNotifier {
  List<Poll> _polls = [];
  List<Question> _questions = [];
  bool _isLoading = false;

  List<Poll> get polls => _polls;
  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;

  List<Poll> get activePolls => _polls.where((p) => p.isActive).toList();
  List<Question> get visibleQuestions =>
      _questions.where((q) => !q.isHidden).toList()
        ..sort((a, b) => b.upvotes.compareTo(a.upvotes)); // Sort by popularity

  // --- Polls ---

  Future<void> loadPolls(String eventId) async {
    _isLoading = true;
    notifyListeners();
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Mock data
    if (_polls.isEmpty) {
      _polls = [
        Poll(
          id: const Uuid().v4(),
          eventId: eventId,
          question: 'How would you rate the keynote?',
          type: PollType.rating,
          status: PollStatus.active,
          createdAt: DateTime.now(),
          results: {'1': 2, '2': 5, '3': 15, '4': 40, '5': 60},
        ),
        Poll(
          id: const Uuid().v4(),
          eventId: eventId,
          question: 'Which break-out session are you attending?',
          type: PollType.singleChoice,
          options: ['AI in Events', 'Sustainable Planning', 'Hybrid Future'],
          status: PollStatus.active,
          createdAt: DateTime.now(),
          results: {
            'AI in Events': 45,
            'Sustainable Planning': 20,
            'Hybrid Future': 35
          },
        ),
      ];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createPoll(Poll poll) async {
    _polls.insert(0, poll);
    notifyListeners();
  }

  Future<void> votePoll(String pollId, String option) async {
    final index = _polls.indexWhere((p) => p.id == pollId);
    if (index != -1) {
      final poll = _polls[index];
      final newResults = Map<String, int>.from(poll.results);
      newResults[option] = (newResults[option] ?? 0) + 1;
      _polls[index] = poll.copyWith(results: newResults);
      notifyListeners();
    }
  }

  Future<void> updatePollStatus(String pollId, PollStatus status) async {
    final index = _polls.indexWhere((p) => p.id == pollId);
    if (index != -1) {
      _polls[index] = _polls[index].copyWith(status: status);
      notifyListeners();
    }
  }

  // --- Q&A ---

  Future<void> loadQuestions(String eventId) async {
    // Mock data
    if (_questions.isEmpty) {
      _questions = [
        Question(
          id: const Uuid().v4(),
          eventId: eventId,
          authorName: 'Sarah J.',
          authorId: 'user1',
          text: 'Will the slides be available after the session?',
          upvotes: 12,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        Question(
          id: const Uuid().v4(),
          eventId: eventId,
          authorName: 'Mike T.',
          authorId: 'user2',
          text: 'How does the new regulation affect small businesses?',
          upvotes: 8,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
    }
    notifyListeners();
  }

  Future<void> submitQuestion(Question question) async {
    _questions.insert(0, question);
    notifyListeners();
  }

  Future<void> upvoteQuestion(String questionId) async {
    final index = _questions.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      _questions[index] =
          _questions[index].copyWith(upvotes: _questions[index].upvotes + 1);
      notifyListeners();
    }
  }

  Future<void> markQuestionAnswered(String questionId) async {
    final index = _questions.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      _questions[index] = _questions[index].copyWith(isAnswered: true);
      notifyListeners();
    }
  }
}
