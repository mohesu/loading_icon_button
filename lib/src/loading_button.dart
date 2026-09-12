part of '../loading_icon_button.dart';

/// A button that runs an async callback and shows its progress.
///
/// [LoadingButton] owns a small state machine — [ActionState.idle] to
/// [ActionState.loading] to [ActionState.success] or [ActionState.error], and
/// back to idle — and renders one of the five Material button types
/// ([ButtonType]) for it.
///
/// ```dart
/// LoadingButton(
///   onPressed: () async => api.submit(),
///   child: const Text('Submit'),
///   onFailure: (Object error, StackTrace stack) => report(error, stack),
/// )
/// ```
///
/// Pass a [controller] to drive the state from outside, [progress] to show a
/// determinate indicator, and [indicator] to swap the spinner for a
/// [ThinkingOrb] or anything else. Defaults for all of those can be set for a
/// whole subtree with [LoadingButtonTheme].
///
/// Repeat presses are rejected while a run is in flight, including during the
/// press animation, so an async callback cannot be started twice by a fast
/// double tap.
class LoadingButton extends StatefulWidget {
  /// Creates a LoadingButton.
  const LoadingButton({
    super.key,
    this.type = ButtonType.elevated,
    this.onPressed,
    this.child,
    this.loadingWidget,
    this.successWidget,
    this.errorWidget,
    this.style,
    this.buttonStyle,
    this.animationDuration,
    this.successDuration,
    this.errorDuration,
    this.width,
    this.height,
    this.sizing,
    this.loadingText,
    this.successText,
    this.errorText,
    this.resetAfterDuration = true,
    this.enableHapticFeedback,
    @Deprecated(
      'Use onFailure, which also receives the StackTrace. '
      'This feature was deprecated after v1.1.0.',
    )
    this.onError,
    this.onFailure,
    this.onSuccess,
    this.onStateChanged,
    this.controller,
    this.indicator,
    this.progress,
    this.progressStyle,
    this.colors,
    this.colorStrategy,
    this.enabled = true,
    this.debounce,
    this.cooldown,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.transitionBuilder,
  }) : assert(
          progress == null || (progress >= 0.0 && progress <= 1.0),
          'progress must be null (indeterminate) or within 0.0..1.0',
        );

  /// Which Material button to render.
  final ButtonType type;

  /// Called when the button is pressed.
  ///
  /// The button stays in [ActionState.loading] until the returned future
  /// settles. If it throws, the button shows [ActionState.error] and
  /// [onFailure] is called.
  final AsyncCallback? onPressed;

  /// Shown in [ActionState.idle].
  final Widget? child;

  /// Shown while loading. Wins over [indicator] and the theme.
  final Widget? loadingWidget;

  /// Shown on success. Wins over the theme.
  final Widget? successWidget;

  /// Shown on failure. Wins over the theme.
  final Widget? errorWidget;

  /// Package-specific style overrides.
  ///
  /// For anything Material already models, prefer [buttonStyle].
  final LoadingButtonStyle? style;

  /// A standard Material [ButtonStyle], passed through to the underlying
  /// button. Applied first; [style] and the state colours layer on top.
  final ButtonStyle? buttonStyle;

  /// Duration of state-change transitions.
  final Duration? animationDuration;

  /// How long [ActionState.success] is held before resetting.
  final Duration? successDuration;

  /// How long [ActionState.error] is held before resetting.
  final Duration? errorDuration;

  /// Fixed width. Overrides whatever [sizing] computes.
  final double? width;

  /// Fixed height. Overrides whatever [sizing] computes.
  final double? height;

  /// How the button decides its size.
  ///
  /// Defaults to [LoadingButtonSizing.legacy] — a fixed 200x50 box — for
  /// backwards compatibility. New code should prefer
  /// [LoadingButtonSizing.intrinsic].
  final LoadingButtonSizing? sizing;

  /// Accessible description and, when no [loadingWidget] is set, the label
  /// shown while loading.
  final String? loadingText;

  /// Accessible description and, when no [successWidget] is set, the label
  /// shown on success.
  final String? successText;

  /// Accessible description and, when no [errorWidget] is set, the label shown
  /// on failure.
  final String? errorText;

  /// Whether to return to idle after the success or error window elapses.
  ///
  /// When false the button stays in its terminal state; drive it back with a
  /// [controller] or by rebuilding.
  final bool resetAfterDuration;

  /// Whether a press fires haptic feedback.
  final bool? enableHapticFeedback;

  /// Called when [onPressed] throws.
  @Deprecated(
    'Use onFailure, which also receives the StackTrace. '
    'This feature was deprecated after v1.1.0.',
  )
  final void Function(dynamic)? onError;

  /// Called when [onPressed] throws, with the error and its stack trace.
  final void Function(Object error, StackTrace stackTrace)? onFailure;

  /// Called when [onPressed] completes without throwing.
  final VoidCallback? onSuccess;

  /// Called whenever the state changes. Not called for the initial state.
  final void Function(ActionState state)? onStateChanged;

  /// Drives the button's state from outside the widget tree.
  final LoadingButtonController? controller;

  /// What to show while loading. Overridden by [loadingWidget].
  final LoadingIndicator? indicator;

  /// Determinate progress in 0.0..1.0, or null for indeterminate.
  ///
  /// A [controller]'s progress wins over this when one is attached.
  final double? progress;

  /// How determinate progress is rendered.
  final LoadingProgressStyle? progressStyle;

  /// Per-state colours.
  final LoadingButtonColors? colors;

  /// Where colours come from.
  final LoadingButtonColorStrategy? colorStrategy;

  /// Whether the button accepts presses. False shows [ActionState.disabled].
  final bool enabled;

  /// Ignore taps arriving within this long of the previously accepted tap.
  final Duration? debounce;

  /// Hold the button disabled for this long after a run completes.
  final Duration? cooldown;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Tooltip shown on hover and long-press.
  final String? tooltip;

  /// Wraps the per-state child, for a custom transition. Defaults to a cross
  /// fade.
  final Widget Function(Widget child, Animation<double> animation)?
      transitionBuilder;

  @override
  State<LoadingButton> createState() => LoadingButtonState();
}

/// The [State] for a [LoadingButton].
///
/// Exposed so a `GlobalKey<LoadingButtonState>` can reach [press] and
/// [currentState], but a [LoadingButtonController] is usually the better tool.
class LoadingButtonState extends State<LoadingButton>
    implements _LoadingButtonBinding {
  late final ValueNotifier<LoadingButtonValue> _internal =
      ValueNotifier<LoadingButtonValue>(LoadingButtonValue.idle);

  Timer? _resetTimer;

  /// Guards the whole press path synchronously, before the first await, so a
  /// double tap cannot start two runs.
  bool _pressLatch = false;

  DateTime? _lastAcceptedPress;

  ValueNotifier<LoadingButtonValue> get _notifier =>
      widget.controller ?? _internal;

  LoadingButtonValue get _value => _notifier.value;

  /// The button's current phase.
  ActionState get currentState => _value.state;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _notifier.addListener(_onValueChanged);
    if (!widget.enabled) {
      _notifier.value = _value.copyWith(state: ActionState.disabled);
    }
  }

  @override
  void didUpdateWidget(LoadingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final LoadingButton old = oldWidget;
    if (old.controller != widget.controller) {
      old.controller?._detach(this);
      (old.controller ?? _internal).removeListener(_onValueChanged);
      widget.controller?._attach(this);
      _notifier.addListener(_onValueChanged);
    }
    if (old.enabled != widget.enabled && !_value.isLoading) {
      _notifier.value = _value.copyWith(
        state: widget.enabled ? ActionState.idle : ActionState.disabled,
      );
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _resetTimer = null;
    widget.controller?._detach(this);
    _notifier.removeListener(_onValueChanged);
    _internal.dispose();
    super.dispose();
  }

  void _onValueChanged() {
    if (!mounted) return;
    setState(() {});
    widget.onStateChanged?.call(_value.state);
    _scheduleReset(_value.state);
  }

  void _setValue(LoadingButtonValue value) {
    if (!mounted) return;
    _notifier.value = value;
  }

  void _scheduleReset(ActionState state) {
    _resetTimer?.cancel();
    _resetTimer = null;
    if (!widget.resetAfterDuration) return;
    final Duration? window = switch (state) {
      ActionState.success => _effectiveSuccessDuration,
      ActionState.error => _effectiveErrorDuration,
      _ => null,
    };
    if (window == null) return;
    _resetTimer = Timer(window, () {
      _resetTimer = null;
      if (!mounted) return;
      // Only reset if we are still in the state that scheduled this.
      if (_value.state != state) return;
      final Duration cooldown = _effectiveCooldown;
      if (cooldown > Duration.zero) {
        final LoadingButtonController? controller = widget.controller;
        if (controller != null) {
          controller.startCooldown(cooldown);
        } else {
          _setValue(const LoadingButtonValue(state: ActionState.disabled));
          _resetTimer = Timer(cooldown, () {
            _resetTimer = null;
            if (mounted) _setValue(LoadingButtonValue.idle);
          });
        }
        return;
      }
      _setValue(
        widget.enabled
            ? LoadingButtonValue.idle
            : const LoadingButtonValue(state: ActionState.disabled),
      );
    });
  }

  /// Runs [LoadingButton.onPressed] exactly as a tap would.
  Future<void> press() => _invokePressed();

  @override
  Future<void> _invokePressed() async {
    // Synchronous latch FIRST: every early return below must leave it clear,
    // and nothing may await before it is set.
    if (_pressLatch) return;
    if (_value.state != ActionState.idle) return;
    if (!widget.enabled) return;

    final Duration debounce = _effectiveDebounce;
    if (debounce > Duration.zero) {
      final DateTime? last = _lastAcceptedPress;
      if (last != null && DateTime.now().difference(last) < debounce) return;
    }

    final AsyncCallback? onPressed = widget.onPressed;
    if (onPressed == null) return;

    _pressLatch = true;
    _lastAcceptedPress = DateTime.now();
    try {
      // Fire and forget: awaiting the platform channel would delay the user's
      // callback by a round trip, and on a test binding it never resolves.
      if (_effectiveHaptics) {
        unawaited(HapticFeedback.lightImpact());
      }

      _setValue(const LoadingButtonValue(state: ActionState.loading));
      try {
        await onPressed();
        if (!mounted) return;
        _setValue(const LoadingButtonValue(state: ActionState.success));
        widget.onSuccess?.call();
      } catch (error, stackTrace) {
        if (mounted) {
          _setValue(LoadingButtonValue(
            state: ActionState.error,
            error: error,
            stackTrace: stackTrace,
          ));
        }
        widget.onFailure?.call(error, stackTrace);
        // ignore: deprecated_member_use_from_same_package
        widget.onError?.call(error);
        if (widget.onFailure == null && widget.onError == null) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'loading_icon_button',
            context: ErrorDescription('while running LoadingButton.onPressed'),
          ));
        }
      }
    } finally {
      _pressLatch = false;
    }
  }

  // --- resolved configuration ------------------------------------------

  LoadingButtonThemeData get _theme => LoadingButtonThemeData.of(context);

  // ignore: deprecated_member_use_from_same_package
  LoadingButtonConfig get _config => LoadingButtonConfig();

  Duration get _effectiveAnimationDuration =>
      widget.animationDuration ??
      _theme.animationDuration ??
      _config.defaultAnimationDuration;

  Duration get _effectiveSuccessDuration =>
      widget.successDuration ??
      _theme.successDuration ??
      _config.defaultSuccessDuration;

  Duration get _effectiveErrorDuration =>
      widget.errorDuration ??
      _theme.errorDuration ??
      _config.defaultErrorDuration;

  bool get _effectiveHaptics =>
      widget.enableHapticFeedback ??
      _theme.enableHapticFeedback ??
      _config.enableHapticFeedback;

  Duration get _effectiveDebounce =>
      widget.debounce ?? _theme.debounce ?? Duration.zero;

  Duration get _effectiveCooldown =>
      widget.cooldown ?? _theme.cooldown ?? Duration.zero;

  LoadingButtonSizing get _effectiveSizing =>
      widget.sizing ?? _theme.sizing ?? LoadingButtonSizing.legacy;

  LoadingProgressStyle get _effectiveProgressStyle =>
      widget.progressStyle ??
      _theme.progressStyle ??
      LoadingProgressStyle.indicator;

  LoadingButtonColorStrategy get _effectiveColorStrategy =>
      widget.colorStrategy ??
      _theme.colorStrategy ??
      LoadingButtonColorStrategy.legacy;

  LoadingButtonColors get _effectiveColors {
    final LoadingButtonColors? explicit = widget.colors ?? _theme.colors;
    if (explicit != null) return explicit;
    return switch (_effectiveColorStrategy) {
      LoadingButtonColorStrategy.legacy => LoadingButtonColors.legacy,
      LoadingButtonColorStrategy.material3 =>
        LoadingButtonColors.fromScheme(Theme.of(context).colorScheme),
    };
  }

  double? get _effectiveProgress =>
      widget.controller != null ? _value.progress : widget.progress;

  double get _borderRadius =>
      widget.style?.borderRadius ?? _config.defaultBorderRadius;

  // --- child ------------------------------------------------------------

  Widget _buildChild() {
    final double? progress = _effectiveProgress;
    final bool showDeterminate =
        _effectiveProgressStyle != LoadingProgressStyle.fill;

    final Widget content = switch (_value.state) {
      ActionState.loading => widget.loadingWidget ??
          (widget.loadingText != null
              ? Text(widget.loadingText!)
              : (widget.indicator ?? _theme.indicator)?.build(context,
                      progress: showDeterminate ? progress : null) ??
                  _defaultLoadingWidget(showDeterminate ? progress : null)),
      ActionState.success => widget.successWidget ??
          (widget.successText != null
              ? Text(widget.successText!)
              : _theme.successWidget ?? _config.defaultSuccessWidget),
      ActionState.error => widget.errorWidget ??
          (widget.errorText != null
              ? Text(widget.errorText!)
              : _theme.errorWidget ?? _config.defaultErrorWidget),
      ActionState.idle ||
      ActionState.disabled =>
        widget.child ?? const SizedBox.shrink(),
    };

    final String? label = _transientSemanticLabel();
    final Widget labelled = label == null
        ? content
        : Semantics(
            label: label,
            liveRegion: true,
            // The label already says everything; keeping the child's own
            // semantics too would announce it twice.
            excludeSemantics: true,
            child: content,
          );

    return AnimatedSwitcher(
      duration: _effectiveAnimationDuration,
      transitionBuilder: widget.transitionBuilder ??
          (Widget child, Animation<double> animation) =>
              FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey<ActionState>(_value.state),
        child: labelled,
      ),
    );
  }

  Widget _defaultLoadingWidget(double? progress) {
    if (progress == null) return _config.defaultLoadingWidget;
    return SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(value: progress, strokeWidth: 2),
    );
  }

  /// A description for the states whose visual is not self-describing.
  ///
  /// Idle returns null so the button's own child provides its accessible name,
  /// rather than this widget inventing a second one.
  String? _transientSemanticLabel() => switch (_value.state) {
        ActionState.loading => widget.loadingText ?? 'Loading',
        ActionState.success => widget.successText ?? 'Success',
        ActionState.error => widget.errorText ?? 'Error',
        ActionState.idle || ActionState.disabled => null,
      };

  // --- colours ----------------------------------------------------------

  Color? _backgroundColor() {
    final LoadingButtonStyle? style = widget.style;
    final LoadingButtonColors colors = _effectiveColors;
    final bool legacy =
        _effectiveColorStrategy == LoadingButtonColorStrategy.legacy;
    return switch (_value.state) {
      ActionState.loading => style?.loadingBackgroundColor ??
          colors.loading ??
          style?.backgroundColor ??
          (legacy ? Theme.of(context).primaryColor : null),
      ActionState.success => style?.successBackgroundColor ?? colors.success,
      ActionState.error => style?.errorBackgroundColor ?? colors.error,
      ActionState.disabled => style?.disabledBackgroundColor,
      ActionState.idle => style?.backgroundColor ??
          (legacy ? Theme.of(context).primaryColor : null),
    };
  }

  Color? _foregroundColor() {
    final LoadingButtonStyle? style = widget.style;
    final LoadingButtonColors colors = _effectiveColors;
    final bool legacy =
        _effectiveColorStrategy == LoadingButtonColorStrategy.legacy;
    return switch (_value.state) {
      ActionState.disabled => style?.disabledForegroundColor ??
          (legacy ? Colors.grey.shade400 : null),
      ActionState.loading => colors.onLoading ??
          style?.foregroundColor ??
          (legacy ? Colors.white : null),
      ActionState.success => colors.onSuccess ??
          style?.foregroundColor ??
          (legacy ? Colors.white : null),
      ActionState.error => colors.onError ??
          style?.foregroundColor ??
          (legacy ? Colors.white : null),
      ActionState.idle =>
        style?.foregroundColor ?? (legacy ? Colors.white : null),
    };
  }

  // --- build ------------------------------------------------------------

  bool get _isEnabled =>
      widget.enabled &&
      _value.state == ActionState.idle &&
      widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    Widget button = _buildButtonByType();

    final double? progress = _effectiveProgress;
    final LoadingProgressStyle progressStyle = _effectiveProgressStyle;
    if (progress != null &&
        _value.isLoading &&
        progressStyle != LoadingProgressStyle.indicator) {
      button = _withProgressFill(button, progress);
    }

    button = _applySizing(button);

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }

  /// Overlays a left-to-right fill, clipped to the button's own shape.
  Widget _withProgressFill(Widget button, double progress) {
    final Color? tint = _foregroundColor();
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: <Widget>[
        button,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_borderRadius),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: ColoredBox(
                    color: (tint ?? Colors.white).withAlpha(48),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _applySizing(Widget button) {
    final LoadingButtonSizing sizing = _effectiveSizing;
    final double? width = widget.width;
    final double? height = widget.height;

    switch (sizing) {
      case _IntrinsicSizing(constraints: final BoxConstraints? constraints):
        Widget result = AnimatedSize(
          duration: _effectiveAnimationDuration,
          child: button,
        );
        if (width != null || height != null) {
          result = SizedBox(width: width, height: height, child: result);
        }
        if (constraints != null) {
          result = ConstrainedBox(constraints: constraints, child: result);
        }
        return result;
      case _ExpandSizing(height: final double? modeHeight):
        return SizedBox(
          width: width ?? double.infinity,
          height: height ?? modeHeight,
          child: button,
        );
      case _FixedSizing(width: final double? w, height: final double? h):
        return SizedBox(width: width ?? w, height: height ?? h, child: button);
      case _LegacySizing():
        // Pre-1.1.0 geometry, including the surprise tablet multiplier.
        // `sizeOf` rather than `MediaQuery.of` so the button does not rebuild
        // on every unrelated MediaQuery change.
        final bool isTablet = MediaQuery.sizeOf(context).width > 600;
        return SizedBox(
          width: width ??
              (isTablet ? _config.defaultWidth * 1.2 : _config.defaultWidth),
          height: height ?? _config.defaultHeight,
          child: button,
        );
    }
  }

  ButtonStyle _styleFrom({BorderSide? side}) {
    final ButtonStyle resolved = ButtonStyle(
      backgroundColor: _maybeColor(_backgroundColor()),
      foregroundColor: _maybeColor(_foregroundColor()),
      elevation: widget.style?.elevation == null
          ? null
          : WidgetStatePropertyAll<double>(widget.style!.elevation!),
      shadowColor: _maybeColor(widget.style?.shadowColor),
      padding: widget.style?.padding == null
          ? null
          : WidgetStatePropertyAll<EdgeInsetsGeometry>(widget.style!.padding!),
      alignment: widget.style?.alignment,
      textStyle: widget.style?.textStyle == null
          ? null
          : WidgetStatePropertyAll<TextStyle>(widget.style!.textStyle!),
      side: side == null ? null : WidgetStatePropertyAll<BorderSide>(side),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
    );
    return widget.buttonStyle?.merge(resolved) ?? resolved;
  }

  WidgetStateProperty<Color?>? _maybeColor(Color? color) =>
      color == null ? null : WidgetStatePropertyAll<Color?>(color);

  Widget _buildButtonByType() {
    final VoidCallback? onPressed = _isEnabled ? press : null;
    final Widget child = _buildChild();

    switch (widget.type) {
      case ButtonType.elevated:
        return ElevatedButton(
          onPressed: onPressed,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          style: _styleFrom(),
          child: child,
        );
      case ButtonType.filled:
        return FilledButton(
          onPressed: onPressed,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          style: _styleFrom(),
          child: child,
        );
      case ButtonType.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          style: _styleFrom(
            side: widget.style?.borderColor == null &&
                    widget.style?.borderWidth == null
                ? null
                : BorderSide(
                    color: widget.style?.borderColor ??
                        _foregroundColor() ??
                        Theme.of(context).colorScheme.outline,
                    width: widget.style?.borderWidth ?? 1.0,
                  ),
          ),
          child: child,
        );
      case ButtonType.text:
        return TextButton(
          onPressed: onPressed,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          style: _styleFrom(),
          child: child,
        );
      case ButtonType.icon:
        return IconButton(
          onPressed: onPressed,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          iconSize: widget.style?.iconSize,
          color: _foregroundColor(),
          style: _styleFrom(),
          icon: child,
        );
    }
  }
}
