import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/modulo.dart';
import 'learning_controller.dart';
import '../../simulator/presentation/simulator_controller.dart';
import '../../simulator/presentation/simulator_screen.dart';

class ModuleDetailScreen extends ConsumerWidget {
  final Modulo modulo;

  const ModuleDetailScreen({super.key, required this.modulo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(modulo.titulo),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata
            Row(
              children: [
                Chip(label: Text(modulo.categoria), backgroundColor: Colors.blue.shade100),
                const SizedBox(width: 8),
                Chip(label: Text(modulo.dificultad), backgroundColor: Colors.orange.shade100),
              ],
            ),
            const SizedBox(height: 24),
            
            // Título principal
            Text(
              modulo.titulo,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Descripción
            Text(
              modulo.descripcion,
              style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.black54),
            ),
            const Divider(height: 40, thickness: 2),
            
            // Contenido teórico (Simulado, idealmente Markdown o HTML)
            const Text(
              'Contenido del Módulo:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              modulo.contenido.isEmpty 
                ? 'Este módulo aún no tiene contenido detallado. (Prueba visual)' 
                : modulo.contenido,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            
            const SizedBox(height: 40),
            
            // Botones de acción
            Consumer(
              builder: (context, ref, _) {
                final casoAsync = ref.watch(casoPorModuloProvider(modulo.id));
                return Column(
                  children: [
                    // Botón completar módulo
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(learningControllerProvider).marcarModuloCompletado(modulo.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('¡Módulo completado exitosamente!')),
                            );
                            context.pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Completar Módulo', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botón Simulador (solo si hay un caso disponible)
                    casoAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (err, stackTrace) => const SizedBox.shrink(),
                      data: (caso) {
                        if (caso == null) return const SizedBox.shrink();
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SimulatorScreen(caso: caso),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.psychology),
                            label: const Text('Iniciar Simulación', style: TextStyle(fontSize: 16)),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
