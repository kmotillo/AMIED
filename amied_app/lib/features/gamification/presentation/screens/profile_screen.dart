import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/gamification_repository.dart';
import '../../../auth/presentation/providers/role_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("No estás autenticado");

      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last.toLowerCase();
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await Supabase.instance.client.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: 'image/$fileExt',
        ),
      );

      final avatarUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);

      await ref.read(authRepositoryProvider).updateAvatar(avatarUrl);
      
      if (mounted) {
        setState(() {}); // Refrescar la pantalla para mostrar la nueva foto
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir la imagen: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _showEditNameDialog(BuildContext context, String currentName, String currentInstitution) async {
    final nameController = TextEditingController(text: currentName);
    final institutionController = TextEditingController(text: currentInstitution);
    bool isLoading = false;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Nombre'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre y Apellidos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: institutionController,
                    decoration: const InputDecoration(
                      labelText: 'Institución Educativa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading ? null : () async {
                    if (nameController.text.trim().isEmpty || institutionController.text.trim().isEmpty) return;
                    setStateDialog(() => isLoading = true);
                    try {
                      await ref.read(authRepositoryProvider).updateProfile(
                        fullName: nameController.text.trim(),
                        institution: institutionController.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {}); // refresh the screen
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
                      }
                    } catch (e) {
                      setStateDialog(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Guardar'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final userGamificationAsync = ref.watch(userGamificationProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider);
    final allBadgesAsync = ref.watch(allBadgesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                tooltip: 'Cerrar Sesión',
              )
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  
                  // User Details Section
                  Consumer(
                    builder: (context, ref, child) {
                      final user = Supabase.instance.client.auth.currentUser;
                      final fullName = user?.userMetadata?['full_name'] ?? 'Usuario';
                      final institution = user?.userMetadata?['institution'] ?? 'Sin institución';
                      final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
                      final email = user?.email ?? '';
                      
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppColors.secondary,
                                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null || avatarUrl.isEmpty
                                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                                      : null,
                                ),
                                if (_isUploadingAvatar)
                                  const Positioned.fill(
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  fullName,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                                onPressed: () => _showEditNameDialog(context, fullName, institution),
                                tooltip: 'Editar Perfil',
                              ),
                            ],
                          ),
                          Text(
                            email,
                            style: const TextStyle(fontSize: 16, color: AppColors.textLight),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              institution,
                              style: const TextStyle(fontSize: 14, color: AppColors.secondary, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  userGamificationAsync.when(
                    data: (gamification) {
                      if (gamification == null) {
                        return const Text('Aún no tienes datos de progreso.');
                      }

                      final nextLevelXp = gamification.currentLevel * 100;
                      final currentLevelXp = (gamification.currentLevel - 1) * 100;
                      final progress = (gamification.totalXp - currentLevelXp) / (nextLevelXp - currentLevelXp);

                      return Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Nivel ${gamification.currentLevel}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${gamification.totalXp} XP Totales',
                              style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${gamification.totalXp} XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                Text('$nextLevelXp XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 16,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Faltan ${nextLevelXp - gamification.totalXp} XP para el siguiente nivel',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => Text('Error al cargar progreso: $e'),
                  ),
                  
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mis Medallas',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  allBadgesAsync.when(
                    data: (allBadges) {
                      final earnedIds = userBadgesAsync.value?.map((b) => b.id).toSet() ?? {};
                      final earnedBadges = allBadges.where((badge) => earnedIds.contains(badge.id)).toList();

                      if (earnedBadges.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Text(
                              'Aún no has obtenido ninguna medalla.\n¡Sigue completando cursos!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textLight, fontSize: 16),
                            ),
                          ),
                        );
                      }
                      
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: earnedBadges.length,
                        itemBuilder: (context, index) {
                          final badge = earnedBadges[index];

                          return Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface,
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B),
                                    width: 3,
                                  ),
                                ),
                                child: badge.iconUrl != null && badge.iconUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          badge.iconUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.emoji_events,
                                            size: 40,
                                            color: Color(0xFFF59E0B),
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.emoji_events,
                                        size: 40,
                                        color: Color(0xFFF59E0B),
                                      ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                badge.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => Text('Error al cargar medallas: $e'),
                  ),
                  const SizedBox(height: 32),
                  ref.watch(userRoleProvider).maybeWhen(
                    data: (role) => role == 'admin' ? ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
                      title: const Text('Panel de Administración'),
                      onTap: () => context.go('/admin/users'),
                    ) : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
