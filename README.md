# kuradesk_chat (Flutter)

In-app chat UI for KuraDesk — same plugin API as the web widget. Conversations land in your shared team inbox.

## Install

```sh
flutter pub add kuradesk_chat
```

Or add it to your `pubspec.yaml`:

```yaml
dependencies:
  kuradesk_chat: ^0.3.2
```

Then import it:

```dart
import 'package:kuradesk_chat/kuradesk_chat.dart';
```

Setup guide: https://desk.kurasika.tech/downloads/

## Server-driven branding (no app rebuild)

Configure in **KuraDesk → Settings → Chat plugins**:

- Logo URL, primary color, welcome message
- Header title & subtitle
- Launcher hint text (floating button)
- Footer text and show/hide powered-by line

The app fetches these from `GET /api/plugin/v1/config/:widgetKey` on each open.

## Full-screen chat

```dart
KuradeskChatView(
  apiBaseUrl: 'https://desk.kurasika.tech',
  widgetKey: 'YOUR_WIDGET_PUBLIC_KEY',
)
```

## Floating launcher

```dart
KuradeskChatLauncher(
  apiBaseUrl: 'https://desk.kurasika.tech',
  widgetKey: 'YOUR_WIDGET_PUBLIC_KEY',
  child: YourAppHome(),
)
```

## Theme

Follows the device light/dark mode automatically. Accent color comes from the widget settings in KuraDesk.
