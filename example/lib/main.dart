import 'package:flutter/material.dart';
import 'package:kuradesk_chat/kuradesk_chat.dart';

/// Base URL of your KuraDesk deployment.
const kuradeskApiBaseUrl = 'https://desk.kurasika.tech';

/// Public widget key from KuraDesk -> Settings -> Chat plugins.
const kuradeskWidgetKey = 'YOUR_WIDGET_PUBLIC_KEY';

void main() => runApp(const ExampleApp());

/// Example app showing both ways to embed KuraDesk chat.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KuraDesk Chat Example',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0D9488)),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

/// Wraps the app content in a [KuradeskChatLauncher] so the floating chat
/// button is available on every screen.
class HomePage extends StatelessWidget {
  /// Creates the home page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return KuradeskChatLauncher(
      apiBaseUrl: kuradeskApiBaseUrl,
      widgetKey: kuradeskWidgetKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('KuraDesk Chat Example')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tap the floating button in the bottom-right corner to open '
                  'the chat panel.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FullScreenChatPage(),
                    ),
                  ),
                  child: const Text('Open full-screen chat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows [KuradeskChatView] filling an entire route.
class FullScreenChatPage extends StatelessWidget {
  /// Creates the full-screen chat page.
  const FullScreenChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: const SafeArea(
        child: KuradeskChatView(
          apiBaseUrl: kuradeskApiBaseUrl,
          widgetKey: kuradeskWidgetKey,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}
