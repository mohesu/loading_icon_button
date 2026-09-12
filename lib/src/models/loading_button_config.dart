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
/// * **The default widgets bake in [Colors.white].** [defaultLoadingWidget],
///   [defaultSuccessWidget] and [defaultErrorWidget] are const widgets with a
///   hard-coded white foreground. That is invisible on a light surface — on an
///   [OutlinedButton] or a [TextButton], or on any filled button whose
///   container colour is light. [LoadingButtonColors] and
///   [LoadingButtonColorStrategy.material3] derive the foreground from the
///   [ColorScheme] instead.
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
  Widget defaultLoadingWidget = const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    ),
  );

  /// Default success widget
  Widget defaultSuccessWidget = const Icon(
    Icons.check,
    color: Colors.white,
    size: 20,
  );

  /// Default error widget
  Widget defaultErrorWidget = const Icon(
    Icons.error,
    color: Colors.white,
    size: 20,
  );

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
