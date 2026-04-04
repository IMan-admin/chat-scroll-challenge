import 'dart:async';

class ActiveChatStream {
  final String streamId;
  final StreamSubscription<String> subscription;

  const ActiveChatStream({
    required this.streamId,
    required this.subscription,
  });
}
