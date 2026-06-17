import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/constants/app_colors.dart';

class LessonEditorScreen extends StatefulWidget {
  final String? initialMarkdown;

  const LessonEditorScreen({super.key, this.initialMarkdown});

  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMarkdown ?? '# Nueva Lección\nEscribe tu contenido aquí...');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Editor de Lección (Markdown)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  // Guardar
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                // Editor Izquierdo
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontFamily: 'monospace'),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Previsualizador Derecho
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Markdown(
                      data: _controller.text,
                      selectable: true,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
