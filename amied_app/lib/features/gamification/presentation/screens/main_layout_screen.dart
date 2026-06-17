import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../courses/presentation/screens/courses_catalog_screen.dart';
import '../../../courses/presentation/screens/my_courses_screen.dart';
import '../../../auth/presentation/providers/role_provider.dart';
import 'profile_screen.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);
    final showDevCourses = roleAsync.value == 'admin' || roleAsync.value == 'docente';

    final screens = [
      const MyCoursesScreen(),
      const CoursesCatalogScreen(),
      if (showDevCourses) const CoursesCatalogScreen(showUnpublished: true),
      const ProfileScreen(),
    ];

    final bottomNavItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.menu_book),
        label: 'Mis Cursos',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore),
        label: 'Catálogo',
      ),
      if (showDevCourses)
        const BottomNavigationBarItem(
          icon: Icon(Icons.build),
          label: 'Pruebas',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    // Evitar desbordamiento de índice si cambia de admin a no-admin
    if (_currentIndex >= screens.length) {
      _currentIndex = screens.length - 1;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: _currentIndex == 1 // Solo mostrar en catálogo
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/ai-tutor'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Tutor Virtual'),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 6,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Asegura que todos los íconos se muestren bien con 4 items
        items: bottomNavItems,
      ),
    );
  }
}

