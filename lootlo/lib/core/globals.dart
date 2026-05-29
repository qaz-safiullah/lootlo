import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// NEW: Global Reactive Theme State (Defaults to system preference)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);