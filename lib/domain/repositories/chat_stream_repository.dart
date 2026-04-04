import 'package:google_generative_ai/google_generative_ai.dart';

abstract class ChatStreamRepository {
  Stream<String> sendMessageStream(Content content);
}
