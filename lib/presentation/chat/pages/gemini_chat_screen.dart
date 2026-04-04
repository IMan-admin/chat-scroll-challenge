import 'dart:async';

import 'package:cross_cache/cross_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart'
    hide InMemoryChatController;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/controllers/in_memory_chat_controller.dart';
import '../../../data/repositories/gemini_chat_stream_repository.dart';
import '../../../domain/use_cases/send_chat_message_use_case.dart';
import '../../../domain/use_cases/stop_chat_stream_use_case.dart';
import '../chat_presenter.dart';
import '../state/gemini_stream_manager.dart';

const Duration _kScrollAnimationDuration = Duration(milliseconds: 180);

class GeminiChatScreen extends StatefulWidget {
  final String geminiApiKey;

  const GeminiChatScreen({super.key, required this.geminiApiKey});

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final _uuid = const Uuid();
  final _crossCache = CrossCache();
  final _scrollController = ScrollController();
  final _chatController = InMemoryChatController();

  final _currentUser = const User(id: 'me');
  final _agent = const User(id: 'agent');

  late final GenerativeModel _model;
  late final GeminiStreamManager _streamManager;
  late final ChatPresenter _presenter;
  StreamSubscription<ScrollToBottomRequest>? _scrollRequestSubscription;

  @override
  void initState() {
    super.initState();
    _streamManager = GeminiStreamManager(chatController: _chatController);

    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: widget.geminiApiKey,
      safetySettings: [
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );

    final repository = GeminiChatStreamRepository(_model.startChat());
    final sendChatMessageUseCase = SendChatMessageUseCase(
      chatController: _chatController,
      streamManager: _streamManager,
      repository: repository,
      agent: _agent,
    );
    final stopChatStreamUseCase = StopChatStreamUseCase(
      streamManager: _streamManager,
    );

    _presenter = ChatPresenter(
      sendChatMessageUseCase: sendChatMessageUseCase,
      stopChatStreamUseCase: stopChatStreamUseCase,
    );
    _scrollController.addListener(_handleScrollChanged);
    _scrollRequestSubscription = _presenter.uiEvents.listen(_handleScrollRequest);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollChanged);
    _scrollRequestSubscription?.cancel();
    _presenter.dispose();
    _streamManager.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    _crossCache.dispose();
    super.dispose();
  }

  void _handleScrollChanged() {
    if (!_scrollController.hasClients) return;
    _presenter.handleScrollChanged(
      currentScroll: _scrollController.offset,
      maxScroll: _scrollController.position.maxScrollExtent,
    );
  }

  void _handleScrollRequest(ScrollToBottomRequest request) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final currentOffset = _scrollController.offset;
      final targetOffset = _scrollController.position.maxScrollExtent;
      if ((currentOffset - targetOffset).abs() < 0.5) return;

      if (request.animated) {
        unawaited(
          _scrollController.animateTo(
            targetOffset,
            duration: _kScrollAnimationDuration,
            curve: Curves.easeOut,
          ),
        );
      } else {
        _scrollController.jumpTo(targetOffset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gemini Chat')),
      body: ChangeNotifierProvider.value(
        value: _streamManager,
        child: Chat(
          builders: Builders(
            chatAnimatedListBuilder: (context, itemBuilder) {
              return ChatAnimatedList(
                scrollController: _scrollController,
                itemBuilder: itemBuilder,
                initialScrollToEndMode: InitialScrollToEndMode.none,
              );
            },
            imageMessageBuilder:
                (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) => FlyerChatImageMessage(
                  message: message,
                  index: index,
                  showTime: false,
                  showStatus: false,
                ),
            composerBuilder: (context) => ListenableBuilder(
              listenable: _presenter,
              builder: (context, _) => _Composer(
                isStreaming: _presenter.isStreaming,
                onStop: () => unawaited(_presenter.stopCurrentStream()),
              ),
            ),
            textMessageBuilder:
                (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) => FlyerChatTextMessage(
                  message: message,
                  index: index,
                  showTime: false,
                  showStatus: false,
                  receivedBackgroundColor: Colors.transparent,
                  padding: message.authorId == _agent.id
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                ),
            textStreamMessageBuilder:
                (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  final streamState = context
                      .watch<GeminiStreamManager>()
                      .getState(message.streamId);

                  return FlyerChatTextStreamMessage(
                    message: message,
                    index: index,
                    streamState: streamState,
                    showTime: false,
                    showStatus: false,
                    receivedBackgroundColor: Colors.transparent,
                    padding: message.authorId == _agent.id
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                  );
                },
          ),
          chatController: _chatController,
          crossCache: _crossCache,
          currentUserId: _currentUser.id,
          onAttachmentTap: _handleAttachmentTap,
          onMessageSend: _handleMessageSend,
          resolveUser: (id) => Future.value(
            switch (id) {
              'me' => _currentUser,
              'agent' => _agent,
              _ => null,
            },
          ),
          theme: ChatTheme.fromThemeData(theme),
        ),
      ),
    );
  }

  Future<void> _handleMessageSend(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await _presenter.sendMessage(
      userMessage: TextMessage(
        id: _uuid.v4(),
        authorId: _currentUser.id,
        createdAt: DateTime.now().toUtc(),
        text: trimmed,
        metadata: isOnlyEmoji(trimmed) ? {'isOnlyEmoji': true} : null,
      ),
      content: Content.text(trimmed),
    );
  }

  Future<void> _handleAttachmentTap() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    await _crossCache.downloadAndSave(image.path);
    final bytes = await _crossCache.get(image.path);

    await _presenter.sendMessage(
      userMessage: ImageMessage(
        id: _uuid.v4(),
        authorId: _currentUser.id,
        createdAt: DateTime.now().toUtc(),
        source: image.path,
      ),
      content: Content.data('image/jpeg', bytes),
    );
  }
}

class _Composer extends StatefulWidget {
  final bool isStreaming;
  final VoidCallback? onStop;

  const _Composer({
    this.isStreaming = false,
    this.onStop,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _key = GlobalKey();
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.onKeyEvent = _handleKeyEvent;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isShiftPressed) {
      _handleSubmitted(_textController.text);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(covariant _Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final onAttachmentTap = context.read<OnAttachmentTapCallback?>();
    final theme = context.select(
      (ChatTheme t) => (
        bodyMedium: t.typography.bodyMedium,
        onSurface: t.colors.onSurface,
        surfaceContainerHigh: t.colors.surfaceContainerHigh,
        surfaceContainerLow: t.colors.surfaceContainerLow,
      ),
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRect(
        child: Container(
          key: _key,
          color: theme.surfaceContainerLow,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: bottomSafeArea)
                    .add(const EdgeInsets.all(8)),
                child: Row(
                  children: [
                    if (onAttachmentTap != null)
                      IconButton(
                        icon: const Icon(Icons.attachment),
                        color: theme.onSurface.withValues(alpha: 0.5),
                        onPressed: onAttachmentTap,
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: theme.bodyMedium.copyWith(
                            color: theme.onSurface.withValues(alpha: 0.5),
                          ),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius:
                                BorderRadius.all(Radius.circular(24)),
                          ),
                          filled: true,
                          fillColor: theme.surfaceContainerHigh.withValues(
                            alpha: 0.8,
                          ),
                          hoverColor: Colors.transparent,
                        ),
                        style: theme.bodyMedium.copyWith(
                          color: theme.onSurface,
                        ),
                        onSubmitted: _handleSubmitted,
                        textInputAction: TextInputAction.newline,
                        autocorrect: true,
                        autofocus: false,
                        textCapitalization: TextCapitalization.sentences,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: widget.isStreaming
                          ? const Icon(Icons.stop_circle)
                          : const Icon(Icons.send),
                      color: theme.onSurface.withValues(alpha: 0.5),
                      onPressed: widget.isStreaming
                          ? widget.onStop
                          : () => _handleSubmitted(_textController.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _measure() {
    if (!mounted) return;

    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final height = renderBox.size.height;
      final bottomSafeArea = MediaQuery.of(context).padding.bottom;
      context.read<ComposerHeightNotifier>().setHeight(height - bottomSafeArea);
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    context.read<OnMessageSendCallback?>()?.call(text);
    _textController.clear();
  }
}
