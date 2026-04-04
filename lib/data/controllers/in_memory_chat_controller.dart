import 'dart:async';

import 'package:flutter_chat_core/flutter_chat_core.dart';

class InMemoryChatController
    with UploadProgressMixin, ScrollToMessageMixin
    implements ChatController {
  List<Message> _messages;
  final _operationsController = StreamController<ChatOperation>.broadcast();

  InMemoryChatController({List<Message>? messages})
    : _messages = messages ?? [];

  @override
  List<Message> get messages => _messages;

  @override
  Stream<ChatOperation> get operationsStream => _operationsController.stream;

  @override
  Future<void> insertMessage(
    Message message, {
    int? index,
    bool animated = true,
  }) async {
    if (_messages.any((m) => m.id == message.id)) return;

    if (index == null) {
      _messages.add(message);
      _operationsController.add(
        ChatOperation.insert(message, _messages.length - 1, animated: animated),
      );
    } else {
      _messages.insert(index, message);
      _operationsController.add(
        ChatOperation.insert(message, index, animated: animated),
      );
    }
  }

  @override
  Future<void> insertAllMessages(
    List<Message> messages, {
    int? index,
    bool animated = true,
  }) async {
    if (messages.isEmpty) return;

    if (index == null) {
      final originalLength = _messages.length;
      _messages.addAll(messages);
      _operationsController.add(
        ChatOperation.insertAll(messages, originalLength, animated: animated),
      );
    } else {
      _messages.insertAll(index, messages);
      _operationsController.add(
        ChatOperation.insertAll(messages, index, animated: animated),
      );
    }
  }

  @override
  Future<void> removeMessage(Message message, {bool animated = true}) async {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index == -1) return;

    final actualMessage = _messages[index];
    _messages.removeAt(index);
    _operationsController.add(
      ChatOperation.remove(actualMessage, index, animated: animated),
    );
  }

  @override
  Future<void> updateMessage(Message oldMessage, Message newMessage) async {
    final index = _messages.indexWhere((m) => m.id == oldMessage.id);
    if (index == -1) return;

    final actualOldMessage = _messages[index];
    if (actualOldMessage == newMessage) return;

    _messages[index] = newMessage;
    _operationsController.add(
      ChatOperation.update(actualOldMessage, newMessage, index),
    );
  }

  @override
  Future<void> setMessages(
    List<Message> messages, {
    bool animated = true,
  }) async {
    _messages = List.from(messages);
    _operationsController.add(
      ChatOperation.set(
        _messages,
        animated: _messages.isEmpty ? false : animated,
      ),
    );
  }

  @override
  void dispose() {
    _operationsController.close();
    disposeUploadProgress();
    disposeScrollMethods();
  }
}
