import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../authentication/presentation/auth_controller.dart';
import 'learning_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulosAsync = ref.watch(modulosProvider);
    final progresoAsync = ref.watch(progresoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Docente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: modulosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (modulos) {
          return progresoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (progresos) {
              // Calcular avance general
              final completados = progresos.where((p) => p.estado.name == 'completado').length;
              final avanceGeneral = modulos.isEmpty ? 0.0 : (completados / modulos.length) * 100;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tarjeta de Resumen
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('Tu Nivel Inclusivo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            avanceGeneral >= 100 ? 'Docente Experto' : 
                            avanceGeneral >= 50 ? 'Docente Facilitador' : 'Docente en Formación',
                            style: const TextStyle(fontSize: 24, color: Colors.blue),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(value: avanceGeneral / 100, minHeight: 10),
                          const SizedBox(height: 8),
                          Text('Progreso General: ${avanceGeneral.toStringAsFixed(1)}%'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Módulos de Aprendizaje', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // Lista de módulos
                  if (modulos.isEmpty)
                    const Text('No hay módulos disponibles todavía.')
                  else
                    ...modulos.map((modulo) {
                      final esCompletado = progresos.any((p) => p.idModulo == modulo.id && p.estado.name == 'completado');
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(modulo.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(modulo.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Icon(
                            esCompletado ? Icons.check_circle : Icons.play_circle_outline,
                            color: esCompletado ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                          onTap: () {
                            context.push('/modulo/${modulo.id}', extra: modulo);
                          },
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
