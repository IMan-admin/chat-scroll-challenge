import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../domain/entities/active_chat_stream.dart';
import '../../domain/use_cases/send_chat_message_use_case.dart';
import '../../domain/use_cases/stop_chat_stream_use_case.dart';
import 'chat_auto_scroll_controller.dart';

class ScrollToBottomRequest {
  final bool animated;

  const ScrollToBottomRequest({this.animated = false});
}

class ChatPresenter extends ChangeNotifier {
  final SendChatMessageUseCase sendChatMessageUseCase;
  final StopChatStreamUseCase stopChatStreamUseCase;
  final ChatAutoScrollController autoScrollController;

  final _uiEventsController = StreamController<ScrollToBottomRequest>.broadcast();

  ActiveChatStream? _activeStream;
  bool _isStreaming = false;

  ChatPresenter({
    required this.sendChatMessageUseCase,
    required this.stopChatStreamUseCase,
    ChatAutoScrollController? autoScrollController,
  }) : autoScrollController =
           autoScrollController ?? ChatAutoScrollController();

  Stream<ScrollToBottomRequest> get uiEvents => _uiEventsController.stream;
  bool get isStreaming => _isStreaming;

  void handleScrollChanged({
    required double currentScroll,
    required double maxScroll,
  }) {
    autoScrollController.updateScrollPosition(
      currentScroll: currentScroll,
      maxScroll: maxScroll,
    );
  }

  Future<void> sendMessage({
    required Message userMessage,
    required Content content,
  }) async {
    autoScrollController.requestAutoScroll();
    _emitScrollToBottom();
    _setStreaming(true);

    try {
      _activeStream = await sendChatMessageUseCase.execute(
        userMessage: userMessage,
        content: content,
        onChunk: (_, __) => _emitScrollToBottom(animated: true),
        onDone: (_) async {
          _emitScrollToBottom();
          _clearActiveStream();
        },
        onError: (streamId, error) async {
          await sendChatMessageUseCase.streamManager.errorStream(
            streamId,
            error,
          );
          _emitScrollToBottom();
          _clearActiveStream();
        },
      );

      _emitScrollToBottom();
    } catch (error) {
      _setStreaming(false);
      rethrow;
    }
  }

  Future<void> stopCurrentStream() async {
    final activeStream = _activeStream;
    if (activeStream == null) return;

    _activeStream = null;
    await stopChatStreamUseCase.execute(activeStream);
    _setStreaming(false);
    _emitScrollToBottom();
  }

  @override
  void dispose() {
    unawaited(_activeStream?.subscription.cancel());
    _uiEventsController.close();
    super.dispose();
  }

  void _clearActiveStream() {
    _activeStream = null;
    _setStreaming(false);
  }

  void _setStreaming(bool value) {
    if (_isStreaming == value) return;
    _isStreaming = value;
    notifyListeners();
  }

  void _emitScrollToBottom({bool animated = false}) {
    if (!autoScrollController.shouldAutoScroll) return;
    _uiEventsController.add(ScrollToBottomRequest(animated: animated));
  }
}
