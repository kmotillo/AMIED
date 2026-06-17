import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/role_provider.dart';

class AdminLayoutScreen extends ConsumerStatefulWidget {
  final Widget child;

  const AdminLayoutScreen({super.key, required this.child});

  @override
  ConsumerState<AdminLayoutScreen> createState() => _AdminLayoutScreenState();
}

class _AdminLayoutScreenState extends ConsumerState<AdminLayoutScreen> {
  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        if (role != 'admin') {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Acceso Denegado. Se requiere rol de Administrador.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Volver al Inicio'),
                  )
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Panel de Administración'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: const Text('Volver a la App', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Container(
            color: Colors.grey[100],
            child: widget.child,
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
