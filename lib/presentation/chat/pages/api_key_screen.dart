import 'package:flutter/material.dart';

import 'gemini_chat_screen.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Chat Auto-Scroll Challenge',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your Gemini API key to start.\n'
                'Get a free key at ai.google.dev',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 350,
                child: TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Gemini API Key',
                  ),
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final apiKey = _apiKeyController.text.trim();
                  if (apiKey.isEmpty) return;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GeminiChatScreen(
                        geminiApiKey: apiKey,
                      ),
                    ),
                  );
                },
                child: const Text('Start Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
