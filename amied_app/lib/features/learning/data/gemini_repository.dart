import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final geminiRepositoryProvider = FutureProvider<GeminiRepository>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('app_settings')
        .select('setting_value')
        .eq('setting_key', 'gemini_api_key')
        .maybeSingle();

    if (response == null || response['setting_value'] == null || response['setting_value'].toString().trim().isEmpty) {
      throw Exception('La API Key del Tutor Virtual no está configurada.');
    }

    final apiKey = response['setting_value'].toString().trim();

    // System instruction para darle personalidad al tutor
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'Eres un tutor experto en educación inclusiva en el contexto de Ecuador. '
        'Tu objetivo es guiar a docentes universitarios a adaptar sus materiales '
        'y estrategias pedagógicas para estudiantes con discapacidad, haciendo '
        'referencia a la Ley Orgánica de Educación Superior (LOES) cuando sea útil. '
        'Responde de forma amable, clara, pedagógica y paciente. Sé conciso.',
      ),
    );

    return GeminiRepository(model);
  } catch (e) {
    throw Exception('Error de configuración: $e');
  }
});

class GeminiRepository {
  final GenerativeModel _model;
  ChatSession? _chatSession;

  GeminiRepository(this._model);

  void startChat() {
    _chatSession = _model.startChat();
  }

  Future<String> sendMessage(String text) async {
    if (_chatSession == null) {
      startChat();
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      return response.text ?? 'No pude generar una respuesta.';
    } catch (e) {
      throw Exception('Error al contactar con Gemini: $e');
    }
  }
}
