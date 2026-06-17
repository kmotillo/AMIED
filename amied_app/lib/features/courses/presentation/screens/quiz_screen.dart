// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/quiz_repository.dart';
import '../../domain/quiz.dart';
import '../../../gamification/data/gamification_repository.dart';
import '../providers/progress_providers.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String moduleId;

  const QuizScreen({super.key, required this.courseId, required this.moduleId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  // Mapa de questionId a answerId
  final Map<String, String> _selectedAnswers = {};
  
  // Estado local para arrastrar y soltar: questionId -> { concept: definition }
  final Map<String, Map<String, String>> _matchedPairs = {};

  bool _isSubmitted = false;
  int _finalScore = 0;
  bool _passed = false;
  bool _isSaving = false;

  void _submitQuiz(Quiz quiz) async {
    // Validar que respondió todo
    int answeredCount = _selectedAnswers.values.where((v) => v.trim().isNotEmpty).length;
    if (answeredCount < quiz.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, responde todas las preguntas.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    int correctAnswers = 0;
    for (var question in quiz.questions) {
      final selectedAnswerId = _selectedAnswers[question.id];
      if (selectedAnswerId == null) continue;

      if (question.questionType == 'match_pairs') {
        if (selectedAnswerId == 'MATCHED_CORRECTLY') {
          correctAnswers++;
        }
      } else if (question.questionType == 'fill_in_the_blank') {
        final userInput = selectedAnswerId.trim().toLowerCase();
        bool isCorrect = false;
        for (var a in question.answers) {
          if (userInput == a.answerText.trim().toLowerCase()) {
            isCorrect = true;
            break;
          }
        }
        if (isCorrect) correctAnswers++;
      } else if (question.questionType == 'match_pairs') {
        final currentMatches = _matchedPairs[question.id];
        if (currentMatches != null && currentMatches.length == question.answers.length) {
          bool isCorrect = true;
          for (var a in question.answers) {
            final parts = a.answerText.split('|');
            final concept = parts[0].trim();
            final definition = parts.length > 1 ? parts.sublist(1).join('|').trim() : '';
            if (currentMatches[concept] != definition) {
              isCorrect = false;
              break;
            }
          }
          if (isCorrect) correctAnswers++;
        }
      } else {
        try {
          final answer = question.answers.firstWhere((a) => a.id == selectedAnswerId);
          if (answer.isCorrect) {
            correctAnswers++;
          }
        } catch (e) {
          // Si no encuentra la respuesta, no suma
        }
      }
    }

    _finalScore = ((correctAnswers / quiz.questions.length) * 100).round();
    _passed = _finalScore >= quiz.passingScore;

    try {
      final repo = ref.read(quizRepositoryProvider);
      await repo.saveQuizAttempt(
        quizId: quiz.id,
        score: _finalScore,
        passed: _passed,
      );
      
      // Refrescar el estado de gamificación y progreso
      ref.invalidate(userGamificationProvider);
      ref.invalidate(userBadgesProvider);
      ref.invalidate(passedModulesWithQuizzesProvider);

      setState(() {
        _isSubmitted = true;
        _isSaving = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Icon(
              _passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 80,
              color: _passed ? Colors.amber : Colors.red,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _passed ? '¡Felicidades!' : 'Sigue intentándolo',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  _passed 
                    ? 'Has aprobado la evaluación con $_finalScore% y has ganado puntos de experiencia.'
                    : 'No alcanzaste el puntaje mínimo de ${quiz.passingScore}%. Obtuviste $_finalScore%.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (_passed) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Widget _buildTrueFalseCard(int number, Question question, bool isQuestionAnswered, String? selectedAnswerId, bool isEnrolled) {
    if (isQuestionAnswered || _isSubmitted) {
      // Mostrar la respuesta seleccionada
      final answer = selectedAnswerId != null ? question.answers.firstWhere((a) => a.id == selectedAnswerId) : null;
      
      Color cardColor = Colors.white;
      if (_isSubmitted && answer != null) {
        cardColor = answer.isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1);
      } else if (isQuestionAnswered) {
        cardColor = Colors.blue.withValues(alpha: 0.05);
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 24),
        color: cardColor,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$number. ${question.questionText}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (answer != null)
                Row(
                  children: [
                    Icon(
                      answer.answerText.toLowerCase() == 'verdadero' ? Icons.check_circle : Icons.cancel,
                      color: answer.answerText.toLowerCase() == 'verdadero' ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text('Tu respuesta: ${answer.answerText}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    if (!_isSubmitted && isEnrolled)
                      TextButton.icon(
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Deshacer'),
                        onPressed: () {
                          setState(() {
                            _selectedAnswers.remove(question.id);
                          });
                        },
                      ),
                  ],
                ),
              if (_isSubmitted && answer != null && answer.feedbackText != null && answer.feedbackText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(answer.feedbackText!, style: const TextStyle(color: Colors.blue))),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      );
    }

    // Modo interactivo (Swipe)
    final answerTrue = question.answers.firstWhere((a) => a.answerText.toLowerCase() == 'verdadero', orElse: () => question.answers[0]);
    final answerFalse = question.answers.firstWhere((a) => a.answerText.toLowerCase() == 'falso', orElse: () => question.answers.length > 1 ? question.answers[1] : question.answers[0]);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. Desliza para responder:', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Dismissible(
            key: ValueKey('${question.id}_dismissible'),
            direction: isEnrolled ? DismissDirection.horizontal : DismissDirection.none,
            onDismissed: (direction) {
              setState(() {
                if (direction == DismissDirection.startToEnd) {
                  _selectedAnswers[question.id] = answerTrue.id;
                } else {
                  _selectedAnswers[question.id] = answerFalse.id;
                }
              });
            },
            background: Container(
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Row(
                children: [
                  Icon(Icons.check, color: Colors.white, size: 32),
                  SizedBox(width: 8),
                  Text('VERDADERO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            secondaryBackground: Container(
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('FALSO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(width: 8),
                  Icon(Icons.close, color: Colors.white, size: 32),
                ],
              ),
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  question.questionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchPairsCard(int number, Question question, bool isQuestionAnswered, String? selectedAnswerId, bool isEnrolled) {
    if (!_matchedPairs.containsKey(question.id)) {
      _matchedPairs[question.id] = {};
    }
    
    final currentMatches = _matchedPairs[question.id]!;
    
    // Parse concepts and definitions
    final List<String> allConcepts = [];
    final List<String> allDefinitions = [];
    final Map<String, String> correctMap = {};
    
    for (var a in question.answers) {
      final parts = a.answerText.split('|');
      final concept = parts[0].trim();
      final definition = parts.length > 1 ? parts.sublist(1).join('|').trim() : '';
      allConcepts.add(concept);
      allDefinitions.add(definition);
      correctMap[concept] = definition;
    }
    
    final List<String> availableConcepts = allConcepts.where((c) => !currentMatches.containsKey(c)).toList();
    availableConcepts.sort((a, b) => a.length.compareTo(b.length)); // Deterministic scramble
    
    bool isCompletedLocally = currentMatches.length == allConcepts.length;
    
    // Evaluate if correct when submitted
    bool isTotallyCorrect = false;
    if (_isSubmitted && isCompletedLocally) {
      isTotallyCorrect = true;
      for (var c in allConcepts) {
        if (currentMatches[c] != correctMap[c]) {
          isTotallyCorrect = false;
          break;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      color: (_isSubmitted && isTotallyCorrect) ? Colors.green.withValues(alpha: 0.1) : (_isSubmitted ? Colors.red.withValues(alpha: 0.1) : Colors.white),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$number. ${question.questionText}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Arrastra cada concepto hacia su definición correcta.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            
            if (_isSubmitted && !isTotallyCorrect)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Hay emparejamientos incorrectos.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              
            // Definitions as DragTargets
            ...allDefinitions.map((def) {
              final matchedConceptsList = currentMatches.entries.where((e) => e.value == def).map((e) => e.key).toList();
              final matchedConcept = matchedConceptsList.isNotEmpty ? matchedConceptsList.first : null;
              
              return DragTarget<String>(
                onWillAcceptWithDetails: (details) {
                  return isEnrolled && !_isSubmitted; // Accept anytime if enrolled and not submitted
                },
                onAcceptWithDetails: (details) {
                  final draggedConcept = details.data;
                  setState(() {
                    // Remover concepto previo si este slot ya tenía uno
                    currentMatches.removeWhere((k, v) => v == def);
                    
                    currentMatches[draggedConcept] = def;
                    if (currentMatches.length == allConcepts.length) {
                      _selectedAnswers[question.id] = 'ANSWERED';
                    } else {
                      _selectedAnswers.remove(question.id);
                    }
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  Color slotBgColor = matchedConcept != null ? Colors.blue.withValues(alpha: 0.1) : (candidateData.isNotEmpty ? Colors.blue.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1));
                  Color slotBorderColor = matchedConcept != null ? Colors.blue : (candidateData.isNotEmpty ? Colors.blue : Colors.grey.shade300);
                  Color badgeBgColor = matchedConcept != null ? Colors.blue : Colors.white;
                  Color badgeBorderColor = matchedConcept != null ? Colors.blue : Colors.grey.shade300;
                  
                  if (_isSubmitted && matchedConcept != null) {
                    final isRight = correctMap[matchedConcept] == def;
                    slotBgColor = isRight ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1);
                    slotBorderColor = isRight ? Colors.green : Colors.red;
                    badgeBgColor = isRight ? Colors.green : Colors.red;
                    badgeBorderColor = isRight ? Colors.green : Colors.red;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: slotBgColor,
                      border: Border.all(color: slotBorderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(def, style: const TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              border: Border.all(
                                color: badgeBorderColor, 
                                style: matchedConcept != null ? BorderStyle.solid : BorderStyle.none
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                matchedConcept ?? 'Arrastra aquí',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: matchedConcept != null ? Colors.white : Colors.grey,
                                  fontWeight: matchedConcept != null ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
            
            const SizedBox(height: 16),
            
            // Available concepts as Draggables
            if (availableConcepts.isNotEmpty && !_isSubmitted)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableConcepts.map((concept) {
                  return Draggable<String>(
                    data: concept,
                    feedback: Material(
                      elevation: 4,
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: Text(concept, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    childWhenDragging: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                      child: Text(concept, style: const TextStyle(color: Colors.grey)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                      child: Text(concept, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
              
            if (currentMatches.isNotEmpty && !_isSubmitted && isEnrolled)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reiniciar Parejas'),
                  onPressed: () {
                    setState(() {
                      _matchedPairs[question.id]!.clear();
                      _selectedAnswers.remove(question.id);
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFillInTheBlanksCard(int number, Question question, bool isQuestionAnswered, String? selectedAnswerId, bool isEnrolled) {
    bool isCorrect = false;
    String feedback = '';
    
    if (_isSubmitted) {
      final userInput = selectedAnswerId?.trim().toLowerCase() ?? '';
      
      for (var a in question.answers) {
        if (userInput == a.answerText.trim().toLowerCase()) {
          isCorrect = true;
          if (a.feedbackText != null && a.feedbackText!.isNotEmpty) {
            feedback = a.feedbackText!;
          }
          break;
        }
      }
      
      if (!isCorrect && question.answers.isNotEmpty) {
         final firstAns = question.answers.first;
         if (firstAns.feedbackText != null && firstAns.feedbackText!.isNotEmpty) {
           feedback = firstAns.feedbackText!;
         }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      color: _isSubmitted ? (isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)) : Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$number. ${question.questionText.replaceAll('___', '______')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (!_isSubmitted && isEnrolled)
              TextFormField(
                initialValue: _selectedAnswers[question.id] ?? '',
                decoration: InputDecoration(
                  hintText: 'Escribe tu respuesta...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (val) {
                  _selectedAnswers[question.id] = val;
                },
              ),
            
            if (_isSubmitted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Text('Tu respuesta: ${selectedAnswerId != null && selectedAnswerId.isNotEmpty ? selectedAnswerId : "Ninguna"}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              if (!isCorrect) ...[
                const SizedBox(height: 8),
                Text('Respuestas válidas: ${question.answers.map((e) => e.answerText).join(', ')}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
              if (feedback.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feedback, style: const TextStyle(color: Colors.blue))),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizAsyncValue = ref.watch(moduleQuizProvider(widget.moduleId));
    final passedModulesAsync = ref.watch(passedModulesWithQuizzesProvider);
    final isEnrolledAsync = ref.watch(isEnrolledProvider(widget.courseId));
    final isEnrolled = isEnrolledAsync.value ?? false;
    
    final int? previousScore = passedModulesAsync.maybeWhen(
      data: (map) => map[widget.moduleId],
      orElse: () => null,
    );
    final bool hasPreviouslyPassed = previousScore != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: quizAsyncValue.when(
        data: (quiz) {
          if (quiz == null) {
            return const Center(child: Text('Este módulo no tiene evaluación.'));
          }

          if (quiz.questions.isEmpty) {
            return const Center(child: Text('La evaluación no tiene preguntas configuradas.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                quiz.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Puntaje para aprobar: ${quiz.passingScore}%',
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 16),
              
              if (hasPreviouslyPassed && !_isSubmitted)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ya aprobaste esta evaluación con $previousScore%. Puedes volver a intentarlo si deseas mejorar tu puntaje, pero no recibirás puntos de experiencia adicionales.',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 16),
              
              if (!isEnrolled)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Debes inscribirte en el curso para poder enviar esta evaluación.',
                          style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isSubmitted)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: _passed ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _passed ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _passed ? Icons.check_circle : Icons.cancel,
                        color: _passed ? Colors.green : Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _passed ? '¡Aprobaste!' : 'No alcanzaste el puntaje mínimo.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _passed ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        'Tu puntaje: $_finalScore%',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),

              ...quiz.questions.map((question) {
                final isQuestionAnswered = _selectedAnswers.containsKey(question.id);
                final selectedAnswerId = _selectedAnswers[question.id];
                final questionIndex = quiz.questions.indexOf(question) + 1;
                
                if (question.questionType == 'true_false') {
                  return _buildTrueFalseCard(questionIndex, question, isQuestionAnswered, selectedAnswerId, isEnrolled);
                } else if (question.questionType == 'match_pairs') {
                  return _buildMatchPairsCard(questionIndex, question, isQuestionAnswered, selectedAnswerId, isEnrolled);
                } else if (question.questionType == 'fill_in_the_blank') {
                  return _buildFillInTheBlanksCard(questionIndex, question, isQuestionAnswered, selectedAnswerId, isEnrolled);
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$questionIndex. ${question.questionText}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...question.answers.map((answer) {
                          final isSelected = selectedAnswerId == answer.id;
                          
                          Color? tileColor;
                          if (_isSubmitted) {
                            if (isSelected) {
                              tileColor = answer.isCorrect ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2);
                            } else if (answer.isCorrect) {
                              tileColor = Colors.green.withValues(alpha: 0.1);
                            }
                          }

                          return Container(
                            color: tileColor,
                            child: RadioListTile<String>(
                              title: Text(answer.answerText),
                              value: answer.id,
                              groupValue: selectedAnswerId,
                              onChanged: (_isSubmitted || !isEnrolled) ? null : (value) {
                                setState(() {
                                  _selectedAnswers[question.id] = value!;
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                          );
                        }),

                        if (_isSubmitted && isQuestionAnswered) ...[
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final answered = question.answers.firstWhere((a) => a.id == selectedAnswerId);
                              if (answered.feedbackText != null && answered.feedbackText!.isNotEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          answered.feedbackText!,
                                          style: const TextStyle(color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }),
              
              const SizedBox(height: 24),
              if (!_isSubmitted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isEnrolled ? Colors.grey : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: (_isSaving || !isEnrolled) ? null : () => _submitQuiz(quiz),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enviar Evaluación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver al Curso', style: TextStyle(fontSize: 18)),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
