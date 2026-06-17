class Quiz {
  final String id;
  final String moduleId;
  final String title;
  final int passingScore;
  final int maxAttempts;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.passingScore,
    required this.maxAttempts,
    this.questions = const [],
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    var questionsList = <Question>[];
    if (json['questions'] != null) {
      questionsList = (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    return Quiz(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      title: json['title'] as String,
      passingScore: json['passing_score'] as int? ?? 70,
      maxAttempts: json['max_attempts'] as int? ?? 3,
      questions: questionsList,
    );
  }
}

class Question {
  final String id;
  final String quizId;
  final String questionText;
  final String questionType;
  final int orderIndex;
  final List<Answer> answers;

  Question({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    required this.orderIndex,
    this.answers = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var answersList = <Answer>[];
    if (json['answers'] != null) {
      answersList = (json['answers'] as List)
          .map((a) => Answer.fromJson(a))
          .toList();
      // Opcional: desordenar las respuestas (shuffle) aquí si se desea
    }

    return Question(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String? ?? 'multiple_choice',
      orderIndex: json['order_index'] as int? ?? 0,
      answers: answersList,
    );
  }
}

class Answer {
  final String id;
  final String questionId;
  final String answerText;
  final bool isCorrect;
  final String? feedbackText;

  Answer({
    required this.id,
    required this.questionId,
    required this.answerText,
    required this.isCorrect,
    this.feedbackText,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      answerText: json['answer_text'] as String,
      isCorrect: json['is_correct'] as bool? ?? false,
      feedbackText: json['feedback_text'] as String?,
    );
  }
}
