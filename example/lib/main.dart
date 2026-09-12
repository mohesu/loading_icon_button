import 'package:flutter/material.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

import 'pages/argon_page.dart';
import 'pages/auto_loading_page.dart';
import 'pages/loading_button_page.dart';
import 'pages/orbs_page.dart';
import 'pages/overview_page.dart';

void main() => runApp(const GalleryApp());

/// The gallery shell: Material 3, a seeded colour scheme, and a light/dark
/// toggle so every demo can be checked in both brightnesses.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleBrightness(Brightness current) {
    setState(() {
      _themeMode =
          current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  /// One theme builder for both brightnesses.
  ///
  /// Note the [LoadingButtonThemeData] extension: it sets package-wide
  /// defaults that resolve per brightness and rebuild their dependents, which
  /// is what replaced the old process-wide `LoadingButtonConfig` singleton.
  /// Individual demos below still override these per widget.
  ThemeData _theme(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4C5DF4),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: const <ThemeExtension<dynamic>>[
        LoadingButtonThemeData(
          // The modern defaults. `LoadingButtonSizing.legacy` (a fixed 200x50
          // box) is still the package default for backwards compatibility;
          // new apps should opt into intrinsic sizing like this.
          sizing: LoadingButtonSizing.intrinsic(),
          colorStrategy: LoadingButtonColorStrategy.material3,
          animationDuration: Duration(milliseconds: 250),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'loading_icon_button gallery',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: GalleryHome(onToggleBrightness: _toggleBrightness),
    );
  }
}

/// A gallery destination: its label, its icons and the page it shows.
class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const List<_Destination> _destinations = <_Destination>[
  _Destination('Overview', Icons.dashboard_outlined, Icons.dashboard),
  _Destination(
      'LoadingButton', Icons.smart_button_outlined, Icons.smart_button),
  _Destination('Auto-loading', Icons.autorenew_outlined, Icons.autorenew),
  _Destination('Argon', Icons.swipe_left_outlined, Icons.swipe_left),
  _Destination('Thinking orbs', Icons.blur_on_outlined, Icons.blur_on),
];

/// The navigation shell. A rail on wide windows, a bottom bar on narrow ones.
class GalleryHome extends StatefulWidget {
  const GalleryHome({super.key, required this.onToggleBrightness});

  /// Called with the currently resolved brightness when the toggle is tapped.
  final void Function(Brightness current) onToggleBrightness;

  @override
  State<GalleryHome> createState() => _GalleryHomeState();
}

class _GalleryHomeState extends State<GalleryHome> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  Widget _page(int index) {
    switch (index) {
      case 1:
        return const LoadingButtonPage();
      case 2:
        return const AutoLoadingPage();
      case 3:
        return const ArgonPage();
      case 4:
        return const OrbsPage();
      case 0:
      default:
        return OverviewPage(onNavigate: _select);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 880;

        final Widget body = Row(
          children: <Widget>[
            if (wide)
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                destinations: <NavigationRailDestination>[
                  for (final _Destination d in _destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
            if (wide) const VerticalDivider(width: 1),
            Expanded(
              // A key per index so switching pages rebuilds from scratch
              // rather than reusing the previous page's element tree.
              child: KeyedSubtree(
                key: ValueKey<int>(_index),
                child: _page(_index),
              ),
            ),
          ],
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(_destinations[_index].label),
            actions: <Widget>[
              IconButton(
                key: const Key('theme-toggle'),
                tooltip:
                    isDark ? 'Switch to light theme' : 'Switch to dark theme',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => widget.onToggleBrightness(brightness),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(child: body),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  destinations: <NavigationDestination>[
                    for (final _Destination d in _destinations)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: d.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
