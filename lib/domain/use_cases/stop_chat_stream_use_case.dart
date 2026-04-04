import '../../presentation/chat/state/gemini_stream_manager.dart';
import '../entities/active_chat_stream.dart';

class StopChatStreamUseCase {
  final GeminiStreamManager streamManager;

  StopChatStreamUseCase({required this.streamManager});

  Future<void> execute(ActiveChatStream? activeStream) async {
    if (activeStream == null) return;

    await activeStream.subscription.cancel();
    await streamManager.cancelStream(activeStream.streamId);
  }
}
