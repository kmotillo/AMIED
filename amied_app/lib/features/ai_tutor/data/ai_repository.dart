import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/constants/ai_keys.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository();
});

class AiRepository {
  late final GenerativeModel _model;
  late final GenerativeModel _chatModel;
  ChatSession? _chatSession;

  AiRepository() {
    // Configurar modelo para preguntas directas
    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: AiKeys.geminiApiKey,
      systemInstruction: Content.system(
        'Eres un experto en Educación Inclusiva y Necesidades Educativas Especiales (NEE). '
        'Tu labor es ayudar a docentes a adaptar sus metodologías y responder dudas sobre estrategias inclusivas, '
        'especialmente el Diseño Universal para el Aprendizaje (DUA) y atención a la diversidad. '
        'Tus respuestas deben ser pedagógicas, empáticas, y prácticas.',
      ),
    );

    // Configurar modelo para el chat con historial
    _chatModel = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: AiKeys.geminiApiKey,
      systemInstruction: Content.system(
        'Eres un tutor virtual experto en educación inclusiva. Respondes dudas de docentes sobre estrategias pedagógicas, '
        'NEEs (Necesidades Educativas Especiales), y diseño universal del aprendizaje. Mantén respuestas concisas, alentadoras y prácticas.',
      ),
    );
  }

  // Inicializar o reiniciar la sesión de chat
  void startChat() {
    _chatSession = _chatModel.startChat();
  }

  // Enviar mensaje al chat y mantener el contexto
  Future<String> sendMessageToChat(String message) async {
    if (_chatSession == null) {
      startChat();
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'Lo siento, no pude procesar la respuesta.';
    } catch (e) {
      return 'Error al comunicarse con Gemini: $e';
    }
  }

  // Analizar el resultado de una simulación para dar feedback extra
  Future<String> getFeedbackSimulacion({
    required String situacion,
    required String opcionSeleccionada,
    required bool fueCorrecta,
    required String explicacionOriginal,
  }) async {
    final prompt =
        '''
    Actúa como un tutor formador de docentes.
    El docente se enfrentó a este caso: "$situacion"
    El docente seleccionó la opción: "$opcionSeleccionada"
    El resultado fue: ${fueCorrecta ? 'Correcto' : 'Incorrecto'}.
    La explicación básica es: "$explicacionOriginal".
    
    Genera un feedback alentador de 2 o 3 párrafos en primera persona dirigiéndote al docente.
    Explica por qué su decisión impacta (positiva o negativamente) al estudiante y cómo puede mejorar.
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ??
          'No se pudo generar la retroalimentación ampliada.';
    } catch (e) {
      return 'Error al generar feedback: $e';
    }
  }
}
