import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  final String _welcomeText = '''
# ¡Bienvenido/a a MIED!

Te damos la más cordial bienvenida a **MIED (Modelo de Inclusión Educativa para la Diversidad)**, una iniciativa desarrollada por la **Universidad Politécnica Salesiana (UPS)** con el propósito de fortalecer las competencias docentes en educación inclusiva dentro del ámbito universitario.

Esta aplicación ha sido diseñada para acompañarte en el aprendizaje de estrategias, metodologías y buenas prácticas orientadas a la atención de estudiantes con **Necesidades Educativas Específicas (NEE)**. A través de minicursos interactivos, recursos especializados y actividades formativas, podrás conocer los diferentes tipos de NEE, identificar barreras para el aprendizaje y aplicar técnicas que favorezcan la participación, el bienestar y el éxito académico de todos los estudiantes.

Creemos que una educación inclusiva no solo transforma la experiencia de aprendizaje de los estudiantes, sino que también fortalece la labor docente y contribuye a la construcción de una comunidad universitaria más equitativa, diversa y accesible.

**Tu compromiso con la inclusión marca la diferencia.**

¡Comienza tu recorrido formativo y sé parte del cambio hacia una educación superior más inclusiva!
''';

  Future<void> _completeWelcome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (context.mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Markdown(
                    data: _welcomeText,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      p: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                      strong: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _completeWelcome(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Comenzar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
