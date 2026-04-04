import 'package:google_generative_ai/google_generative_ai.dart';

import '../../domain/repositories/chat_stream_repository.dart';

class GeminiChatStreamRepository implements ChatStreamRepository {
  final ChatSession _chatSession;

  GeminiChatStreamRepository(this._chatSession);

  @override
  Stream<String> sendMessageStream(Content content) {
    return _chatSession.sendMessageStream(content).map(
      (response) => response.text ?? '',
    );
  }
}
