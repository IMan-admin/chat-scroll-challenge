import 'dart:async';

import 'package:flutter_chat_core/flutter_chat_core.dart'
    hide InMemoryChatController;
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../../data/controllers/in_memory_chat_controller.dart';
import '../../presentation/chat/state/gemini_stream_manager.dart';
import '../entities/active_chat_stream.dart';
import '../repositories/chat_stream_repository.dart';

class SendChatMessageUseCase {
  final InMemoryChatController chatController;
  final GeminiStreamManager streamManager;
  final ChatStreamRepository repository;
  final Uuid uuid;
  final User agent;

  SendChatMessageUseCase({
    required this.chatController,
    required this.streamManager,
    required this.repository,
    required this.agent,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  Future<ActiveChatStream> execute({
    required Message userMessage,
    required Content content,
    required void Function(String streamId, String chunk) onChunk,
    required Future<void> Function(String streamId) onDone,
    required Future<void> Function(String streamId, Object error) onError,
  }) async {
    await chatController.insertMessage(userMessage);

    final streamId = uuid.v4();
    final streamMessage = TextStreamMessage(
      id: streamId,
      authorId: agent.id,
      createdAt: DateTime.now().toUtc(),
      streamId: streamId,
    );

    await chatController.insertMessage(streamMessage);
    streamManager.startStream(streamId, streamMessage);

    final subscription = repository.sendMessageStream(content).listen(
      (chunk) {
        if (chunk.isEmpty) return;
        streamManager.addChunk(streamId, chunk);
        onChunk(streamId, chunk);
      },
      onDone: () async {
        await streamManager.completeStream(streamId);
        await onDone(streamId);
      },
      onError: (error) {
        unawaited(onError(streamId, error));
      },
    );

    return ActiveChatStream(
      streamId: streamId,
      subscription: subscription,
    );
  }
}
