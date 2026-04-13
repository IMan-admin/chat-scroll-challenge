import 'package:flutter/widgets.dart';

class ChatScrollControllerManager {
  final ScrollController scrollController;
  final double threshold;

  bool _isAtBottom = true;
  bool _isScrollPending = false;

  ChatScrollControllerManager({
    required this.scrollController,
    this.threshold = 50.0,
  });

  void attachListener() {
    scrollController.addListener(_scrollListener);
  }

  void dispose() {
    scrollController.removeListener(_scrollListener);
  }

  void _scrollListener() {
    if (!scrollController.hasClients) return;
    final pos = scrollController.position;
    final distanceToBottom = pos.maxScrollExtent - pos.pixels;
    _isAtBottom = distanceToBottom <= threshold;
  }

  void _refreshAtBottomState() {
    _scrollListener();
  }

  void onNewMessage() {
    if (!scrollController.hasClients) return;
    final wasAtBottom = _isAtBottom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      _refreshAtBottomState();
      if (wasAtBottom) {
        scrollToBottom();
      }
    });
  }

  void onStreamingUpdate() {
    if (!scrollController.hasClients) return;
    _refreshAtBottomState();
    if (_isAtBottom) {
      scrollToBottom(animated: false);
    }
  }

  void scrollToBottom({bool animated = true}) {
    if (!scrollController.hasClients || _isScrollPending) return;
    _isScrollPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isScrollPending = false;
      if (!scrollController.hasClients) return;

      final pos = scrollController.position;
      final target = pos.maxScrollExtent;

      if ((target - pos.pixels).abs() < 1.0) return;

      if (animated) {
        scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        scrollController.jumpTo(target);
      }
    });
  }

  bool get isAtBottom => _isAtBottom;
}
