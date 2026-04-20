import 'package:flutter/widgets.dart';

/// Wraps a widget so hovering it shows the click (pointer) cursor. fluent_ui
/// buttons default to MouseCursor.defer, which reads as "not interactive" to
/// users coming from the web. Apply this at button call sites so Run /
/// Cancel / pill actions feel clickable before being clicked.
Widget clickable(Widget child) =>
    MouseRegion(cursor: SystemMouseCursors.click, child: child);
