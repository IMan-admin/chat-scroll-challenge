import 'dart:math' as math;

class ChatAutoScrollController {
  final double bottomThreshold;

  bool _shouldAutoScroll;
  bool _userIsNearBottom;

  ChatAutoScrollController({
    this.bottomThreshold = 24,
    bool shouldAutoScroll = true,
    bool userIsNearBottom = true,
  }) : _shouldAutoScroll = shouldAutoScroll,
       _userIsNearBottom = userIsNearBottom;

  bool get shouldAutoScroll => _shouldAutoScroll;
  bool get userIsNearBottom => _userIsNearBottom;

  void requestAutoScroll() {
    _shouldAutoScroll = true;
  }

  void updateScrollPosition({
    required double currentScroll,
    required double maxScroll,
  }) {
    final distanceFromBottom = math.max(0, maxScroll - currentScroll);
    final isNearBottom = distanceFromBottom <= bottomThreshold;

    _userIsNearBottom = isNearBottom;
    _shouldAutoScroll = isNearBottom;
  }
}
