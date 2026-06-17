import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/caso_simulado.dart';
import 'simulator_controller.dart';

class SimulatorScreen extends ConsumerStatefulWidget {
  final CasoSimulado caso;

  const SimulatorScreen({super.key, required this.caso});

  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen> {
  // Estado de la pantalla
  String? _opcionSeleccionadaId;
  bool? _esCorrecta;
  bool _respondido = false;
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Simulador de Aula'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del caso
            _buildCasoHeader(),
            const SizedBox(height: 24),

            // Situación
            _buildSituacion(),
            const SizedBox(height: 28),

            // Pregunta y opciones
            const Text(
              '¿Qué harías en esta situación?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // Opciones de respuesta
            ...widget.caso.opciones.map((opcion) => _buildOpcionCard(opcion)),

            const SizedBox(height: 24),

            // Feedback después de responder
            if (_respondido) _buildFeedback(),

            const SizedBox(height: 16),

            // Botón de acción
            if (!_respondido)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _opcionSeleccionadaId == null || _cargando
                      ? null
                      : _confirmarRespuesta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirmar Respuesta', style: TextStyle(fontSize: 16)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver al Módulo', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: Colors.indigo, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.caso.titulo,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(widget.caso.necesidadEducativa, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.blue.shade100,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(widget.caso.nivelDificultad, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.orange.shade100,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSituacion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Situación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.caso.situacion,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionCard(OpcionRespuesta opcion) {
    final bool estaSeleccionada = _opcionSeleccionadaId == opcion.id;
    Color borderColor = estaSeleccionada ? Colors.indigo : Colors.grey.shade300;
    Color bgColor = estaSeleccionada ? Colors.indigo.shade50 : Colors.white;

    // Si ya respondió, colorear verde o rojo
    if (_respondido) {
      if (opcion.id == widget.caso.idRespuestaCorrecta) {
        borderColor = Colors.green;
        bgColor = Colors.green.shade50;
      } else if (estaSeleccionada && !_esCorrecta!) {
        borderColor = Colors.red;
        bgColor = Colors.red.shade50;
      }
    }

    return GestureDetector(
      onTap: _respondido ? null : () => setState(() => _opcionSeleccionadaId = opcion.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: estaSeleccionada ? 2 : 1),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
                color: estaSeleccionada ? Colors.indigo : Colors.transparent,
              ),
              child: estaSeleccionada
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(opcion.texto, style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
            if (_respondido && opcion.id == widget.caso.idRespuestaCorrecta)
              const Icon(Icons.check_circle, color: Colors.green),
            if (_respondido && estaSeleccionada && !_esCorrecta!)
              const Icon(Icons.cancel, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final bool correcto = _esCorrecta!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: correcto ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: correcto ? Colors.green : Colors.red, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correcto ? Icons.check_circle : Icons.cancel,
                color: correcto ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                correcto ? '¡Respuesta Correcta! +10 pts' : 'Respuesta Incorrecta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: correcto ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text(
            'Explicación Pedagógica:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.caso.explicacionPedagogica,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarRespuesta() async {
    if (_opcionSeleccionadaId == null) return;
    
    setState(() => _cargando = true);

    final opcionSeleccionada = widget.caso.opciones
        .firstWhere((op) => op.id == _opcionSeleccionadaId);

    final esCorrecta = await ref.read(simulatorControllerProvider).evaluarRespuesta(
      caso: widget.caso,
      opcionSeleccionada: opcionSeleccionada,
    );

    setState(() {
      _esCorrecta = esCorrecta;
      _respondido = true;
      _cargando = false;
    });
  }
}
