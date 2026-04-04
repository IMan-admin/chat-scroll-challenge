# Chat Auto-Scroll Challenge

## Setup

1. Get a free Gemini API key from [ai.google.dev](https://ai.google.dev)
2. Run `flutter pub get`
3. Run `flutter run` (web, macOS, or any platform)
4. Enter your API key and start chatting

## The Problem

This app uses [flutter_chat_ui](https://github.com/flyerhq/flutter_chat_ui) to display a streaming chat with Google Gemini. When you send a message, the AI response streams in token by token.

**Try it:** Send multiple messages (e.g. _"Write a detailed essay about the history of the internet"_) and notice the scroll UX issues as the responses stream in.

## Your Task

Compare the scroll behavior between this app and the reference implementation: https://iman-admin.github.io/chat-scroll-demo/

Identify the UX issues and fix them. Your solution must match the scroll behavior of the reference implementation.

**Test it thoroughly before you start coding.** Pay attention to every detail of how auto-scroll engages, disengages, and resumes. Your solution will be scored primarily on how closely it matches this behavior.

You are free to use any AI tools you'd like. What matters is the end result.

## How to Submit

1. Clone this repo into a **private** repository on your own GitHub account.
2. Implement your solution.
3. Deploy your solution to the web (GitHub Pages, Firebase Hosting, or any hosting).
4. Update this README with:
   - A list of the UX issues you identified and fixed.
   - Your deployed URL.
   - A screen recording demonstrating each fix.
5. Add **IMan-admin** as a collaborator to your private repo.
6. Send us the link to your repo.

## Evaluation Criteria

- Does it auto-scroll during streaming?
- Does manual scroll-away pause auto-scroll?
- Does returning to bottom resume auto-scroll?
- Is the code clean, testable, and well-separated?
- Are edge cases handled?

##

## video link

"https://drive.google.com/drive/folders/1ALXxurjmzJ1aiX1BRiH2kEwXVlVB7IKT"

## Description for each problem and its solution by code

1. Problem: No state to control auto-scroll

Solution: Add variables to determine whether auto-scroll is enabled and whether the user is near the bottom of the chat.

Example:

bool \_shouldAutoScroll = true;
bool \_userIsNearBottom = true;
final double \_bottomThreshold = 100.0; 2. Problem: No Scroll Listener to track user position

Solution: Add a listener to the ScrollController to detect whether the user is near the bottom.

Example:

\_scrollController.addListener(() {
if (!\_scrollController.hasClients) return;

final maxScroll = \_scrollController.position.maxScrollExtent;
final currentScroll = \_scrollController.position.pixels;
final isNearBottom = (maxScroll - currentScroll) <= \_bottomThreshold;

\_userIsNearBottom = isNearBottom;
\_shouldAutoScroll = isNearBottom;
}); 3. Problem: Not scrolling to bottom after sending a message

Solution: After inserting the user message, trigger a scroll to the bottom once the frame is built.

Example:

void \_handleMessageSend(String text) {
final userMessage = ChatMessage.user(text: text);
\_chatController.insertMessage(userMessage);

WidgetsBinding.instance.addPostFrameCallback((\_) {
\_scrollToBottom();
});

\_sendContent(text);
} 4. Problem: No auto-scroll during streaming

Solution: While receiving chunks, scroll to the bottom only if auto-scroll is enabled.

Example:

void \_onNewChunk(String streamId, String chunk) {
\_streamManager.addChunk(streamId, chunk);

if (\_shouldAutoScroll) {
\_scrollToBottom();
}
} 5. Problem: Assistant message appears late on first chunk

Solution: Create a placeholder assistant message immediately when the stream starts.

Example:

void \_startStream(String streamId) {
final assistantMessage = ChatMessage(
id: streamId,
role: Role.assistant,
text: '',
isStreaming: true,
);

\_chatController.insertMessage(assistantMessage);
} 6. Problem: Stopping the stream was treated as an error

Solution: Separate normal completion from errors and avoid using the error stream when stopping.

Example:

void stopStream(String streamId) {
\_streamManager.completeStream(streamId);
} 7. Problem: Text updates during streaming caused visual jitter

Solution: Accumulate text in a buffer and update the UI without unnecessary content changes.

Example:

void addChunk(String streamId, String chunk) {
\_buffers[streamId] = (\_buffers[streamId] ?? '') + chunk;
notifyListeners();
} 8. Problem: Auto-scroll should stop when the user scrolls up

Solution: Tie auto-scroll behavior to whether the user is near the bottom.

Example:

if (\_shouldAutoScroll) {
\_scrollToBottom();
} 9. Problem: No unified helper for scrolling to the bottom

Solution: Create a reusable method for scrolling.

Example:

void \_scrollToBottom() {
if (!\_scrollController.hasClients) return;

\_scrollController.animateTo(
\_scrollController.position.maxScrollExtent,
duration: const Duration(milliseconds: 300),
curve: Curves.easeOut,
);
} 10. Problem: Scroll logic was inside the message controller

Solution: Keep the controller responsible for data only, and move scroll logic to the UI layer.

Example:

void insertMessage(ChatMessage message) {
\_messages.add(message);
\_operationsController.add(message);
}

void \_scrollToBottom() {
\_scrollController.animateTo(
\_scrollController.position.maxScrollExtent,
duration: const Duration(milliseconds: 300),
curve: Curves.easeOut,
);
}

##

## Description for each problem and its solution by comments

1. Auto-scroll state is missing

The app does not maintain any state to control auto-scroll behavior, which makes it impossible to decide when scrolling should happen.
Solution: Introduced state variables to track whether auto-scroll is enabled and whether the user is near the bottom of the chat.

2. No tracking of user scroll position

There is no mechanism to detect where the user is in the chat, so the system cannot react properly when the user scrolls up.
Solution: Added a ScrollController listener to monitor the scroll position and determine if the user is near the bottom.

3. No scroll after sending a message

After sending a message, the view does not automatically scroll to show the latest message.
Solution: Triggered a scroll to the bottom after the frame is rendered using addPostFrameCallback.

4. Auto-scroll not working during streaming

While receiving streamed responses, new content does not automatically stay in view.
Solution: Enabled conditional auto-scroll during streaming, so scrolling happens only when it is appropriate.

5. Assistant message appears late

The assistant message is only created after the first chunk arrives, causing a delay in UI feedback.
Solution: Inserted a placeholder assistant message immediately when the stream starts.

6. Stream stopping handled as an error

Stopping the stream is incorrectly treated as an error, which affects the user experience.
Solution: Separated normal stream completion from error handling.

7. Visual jitter during streaming updates

Frequent UI updates while appending streamed text cause noticeable visual instability.
Solution: Buffered incoming chunks and updated the UI smoothly without unnecessary re-renders.

8. Auto-scroll does not stop when user scrolls up

The app continues to auto-scroll even when the user intentionally scrolls away from the bottom.
Solution: Linked auto-scroll behavior to the user’s position, disabling it when the user is not near the bottom.

9. No reusable scroll-to-bottom logic

Scrolling logic is duplicated or inconsistent across the codebase.
Solution: Created a reusable helper function to handle scrolling in a consistent way.

10. Scroll logic mixed with data layer

Scroll behavior is implemented inside the message controller, violating separation of concerns.
Solution: Moved all scroll-related logic to the UI layer and kept the controller focused on data management.
