import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/chat/pages/api_key_screen.dart';

class ChatScrollChallengeApp extends StatelessWidget {
  const ChatScrollChallengeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat Scroll Challenge',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const ApiKeyScreen(),
    );
  }
}
