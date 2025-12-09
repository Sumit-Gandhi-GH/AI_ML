enum PollStatus { draft, active, closed }

enum PollType { singleChoice, multiChoice, rating, wordCloud }

class Poll {
  final String id;
  final String eventId;
  final String? sessionId; // Null logic implies event-wide poll
  final String question;
  final PollType type;
  final List<String> options;
  final Map<String, int> results; // Option -> Count
  final PollStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? closedAt;

  Poll({
    required this.id,
    required this.eventId,
    this.sessionId,
    required this.question,
    this.type = PollType.singleChoice,
    this.options = const [],
    this.results = const {},
    this.status = PollStatus.draft,
    required this.createdAt,
    this.publishedAt,
    this.closedAt,
  });

  bool get isActive => status == PollStatus.active;
  int get totalVotes => results.values.fold(0, (sum, count) => sum + count);

  Poll copyWith({
    String? question,
    PollType? type,
    List<String>? options,
    Map<String, int>? results,
    PollStatus? status,
    DateTime? publishedAt,
    DateTime? closedAt,
  }) {
    return Poll(
      id: id,
      eventId: eventId,
      sessionId: sessionId,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      results: results ?? this.results,
      status: status ?? this.status,
      createdAt: createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

class Question {
  final String id;
  final String eventId;
  final String? sessionId;
  final String authorName;
  final String authorId;
  final String text;
  final int upvotes;
  final bool isAnonymous;
  final bool isAnswered;
  final bool isHidden;
  final DateTime createdAt;

  Question({
    required this.id,
    required this.eventId,
    this.sessionId,
    required this.authorName,
    required this.authorId,
    required this.text,
    this.upvotes = 0,
    this.isAnonymous = false,
    this.isAnswered = false,
    this.isHidden = false,
    required this.createdAt,
  });

  Question copyWith({
    int? upvotes,
    bool? isAnswered,
    bool? isHidden,
  }) {
    return Question(
      id: id,
      eventId: eventId,
      sessionId: sessionId,
      authorName: authorName,
      authorId: authorId,
      text: text,
      upvotes: upvotes ?? this.upvotes,
      isAnonymous: isAnonymous,
      isAnswered: isAnswered ?? this.isAnswered,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt,
    );
  }
}
