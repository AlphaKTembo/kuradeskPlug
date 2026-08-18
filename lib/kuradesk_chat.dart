/// In-app chat UI for KuraDesk.
///
/// Embed [KuradeskChatLauncher] to overlay a floating chat button on your app,
/// or [KuradeskChatView] to render the chat panel directly. Both talk to a
/// KuraDesk deployment through [KuradeskChatClient] and deliver conversations
/// into your shared team inbox.
library;

export 'src/kuradesk_chat_client.dart';
export 'src/kuradesk_chat_launcher.dart';
export 'src/kuradesk_chat_theme.dart';
export 'src/kuradesk_chat_view.dart';
