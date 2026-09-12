part of '../../loading_icon_button.dart';

/// Global configuration for LoadingButton.
///
/// Still read as the last fallback by [LoadingButton], after the widget's own
/// arguments and after [LoadingButtonThemeData], so existing code that mutates
/// it keeps working exactly as before. New code should not use it.
///
/// ## Why this is deprecated
///
/// It is a mutable, process-wide singleton, and that makes it wrong in ways no
/// amount of care at the call site can fix:
///
/// * **It cannot vary by subtree.** There is exactly one instance per process,
///   so a settings page and a checkout flow cannot have different button
///   defaults. [LoadingButtonTheme] is an [InheritedWidget] and scopes to
///   whatever subtree you wrap.
/// * **It cannot vary by brightness.** The values are plain fields with no
///   access to a [BuildContext], so they cannot respond to the ambient
///   [ThemeData.brightness] or [ColorScheme]. The same literal colours are
///   handed to light and dark alike. [LoadingButtonThemeData] is a
///   [ThemeExtension], so it is resolved per theme and animates with it.
/// * **[reset] cannot reach already-built widgets.** It swaps the singleton
///   instance, but nothing is listening: widgets that already read a value
///   keep the old one until something else happens to rebuild them, so the
///   tree ends up in a half-reset state. A [ThemeExtension] change rebuilds
///   its dependents.
/// * **It holds widgets, not colours.** The defaults now inherit the button's
///   resolved foreground rather than hard-coding [Colors.white] (which was
///   invisible on a light container), but they still cannot vary by subtree or
///   by brightness. [LoadingButtonThemeData.successWidget] and friends can.
///
/// Migrate by moving these values into a [LoadingButtonThemeData], installed
/// either as a [ThemeExtension] on your [ThemeData] or with a
/// [LoadingButtonTheme] widget around the subtree that needs them.
@Deprecated(
  'Use LoadingButtonThemeData with LoadingButtonTheme (or as a ThemeExtension '
  'on ThemeData) instead: it scopes to a subtree, resolves per brightness, and '
  'rebuilds its dependents. '
  'This feature was deprecated after v1.1.0.',
)
class LoadingButtonConfig {
  static LoadingButtonConfig _instance = LoadingButtonConfig._internal();

  factory LoadingButtonConfig() => _instance;

  LoadingButtonConfig._internal();

  /// Default animation duration for all buttons
  Duration defaultAnimationDuration = const Duration(milliseconds: 300);

  /// Default loading widget
  /// Inherits its colour and size from the enclosing [IconTheme], which every
  /// Material button derives from its resolved foreground colour. Before 1.1.0
  /// this hard-coded [Colors.white] and was invisible on a light container.
  Widget defaultLoadingWidget = const _LoadingChild();

  /// Default success widget
  /// Deliberately has no explicit colour, so it inherits the button's resolved
  /// foreground instead of painting white on whatever container it lands on.
  Widget defaultSuccessWidget = const Icon(Icons.check, size: 20);

  /// Default error widget
  /// Deliberately has no explicit colour, so it inherits the button's resolved
  /// foreground instead of painting white on whatever container it lands on.
  Widget defaultErrorWidget = const Icon(Icons.error, size: 20);

  /// Default button height
  double defaultHeight = 50.0;

  /// Default button width
  double defaultWidth = 200.0;

  /// Default border radius
  double defaultBorderRadius = 8.0;

  /// Default success duration
  Duration defaultSuccessDuration = const Duration(seconds: 2);

  /// Default error duration
  Duration defaultErrorDuration = const Duration(seconds: 2);

  /// Whether to enable haptic feedback
  bool enableHapticFeedback = true;

  /// Whether to enable debug mode
  bool debugMode = false;

  /// Reset to default values
  void reset() {
    _instance = LoadingButtonConfig._internal();
  }
}
