// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/admin_repository.dart';

class QuizEditorScreen extends ConsumerStatefulWidget {
  final String moduleId;
  
  const QuizEditorScreen({super.key, required this.moduleId});

  @override
  ConsumerState<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends ConsumerState<QuizEditorScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  String? _existingQuizId;
  final _titleController = TextEditingController();
  final _passingScoreController = TextEditingController(text: '70');
  final _maxAttemptsController = TextEditingController(text: '3');
  
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final repo = ref.read(adminRepositoryProvider);
    final quizData = await repo.getQuizForModule(widget.moduleId);
    
    if (quizData != null && mounted) {
      setState(() {
        _existingQuizId = quizData['id'];
        _titleController.text = quizData['title'] ?? '';
        _passingScoreController.text = (quizData['passing_score'] ?? 70).toString();
        _maxAttemptsController.text = (quizData['max_attempts'] ?? 3).toString();
        
        final questionsData = quizData['questions'] as List<dynamic>? ?? [];
        _questions = questionsData.map((q) {
          final answersData = q['answers'] as List<dynamic>? ?? [];
          return {
            'question_text': q['question_text'],
            'question_type': q['question_type'],
            'answers': answersData.map((a) => {
              'answer_text': a['answer_text'],
              'is_correct': a['is_correct'],
              'feedback_text': a['feedback_text'],
            }).toList(),
          };
        }).toList();
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _addQuestion(String type) {
    setState(() {
      _questions.add({
        'question_text': '',
        'question_type': type,
        'answers': type == 'true_false' 
            ? [
                {'answer_text': 'Verdadero', 'is_correct': true, 'feedback_text': ''},
                {'answer_text': 'Falso', 'is_correct': false, 'feedback_text': ''},
              ]
            : [
                {'answer_text': '', 'is_correct': false, 'feedback_text': ''},
                {'answer_text': '', 'is_correct': false, 'feedback_text': ''},
              ]
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  void _addAnswerToQuestion(int questionIndex) {
    setState(() {
      final answers = _questions[questionIndex]['answers'] as List<dynamic>;
      answers.add({'answer_text': '', 'is_correct': false, 'feedback_text': ''});
    });
  }

  void _removeAnswerFromQuestion(int questionIndex, int answerIndex) {
    setState(() {
      final answers = _questions[questionIndex]['answers'] as List<dynamic>;
      answers.removeAt(answerIndex);
    });
  }

  void _saveQuiz() async {
    // Validaciones básicas
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El título es requerido')));
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos una pregunta')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.saveQuizForModule(
        moduleId: widget.moduleId,
        existingQuizId: _existingQuizId,
        title: _titleController.text.trim(),
        passingScore: int.tryParse(_passingScoreController.text) ?? 70,
        maxAttempts: int.tryParse(_maxAttemptsController.text) ?? 3,
        questions: _questions,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evaluación guardada exitosamente')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Evaluación', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveQuiz,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detalles del Quiz
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Configuración General', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Título del Quiz', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _passingScoreController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Puntaje Mínimo (ej. 70)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _maxAttemptsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Intentos Máximos', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Preguntas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Preguntas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                PopupMenuButton<String>(
                  onSelected: _addQuestion,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'multiple_choice', child: Text('Opción Múltiple')),
                    const PopupMenuItem(value: 'true_false', child: Text('Verdadero o Falso')),
                  ],
                  child: ElevatedButton.icon(
                    onPressed: null, // Hack to use PopupMenu
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir Pregunta'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._questions.asMap().entries.map((entry) {
              final qIndex = entry.key;
              final q = entry.value;
              return _buildQuestionCard(qIndex, q);
            }),
            
            if (_questions.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No hay preguntas en esta evaluación.'),
              )),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _isSaving ? null : _saveQuiz,
            child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Evaluación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int qIndex, Map<String, dynamic> q) {
    final isTrueFalse = q['question_type'] == 'true_false';
    final answers = q['answers'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Pregunta ${qIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeQuestion(qIndex),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: q['question_text'],
              decoration: const InputDecoration(labelText: 'Enunciado de la pregunta', border: OutlineInputBorder()),
              maxLines: 2,
              onChanged: (val) => q['question_text'] = val,
            ),
            const SizedBox(height: 16),
            const Text('Respuestas:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            ...answers.asMap().entries.map((aEntry) {
              final aIndex = aEntry.key;
              final a = aEntry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Radio<int>(
                      value: aIndex,
                      groupValue: answers.indexWhere((ans) => ans['is_correct'] == true),
                      onChanged: (val) {
                        setState(() {
                          for (var ans in answers) {
                            ans['is_correct'] = false;
                          }
                          answers[val!]['is_correct'] = true;
                        });
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: a['answer_text'],
                        decoration: InputDecoration(
                          hintText: 'Texto de la respuesta',
                          filled: true,
                          fillColor: (a['is_correct'] == true) ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
                        ),
                        readOnly: isTrueFalse,
                        onChanged: (val) => a['answer_text'] = val,
                      ),
                    ),
                    if (!isTrueFalse && answers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => _removeAnswerFromQuestion(qIndex, aIndex),
                      )
                  ],
                ),
              );
            }),
            
            if (!isTrueFalse)
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar opción'),
                onPressed: () => _addAnswerToQuestion(qIndex),
              )
          ],
        ),
      ),
    );
  }
}
