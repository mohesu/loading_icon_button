part of '../../loading_icon_button.dart';

/// What to show while a button is busy.
///
/// One type, understood by every button family in the package, so switching a
/// whole app from spinners to [ThinkingOrb]s is a single line:
///
/// ```dart
/// LoadingButtonTheme(
///   data: const LoadingButtonThemeData(
///     indicator: LoadingIndicator.orb(state: OrbState.working),
///   ),
///   child: myApp,
/// )
/// ```
///
/// Sizes and colours default to the ambient [IconTheme], so an indicator picks
/// up the button's resolved foreground colour automatically in both
/// brightnesses.
sealed class LoadingIndicator {
  const LoadingIndicator();

  /// A [CircularProgressIndicator]. The package default.
  const factory LoadingIndicator.circular({
    double? size,
    double strokeWidth,
    Color? color,
  }) = _CircularIndicator;

  /// One of the nine [ThinkingOrb] animations.
  ///
  /// Orbs are indeterminate by design; when a button is reporting determinate
  /// progress, prefer [LoadingProgressStyle.fill] to show it.
  const factory LoadingIndicator.orb({
    OrbState state,
    double? size,
    Color? color,
    double speed,
  }) = _OrbIndicator;

  /// Any widget.
  const factory LoadingIndicator.widget(Widget child) = _WidgetIndicator;

  /// A builder, for indicators that depend on context or on progress.
  const factory LoadingIndicator.builder(
    Widget Function(BuildContext context, double? progress) builder,
  ) = _BuilderIndicator;

  /// Builds the indicator. [progress] is null when indeterminate.
  Widget build(BuildContext context, {double? progress});
}

class _CircularIndicator extends LoadingIndicator {
  const _CircularIndicator({
    this.size,
    this.strokeWidth = 2,
    this.color,
  });

  final double? size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context, {double? progress}) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final double dimension = size ?? iconTheme.size ?? 24;
    return SizedBox.square(
      dimension: dimension,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: strokeWidth,
          color: color ?? iconTheme.color,
        ),
      ),
    );
  }
}

class _OrbIndicator extends LoadingIndicator {
  const _OrbIndicator({
    this.state = OrbState.working,
    this.size,
    this.color,
    this.speed = 1,
  });

  final OrbState state;
  final double? size;
  final Color? color;
  final double speed;

  @override
  Widget build(BuildContext context, {double? progress}) {
    final IconThemeData iconTheme = IconTheme.of(context);
    return ThinkingOrb(
      state: state,
      size: size ?? iconTheme.size ?? 24,
      color: color ?? iconTheme.color,
      speed: speed,
      // The button already publishes a "Loading" semantics label; a second
      // one here would double-announce.
      semanticLabel: '',
    );
  }
}

class _WidgetIndicator extends LoadingIndicator {
  const _WidgetIndicator(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context, {double? progress}) => child;
}

class _BuilderIndicator extends LoadingIndicator {
  const _BuilderIndicator(this.builder);

  final Widget Function(BuildContext context, double? progress) builder;

  @override
  Widget build(BuildContext context, {double? progress}) =>
      builder(context, progress);
}

/// How determinate progress is shown on a [LoadingButton].
enum LoadingProgressStyle {
  /// The loading indicator becomes determinate. The default.
  indicator,

  /// The button background fills left to right, clipped to the button's shape.
  fill,

  /// Both at once.
  both,
}
