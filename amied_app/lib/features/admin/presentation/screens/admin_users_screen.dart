import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/admin_repository.dart';
import '../../services/pdf_report_service.dart';

final adminUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getUsersReportData();
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetailsDialog(BuildContext context, Map<String, dynamic> user) {
    final userId = user['user_id'] as String?;
    if (userId == null) return;
    final userName = user['full_name'] ?? user['email'] ?? 'Usuario';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Progreso Detallado: $userName'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: FutureBuilder<Map<String, dynamic>>(
              future: ref.read(adminRepositoryProvider).getUserDetailedProgress(userId, courseId: user['course_id'] as String?),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final data = snapshot.data!;
                final courses = data['courses'] as List;
                final quizzes = data['quizzes'] as List;
                final badges = data['badges'] as List;

                return ListView(
                  children: [
                    const Text('Cursos Matriculados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    if (courses.isEmpty) const Text('No está matriculado en ningún curso.', style: TextStyle(color: Colors.grey)),
                    ...courses.map((c) {
                      final title = c['courses']?['title'] ?? 'Curso Desconocido';
                      final enrolled = c['enrolled_at'] != null ? DateTime.parse(c['enrolled_at']).toLocal().toString().split(' ')[0] : 'N/A';
                      return ListTile(
                        leading: const Icon(Icons.book, color: AppColors.primary),
                        title: Text(title),
                        subtitle: Text('Matriculado el: $enrolled'),
                      );
                    }),
                    const Divider(height: 32),
                    const Text('Evaluaciones (Quizzes)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    if (quizzes.isEmpty) const Text('No ha intentado ninguna evaluación.', style: TextStyle(color: Colors.grey)),
                    ...quizzes.map((q) {
                      final title = q['quizzes']?['title'] ?? 'Quiz Desconocido';
                      final passed = q['passed'] == true;
                      return ListTile(
                        leading: Icon(passed ? Icons.check_circle : Icons.cancel, color: passed ? Colors.green : Colors.red),
                        title: Text(title),
                        subtitle: Text('Puntaje: ${q['score']}%'),
                      );
                    }),
                    const Divider(height: 32),
                    const Text('Medallas Obtenidas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    if (badges.isEmpty) const Text('Aún no tiene medallas.', style: TextStyle(color: Colors.grey)),
                    ...badges.map((b) {
                      final title = b['badges']?['name'] ?? 'Medalla';
                      return ListTile(
                        leading: const Icon(Icons.emoji_events, color: Colors.amber),
                        title: Text(title),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard de Progreso',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              usersAsync.maybeWhen(
                data: (users) => ElevatedButton.icon(
                  onPressed: () => PdfReportService.generateAndDownloadProgressReport(users),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Descargar Reporte PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('No hay usuarios registrados.'));
                }

                // Filtrar reportes (filas)
                final filteredRows = users.where((u) {
                  final email = (u['email'] ?? '').toString().toLowerCase();
                  final name = (u['full_name'] ?? '').toString().toLowerCase();
                  final inst = (u['institution'] ?? '').toString().toLowerCase();
                  final course = (u['course_title'] ?? '').toString().toLowerCase();
                  final q = _searchQuery.toLowerCase();
                  return email.contains(q) || name.contains(q) || inst.contains(q) || course.contains(q);
                }).toList();

                // Ordenar por nombre de usuario y luego por curso
                filteredRows.sort((a, b) {
                  int nameComp = (a['full_name'] ?? '').toString().compareTo((b['full_name'] ?? '').toString());
                  if (nameComp != 0) return nameComp;
                  return (a['course_title'] ?? '').toString().compareTo((b['course_title'] ?? '').toString());
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gráficas
                    SizedBox(
                      height: 220,
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const Text('Top Estudiantes (XP)', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Expanded(child: _buildTopXPChart(users)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const Text('Distribución por Niveles', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Expanded(child: _buildLevelsPieChart(users)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Buscador
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar usuario (Nombre, Correo, Institución)',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lista Detallada
                    const Text('Clasificación de Usuarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        child: RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(adminUsersProvider);
                            await ref.read(adminUsersProvider.future);
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredRows.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final row = filteredRows[index];
                              final isCompleted = row['status'] == 'completed';
                              final progress = (row['progress_percentage'] as int? ?? 0) / 100.0;
                              
                              return ListTile(
                                onTap: () => _showUserDetailsDialog(context, row), // Reusing dialog but passing the row (which has user_id)
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        row['full_name'] ?? row['email'] ?? 'Usuario', 
                                        style: const TextStyle(fontWeight: FontWeight.bold)
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isCompleted ? Colors.green : Colors.orange),
                                      ),
                                      child: Text(
                                        isCompleted ? 'Finalizado' : 'En Curso',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isCompleted ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${row['institution'] ?? 'Sin institución'} | ${row['email']} | Nivel ${row['current_level']} (${row['total_xp']} XP)', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                    const SizedBox(height: 8),
                                    Text('Curso: ${row['course_title']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: Colors.grey[200],
                                              color: isCompleted ? Colors.green : AppColors.primary,
                                              minHeight: 8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: $e', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(adminUsersProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopXPChart(List<dynamic> allRows) {
    final Map<String, dynamic> uniqueUsers = {};
    for (var row in allRows) {
      final role = row['role'] as String?;
      if (role == 'student' || role == null) {
        uniqueUsers[row['user_id']] = row;
      }
    }
    final students = uniqueUsers.values.toList();
    students.sort((a, b) => ((b['total_xp'] ?? 0) as int).compareTo((a['total_xp'] ?? 0) as int));
    final top5 = students.take(5).toList();

    if (top5.isEmpty) {
      return const Center(child: Text('No hay suficientes datos', style: TextStyle(fontSize: 12)));
    }

    double maxXP = 100;
    if (top5.isNotEmpty && top5.first['total_xp'] != null && (top5.first['total_xp'] as int) > 0) {
      maxXP = (top5.first['total_xp'] as int).toDouble();
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxXP * 1.2,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= top5.length || value.toInt() < 0) return const SizedBox.shrink();
                final name = top5[value.toInt()]['full_name'] ?? top5[value.toInt()]['email'] ?? 'User';
                final shortName = name.toString().split('@').first.split(' ').first; // Take first name or email prefix
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    shortName.length > 7 ? shortName.substring(0, 7) : shortName, 
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: top5.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: ((user['total_xp'] ?? 0) as int).toDouble(),
                color: AppColors.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLevelsPieChart(List<dynamic> allRows) {
    final Map<String, dynamic> uniqueUsers = {};
    for (var row in allRows) {
      final role = row['role'] as String?;
      if (role == 'student' || role == null) {
        uniqueUsers[row['user_id']] = row;
      }
    }

    final Map<int, int> levelCounts = {};
    for (var u in uniqueUsers.values) {
      final lvl = u['current_level'] as int? ?? 1;
      levelCounts[lvl] = (levelCounts[lvl] ?? 0) + 1;
    }

    if (levelCounts.isEmpty) {
      return const Center(child: Text('No hay datos', style: TextStyle(fontSize: 12)));
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];

    int i = 0;
    final pieData = levelCounts.entries.map((e) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: 'Nvl ${e.key}\n(${e.value})',
        color: color,
        radius: 40,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: pieData,
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }
}
