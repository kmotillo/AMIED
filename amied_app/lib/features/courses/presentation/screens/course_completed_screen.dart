import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/constants/app_colors.dart';

class CourseCompletedScreen extends StatefulWidget {
  const CourseCompletedScreen({super.key});

  @override
  State<CourseCompletedScreen> createState() => _CourseCompletedScreenState();
}

class _CourseCompletedScreenState extends State<CourseCompletedScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    
    // Configurar animación de rebote para la medalla
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Iniciar efectos
    _playSoundAndConfetti();
  }

  Future<void> _playSoundAndConfetti() async {
    // Retraso pequeño para que la pantalla termine de abrirse
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      await _audioPlayer.play(AssetSource('sounds/success.ogg'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
    
    _confettiController.play();
    _animationController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo oscuro semitransparente o degradado vibrante
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Degradado de fondo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Contenido Principal
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Medalla animada
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.military_tech,
                        color: Colors.amber,
                        size: 140,
                      ),
                      // Destellos
                      Positioned(
                        top: 10,
                        right: 20,
                        child: Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 30),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 24),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Texto de celebración
                const Text(
                  '¡Felicidades!',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Has superado con éxito todos los contenidos y evaluaciones de este curso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Puntos de experiencia
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amberAccent, size: 28),
                      SizedBox(width: 12),
                      Text(
                        '+200 XP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Botón de continuar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        // Cierra la pantalla de celebración
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        '¡Increíble!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Efecto de Confeti (Centrado)
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 60,
              minBlastForce: 20,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.15,
              colors: const [
                Colors.amber,
                Colors.greenAccent,
                Colors.pinkAccent,
                Colors.blueAccent,
                Colors.purpleAccent,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
