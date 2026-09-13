part of '../loading_icon_button.dart';

/// Fluent builder for [LoadingButton].
///
/// ```dart
/// LoadingButtonBuilder.elevated()
///     .onPressed(() async => api.submit())
///     .child(const Text('Submit'))
///     .indicator(const LoadingIndicator.orb(state: OrbState.working))
///     .onFailure((error, stack) => report(error, stack))
///     .build();
/// ```
///
/// Every setter mutates this builder and returns it, so a builder is **not** a
/// value: it is mutable and effectively single-use. Two consequences worth
/// knowing:
///
/// * Holding a builder and calling [build] twice returns two *different*
///   widgets that share whatever [key] was set. Mounting both at once is an
///   error — Flutter requires keys to be unique among siblings, and a
///   [GlobalKey] must be unique in the whole tree. Build a fresh builder per
///   widget instead of reusing one.
/// * A setter called after [build] does not change the widget already built;
///   it only affects later [build] calls.
///
/// Create one builder, configure it, build once.
class LoadingButtonBuilder {
  final ButtonType _type;
  AsyncCallback? _onPressed;
  Widget? _child;
  Widget? _loadingWidget;
  Widget? _successWidget;
  Widget? _errorWidget;
  LoadingButtonStyle? _style;
  ButtonStyle? _buttonStyle;
  Duration? _animationDuration;
  Duration? _successDuration;
  Duration? _errorDuration;
  double? _width;
  double? _height;
  LoadingButtonSizing? _sizing;
  String? _loadingText;
  String? _successText;
  String? _errorText;
  bool _resetAfterDuration = true;
  bool? _enableHapticFeedback;
  void Function(dynamic)? _onError;
  void Function(Object error, StackTrace stackTrace)? _onFailure;
  VoidCallback? _onSuccess;
  void Function(ActionState)? _onStateChanged;
  LoadingButtonController? _controller;
  LoadingIndicator? _indicator;
  double? _progress;
  LoadingProgressStyle? _progressStyle;
  LoadingButtonColors? _colors;
  LoadingButtonColorStrategy? _colorStrategy;
  bool _enabled = true;
  Duration? _debounce;
  Duration? _cooldown;
  FocusNode? _focusNode;
  bool _autofocus = false;
  String? _tooltip;
  Widget Function(Widget child, Animation<double> animation)?
      _transitionBuilder;
  Key? _key;
  LoadingButtonBuilder._(this._type);

  /// Create elevated button builder
  factory LoadingButtonBuilder.elevated() =>
      LoadingButtonBuilder._(ButtonType.elevated);

  /// Create filled button builder
  factory LoadingButtonBuilder.filled() =>
      LoadingButtonBuilder._(ButtonType.filled);

  /// Create outlined button builder
  factory LoadingButtonBuilder.outlined() =>
      LoadingButtonBuilder._(ButtonType.outlined);

  /// Create text button builder
  factory LoadingButtonBuilder.text() =>
      LoadingButtonBuilder._(ButtonType.text);

  /// Create icon button builder
  factory LoadingButtonBuilder.icon() =>
      LoadingButtonBuilder._(ButtonType.icon);

  /// Set the button's onPressed callback
  LoadingButtonBuilder onPressed(AsyncCallback? onPressed) {
    _onPressed = onPressed;
    return this;
  }

  /// Set the button's child widget
  LoadingButtonBuilder child(Widget child) {
    _child = child;
    return this;
  }

  /// Set the button's key.
  ///
  /// Remember that a builder can be built more than once; see the class
  /// dartdoc for why sharing a key across those builds is an error.
  LoadingButtonBuilder key(Key key) {
    _key = key;
    return this;
  }

  /// Set custom loading widget
  LoadingButtonBuilder loadingWidget(Widget loadingWidget) {
    _loadingWidget = loadingWidget;
    return this;
  }

  /// Set custom success widget
  LoadingButtonBuilder successWidget(Widget successWidget) {
    _successWidget = successWidget;
    return this;
  }

  /// Set custom error widget
  LoadingButtonBuilder errorWidget(Widget errorWidget) {
    _errorWidget = errorWidget;
    return this;
  }

  /// Set button style
  LoadingButtonBuilder style(LoadingButtonStyle style) {
    _style = style;
    return this;
  }

  /// Set the Material [ButtonStyle] passed through to the underlying button.
  ///
  /// Applied before [style] and the state colours, which layer on top.
  LoadingButtonBuilder buttonStyle(ButtonStyle buttonStyle) {
    _buttonStyle = buttonStyle;
    return this;
  }

  /// Set animation duration
  LoadingButtonBuilder animationDuration(Duration duration) {
    _animationDuration = duration;
    return this;
  }

  /// Set success duration
  LoadingButtonBuilder successDuration(Duration duration) {
    _successDuration = duration;
    return this;
  }

  /// Set error duration
  LoadingButtonBuilder errorDuration(Duration duration) {
    _errorDuration = duration;
    return this;
  }

  /// Set button width
  LoadingButtonBuilder width(double width) {
    _width = width;
    return this;
  }

  /// Set button height
  LoadingButtonBuilder height(double height) {
    _height = height;
    return this;
  }

  /// Set how the button decides its size.
  ///
  /// Ignored for whichever of width/height is also set explicitly.
  LoadingButtonBuilder sizing(LoadingButtonSizing sizing) {
    _sizing = sizing;
    return this;
  }

  /// Set loading text
  LoadingButtonBuilder loadingText(String text) {
    _loadingText = text;
    return this;
  }

  /// Set success text
  LoadingButtonBuilder successText(String text) {
    _successText = text;
    return this;
  }

  /// Set error text
  LoadingButtonBuilder errorText(String text) {
    _errorText = text;
    return this;
  }

  /// Set whether to reset after duration
  LoadingButtonBuilder resetAfterDuration(bool reset) {
    _resetAfterDuration = reset;
    return this;
  }

  /// Set whether to enable haptic feedback
  LoadingButtonBuilder enableHapticFeedback(bool enable) {
    _enableHapticFeedback = enable;
    return this;
  }

  /// Set error handler
  @Deprecated(
    'Use onFailure, which also receives the StackTrace. '
    'This feature was deprecated after v1.1.0.',
  )
  LoadingButtonBuilder onError(void Function(dynamic) onError) {
    _onError = onError;
    return this;
  }

  /// Set the failure handler, called with the error and its stack trace when
  /// the [onPressed] callback throws.
  LoadingButtonBuilder onFailure(
    void Function(Object error, StackTrace stackTrace) onFailure,
  ) {
    _onFailure = onFailure;
    return this;
  }

  /// Set the handler called when the [onPressed] callback completes without
  /// throwing.
  LoadingButtonBuilder onSuccess(VoidCallback onSuccess) {
    _onSuccess = onSuccess;
    return this;
  }

  /// Set state change handler
  LoadingButtonBuilder onStateChanged(
    void Function(ActionState) onStateChanged,
  ) {
    _onStateChanged = onStateChanged;
    return this;
  }

  /// Drive the button's state from outside the widget tree.
  LoadingButtonBuilder controller(LoadingButtonController controller) {
    _controller = controller;
    return this;
  }

  /// Set what is shown while loading — a spinner, a [ThinkingOrb], or your own
  /// widget or builder.
  LoadingButtonBuilder indicator(LoadingIndicator indicator) {
    _indicator = indicator;
    return this;
  }

  /// Set determinate progress in 0.0..1.0, or null for indeterminate.
  ///
  /// A [controller]'s progress wins over this when one is attached.
  LoadingButtonBuilder progress(double? progress) {
    _progress = progress;
    return this;
  }

  /// Set how determinate progress is rendered.
  LoadingButtonBuilder progressStyle(LoadingProgressStyle progressStyle) {
    _progressStyle = progressStyle;
    return this;
  }

  /// Set the per-state colours.
  LoadingButtonBuilder colors(LoadingButtonColors colors) {
    _colors = colors;
    return this;
  }

  /// Set where colours come from.
  LoadingButtonBuilder colorStrategy(LoadingButtonColorStrategy strategy) {
    _colorStrategy = strategy;
    return this;
  }

  /// Set whether the button accepts presses. False shows
  /// [ActionState.disabled].
  LoadingButtonBuilder enabled(bool enabled) {
    _enabled = enabled;
    return this;
  }

  /// Ignore taps arriving within this long of the previously accepted tap.
  LoadingButtonBuilder debounce(Duration debounce) {
    _debounce = debounce;
    return this;
  }

  /// Hold the button disabled for this long after a run completes.
  LoadingButtonBuilder cooldown(Duration cooldown) {
    _cooldown = cooldown;
    return this;
  }

  /// Set the focus node.
  ///
  /// A [FocusNode] is a disposable object owned by the caller; do not hand the
  /// same one to two buttons that are mounted at the same time.
  LoadingButtonBuilder focusNode(FocusNode focusNode) {
    _focusNode = focusNode;
    return this;
  }

  /// Set whether the button takes focus when first mounted.
  LoadingButtonBuilder autofocus(bool autofocus) {
    _autofocus = autofocus;
    return this;
  }

  /// Set the tooltip shown on hover and long-press.
  LoadingButtonBuilder tooltip(String tooltip) {
    _tooltip = tooltip;
    return this;
  }

  /// Wrap the per-state child for a custom transition. Defaults to a cross
  /// fade.
  LoadingButtonBuilder transitionBuilder(
    Widget Function(Widget child, Animation<double> animation)
        transitionBuilder,
  ) {
    _transitionBuilder = transitionBuilder;
    return this;
  }

  /// Build the LoadingButton widget.
  ///
  /// Safe to call once per builder. See the class dartdoc before calling it
  /// twice.
  Widget build() {
    return LoadingButton(
      key: _key,
      type: _type,
      onPressed: _onPressed,
      loadingWidget: _loadingWidget,
      successWidget: _successWidget,
      errorWidget: _errorWidget,
      style: _style,
      buttonStyle: _buttonStyle,
      animationDuration: _animationDuration,
      successDuration: _successDuration,
      errorDuration: _errorDuration,
      width: _width,
      height: _height,
      sizing: _sizing,
      loadingText: _loadingText,
      successText: _successText,
      errorText: _errorText,
      resetAfterDuration: _resetAfterDuration,
      enableHapticFeedback: _enableHapticFeedback,
      // ignore: deprecated_member_use_from_same_package
      onError: _onError,
      onFailure: _onFailure,
      onSuccess: _onSuccess,
      onStateChanged: _onStateChanged,
      controller: _controller,
      indicator: _indicator,
      progress: _progress,
      progressStyle: _progressStyle,
      colors: _colors,
      colorStrategy: _colorStrategy,
      enabled: _enabled,
      debounce: _debounce,
      cooldown: _cooldown,
      focusNode: _focusNode,
      autofocus: _autofocus,
      tooltip: _tooltip,
      transitionBuilder: _transitionBuilder,
      child: _child,
    );
  }
}
