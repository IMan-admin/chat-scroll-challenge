import 'package:flutter/foundation.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';

class GeminiStreamManager extends ChangeNotifier {
  final ChatController _chatController;

  final Map<String, StreamState> _streamStates = {};
  final Map<String, TextStreamMessage> _originalMessages = {};
  final Map<String, String> _accumulatedTexts = {};

  GeminiStreamManager({required ChatController chatController})
    : _chatController = chatController;

  StreamState getState(String streamId) {
    return _streamStates[streamId] ?? const StreamStateLoading();
  }

  void startStream(String streamId, TextStreamMessage originalMessage) {
    _originalMessages[streamId] = originalMessage;
    _streamStates[streamId] = const StreamStateLoading();
    _accumulatedTexts[streamId] = '';
    notifyListeners();
  }

  void addChunk(String streamId, String chunk) {
    if (!_streamStates.containsKey(streamId)) return;

    _accumulatedTexts[streamId] = (_accumulatedTexts[streamId] ?? '') + chunk;
    _streamStates[streamId] = StreamStateStreaming(
      _accumulatedTexts[streamId]!,
    );
    notifyListeners();
  }

  Future<void> completeStream(String streamId) async {
    final originalMessage = _originalMessages[streamId];
    if (originalMessage == null) {
      _cleanupStream(streamId);
      return;
    }

    final finalText = _accumulatedTexts[streamId] ?? '';
    await _replaceWithTextMessage(originalMessage, finalText);
    _cleanupStream(streamId);
  }

  Future<void> cancelStream(String streamId) async {
    final originalMessage = _originalMessages[streamId];
    if (originalMessage == null) {
      _cleanupStream(streamId);
      return;
    }

    final partialText = _accumulatedTexts[streamId] ?? '';
    if (partialText.trim().isEmpty) {
      try {
        await _chatController.removeMessage(originalMessage);
      } catch (e) {
        debugPrint(
          'GeminiStreamManager: Failed to remove message $streamId: $e',
        );
      }
    } else {
      await _replaceWithTextMessage(originalMessage, partialText);
    }

    _cleanupStream(streamId);
  }

  Future<void> errorStream(String streamId, Object error) async {
    final originalMessage = _originalMessages[streamId];
    if (originalMessage == null) {
      _cleanupStream(streamId);
      return;
    }

    final currentText = _accumulatedTexts[streamId] ?? '';
    final errorText = currentText.trim().isEmpty
        ? '[${error.toString()}]'
        : '$currentText\n\n[${error.toString()}]';

    await _replaceWithTextMessage(originalMessage, errorText);
    _cleanupStream(streamId);
  }

  Future<void> _replaceWithTextMessage(
    TextStreamMessage originalMessage,
    String text,
  ) async {
    final finalTextMessage = TextMessage(
      id: originalMessage.id,
      authorId: originalMessage.authorId,
      createdAt: originalMessage.createdAt,
      text: text,
    );

    try {
      await _chatController.updateMessage(originalMessage, finalTextMessage);
    } catch (e) {
      debugPrint(
        'GeminiStreamManager: Failed to update message ${originalMessage.id}: $e',
      );
    }
  }

  void _cleanupStream(String streamId) {
    _streamStates.remove(streamId);
    _originalMessages.remove(streamId);
    _accumulatedTexts.remove(streamId);
    notifyListeners();
  }
}
