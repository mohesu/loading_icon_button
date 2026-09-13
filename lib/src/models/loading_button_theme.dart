part of '../../loading_icon_button.dart';

/// Defaults for every loading button beneath it.
///
/// This replaces the process-wide [LoadingButtonConfig] singleton, which could
/// not vary by subtree, could not differ between light and dark, and could not
/// reach widgets that were already built. Install it either as a
/// [ThemeExtension] on your [ThemeData]:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const <ThemeExtension<dynamic>>[
///       LoadingButtonThemeData(indicator: LoadingIndicator.orb()),
///     ],
///   ),
/// )
/// ```
///
/// or with a [LoadingButtonTheme] widget around any subtree. A widget-level
/// [LoadingButtonTheme] wins over the [ThemeExtension], which in turn wins over
/// the deprecated [LoadingButtonConfig].
@immutable
class LoadingButtonThemeData extends ThemeExtension<LoadingButtonThemeData> {
  const LoadingButtonThemeData({
    this.indicator,
    this.successWidget,
    this.errorWidget,
    this.sizing,
    this.colors,
    this.colorStrategy,
    this.animationDuration,
    this.successDuration,
    this.errorDuration,
    this.enableHapticFeedback,
    this.progressStyle,
    this.debounce,
    this.cooldown,
  });

  /// What to show while loading.
  final LoadingIndicator? indicator;

  /// What to show on success. Defaults to a check icon.
  final Widget? successWidget;

  /// What to show on failure. Defaults to an error icon.
  final Widget? errorWidget;

  /// How buttons decide their size.
  final LoadingButtonSizing? sizing;

  /// Per-state colours.
  final LoadingButtonColors? colors;

  /// Where colours come from at all.
  final LoadingButtonColorStrategy? colorStrategy;

  /// Duration of state-change transitions.
  final Duration? animationDuration;

  /// How long the success state is held before resetting.
  final Duration? successDuration;

  /// How long the error state is held before resetting.
  final Duration? errorDuration;

  /// Whether a press fires haptic feedback.
  final bool? enableHapticFeedback;

  /// How determinate progress is rendered.
  final LoadingProgressStyle? progressStyle;

  /// Ignore taps arriving within this long of the previous accepted tap.
  final Duration? debounce;

  /// Hold the button disabled for this long after a run completes.
  final Duration? cooldown;

  /// Reads the effective theme data for [context].
  ///
  /// Resolution order: the nearest [LoadingButtonTheme], then the
  /// [ThemeExtension] on [ThemeData], then an empty instance.
  static LoadingButtonThemeData of(BuildContext context) {
    final LoadingButtonTheme? inherited =
        context.dependOnInheritedWidgetOfExactType<LoadingButtonTheme>();
    if (inherited != null) return inherited.data;
    return Theme.of(context).extension<LoadingButtonThemeData>() ??
        const LoadingButtonThemeData();
  }

  @override
  LoadingButtonThemeData copyWith({
    LoadingIndicator? indicator,
    Widget? successWidget,
    Widget? errorWidget,
    LoadingButtonSizing? sizing,
    LoadingButtonColors? colors,
    LoadingButtonColorStrategy? colorStrategy,
    Duration? animationDuration,
    Duration? successDuration,
    Duration? errorDuration,
    bool? enableHapticFeedback,
    LoadingProgressStyle? progressStyle,
    Duration? debounce,
    Duration? cooldown,
  }) =>
      LoadingButtonThemeData(
        indicator: indicator ?? this.indicator,
        successWidget: successWidget ?? this.successWidget,
        errorWidget: errorWidget ?? this.errorWidget,
        sizing: sizing ?? this.sizing,
        colors: colors ?? this.colors,
        colorStrategy: colorStrategy ?? this.colorStrategy,
        animationDuration: animationDuration ?? this.animationDuration,
        successDuration: successDuration ?? this.successDuration,
        errorDuration: errorDuration ?? this.errorDuration,
        enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
        progressStyle: progressStyle ?? this.progressStyle,
        debounce: debounce ?? this.debounce,
        cooldown: cooldown ?? this.cooldown,
      );

  @override
  LoadingButtonThemeData lerp(
    ThemeExtension<LoadingButtonThemeData>? other,
    double t,
  ) {
    if (other is! LoadingButtonThemeData) return this;
    // Widgets, durations and strategies do not interpolate meaningfully, so
    // they snap at the midpoint; only the colours are lerped.
    final bool past = t >= 0.5;
    return LoadingButtonThemeData(
      indicator: past ? other.indicator : indicator,
      successWidget: past ? other.successWidget : successWidget,
      errorWidget: past ? other.errorWidget : errorWidget,
      sizing: past ? other.sizing : sizing,
      colors: _lerpColors(colors, other.colors, t),
      colorStrategy: past ? other.colorStrategy : colorStrategy,
      animationDuration: past ? other.animationDuration : animationDuration,
      successDuration: past ? other.successDuration : successDuration,
      errorDuration: past ? other.errorDuration : errorDuration,
      enableHapticFeedback:
          past ? other.enableHapticFeedback : enableHapticFeedback,
      progressStyle: past ? other.progressStyle : progressStyle,
      debounce: past ? other.debounce : debounce,
      cooldown: past ? other.cooldown : cooldown,
    );
  }

  static LoadingButtonColors? _lerpColors(
    LoadingButtonColors? a,
    LoadingButtonColors? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    return LoadingButtonColors(
      loading: Color.lerp(a?.loading, b?.loading, t),
      onLoading: Color.lerp(a?.onLoading, b?.onLoading, t),
      success: Color.lerp(a?.success, b?.success, t),
      onSuccess: Color.lerp(a?.onSuccess, b?.onSuccess, t),
      error: Color.lerp(a?.error, b?.error, t),
      onError: Color.lerp(a?.onError, b?.onError, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingButtonThemeData &&
          other.indicator == indicator &&
          other.successWidget == successWidget &&
          other.errorWidget == errorWidget &&
          other.sizing == sizing &&
          other.colors == colors &&
          other.colorStrategy == colorStrategy &&
          other.animationDuration == animationDuration &&
          other.successDuration == successDuration &&
          other.errorDuration == errorDuration &&
          other.enableHapticFeedback == enableHapticFeedback &&
          other.progressStyle == progressStyle &&
          other.debounce == debounce &&
          other.cooldown == cooldown;

  @override
  int get hashCode => Object.hash(
        indicator,
        successWidget,
        errorWidget,
        sizing,
        colors,
        colorStrategy,
        animationDuration,
        successDuration,
        errorDuration,
        enableHapticFeedback,
        progressStyle,
        debounce,
        cooldown,
      );
}

/// Applies [LoadingButtonThemeData] to a subtree.
class LoadingButtonTheme extends InheritedWidget {
  const LoadingButtonTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The defaults to apply below this widget.
  final LoadingButtonThemeData data;

  /// The nearest enclosing theme data, or null if there is none.
  static LoadingButtonThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LoadingButtonTheme>()?.data;

  @override
  bool updateShouldNotify(LoadingButtonTheme oldWidget) =>
      oldWidget.data != data;
}
