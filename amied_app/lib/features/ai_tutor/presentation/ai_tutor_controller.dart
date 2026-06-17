import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_repository.dart';
import '../domain/chat_message.dart';

final chatMessagesProvider = NotifierProvider<AiTutorController, List<ChatMessage>>(() {
  return AiTutorController();
});

final isAiTypingProvider = NotifierProvider<IsAiTypingNotifier, bool>(() {
  return IsAiTypingNotifier();
});

class IsAiTypingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setTyping(bool value) => state = value;
}

class AiTutorController extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    ref.read(aiRepositoryProvider).startChat();
    return [
      ChatMessage(
        text: '¡Hola! Soy tu tutor virtual. ¿En qué te puedo ayudar hoy sobre educación inclusiva o adaptaciones curriculares?',
        isUser: false,
      ),
    ];
  }

  Future<void> sendMessage(String text, WidgetRef uiRef) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true);
    state = [...state, userMessage];

    uiRef.read(isAiTypingProvider.notifier).setTyping(true);

    final responseText = await ref.read(aiRepositoryProvider).sendMessageToChat(text);

    uiRef.read(isAiTypingProvider.notifier).setTyping(false);
    final botMessage = ChatMessage(text: responseText, isUser: false);
    state = [...state, botMessage];
  }
}
