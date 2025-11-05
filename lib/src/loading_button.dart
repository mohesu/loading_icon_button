part of '../../loading_icon_button.dart';

/// A customizable loading button with different states and animations
class LoadingButton extends StatefulWidget {
  /// Creates a LoadingButton
  const LoadingButton({
    super.key,
    this.type = ButtonType.elevated,
    this.onPressed,
    this.child,
    this.loadingWidget,
    this.successWidget,
    this.errorWidget,
    this.style,
    this.animationDuration,
    this.successDuration,
    this.errorDuration,
    this.width,
    this.height,
    this.loadingText,
    this.successText,
    this.errorText,
    this.resetAfterDuration = true,
    this.enableHapticFeedback,
    this.onError,
    this.onStateChanged,
  });

  /// The type of button to create
  final ButtonType type;

  /// Called when the button is pressed
  final AsyncCallback? onPressed;

  /// The widget to display when the button is in idle state
  final Widget? child;

  /// The widget to display when the button is loading
  final Widget? loadingWidget;

  /// The widget to display when the button is in success state
  final Widget? successWidget;

  /// The widget to display when the button is in error state
  final Widget? errorWidget;

  /// The style configuration for the button
  final LoadingButtonStyle? style;

  /// Duration for animations
  final Duration? animationDuration;

  /// Duration to show success state
  final Duration? successDuration;

  /// Duration to show error state
  final Duration? errorDuration;

  /// Width of the button
  final double? width;

  /// Height of the button
  final double? height;

  /// Text to display during loading
  final String? loadingText;

  /// Text to display on success
  final String? successText;

  /// Text to display on error
  final String? errorText;

  /// Whether to reset to idle state after success/error duration
  final bool resetAfterDuration;

  /// Whether to enable haptic feedback
  final bool? enableHapticFeedback;

  /// Called when an error occurs
  final Function(dynamic)? onError;

  /// Called when the button state changes
  final Function(ActionState)? onStateChanged;

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _scaleController;
  late final BehaviorSubject<ActionState> _stateSubject;

  final LoadingButtonConfig _config = LoadingButtonConfig();

  ActionState _currentState = ActionState.idle;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.animationDuration ?? _config.defaultAnimationDuration,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _stateSubject = BehaviorSubject<ActionState>.seeded(ActionState.idle);

    // Listen to state changes
    _stateSubject.stream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });

        widget.onStateChanged?.call(state);

        _handleStateAnimation(state);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    _stateSubject.close();
    super.dispose();
  }

  void _handleStateAnimation(ActionState state) {
    switch (state) {
      case ActionState.loading:
        _animationController.repeat();
        break;
      case ActionState.success:
        _animationController.forward();
        _scheduleReset(
            widget.successDuration ?? _config.defaultSuccessDuration);
        break;
      case ActionState.error:
        _animationController.forward();
        _scheduleReset(widget.errorDuration ?? _config.defaultErrorDuration);
        break;
      case ActionState.idle:
      case ActionState.disabled:
        _animationController.reset();
        break;
    }
  }

  void _scheduleReset(Duration duration) {
    if (widget.resetAfterDuration) {
      Future.delayed(duration, () {
        if (mounted) {
          _stateSubject.add(ActionState.idle);
        }
      });
    }
  }

  Future<void> _handlePress() async {
    if (_currentState != ActionState.idle) return;

    // Haptic feedback
    if (widget.enableHapticFeedback ?? _config.enableHapticFeedback) {
      await HapticFeedback.lightImpact();
    }

    // Scale animation
    await _scaleController.forward();
    await _scaleController.reverse();

    if (widget.onPressed == null) return;

    try {
      _stateSubject.add(ActionState.loading);
      await widget.onPressed?.call();
      if (mounted) {
        _stateSubject.add(ActionState.success);
      }
    } catch (error) {
      if (mounted) {
        _stateSubject.add(ActionState.error);
      }
      widget.onError?.call(error);

      if (_config.debugMode) {
        debugPrint('LoadingButton Error: $error');
      }
    }
  }

  Widget _buildChild() {
    switch (_currentState) {
      case ActionState.loading:
        return widget.loadingWidget ??
            (widget.loadingText != null
                ? Text(widget.loadingText!)
                : _config.defaultLoadingWidget);
      case ActionState.success:
        return widget.successWidget ??
            (widget.successText != null
                ? Text(widget.successText!)
                : _config.defaultSuccessWidget);
      case ActionState.error:
        return widget.errorWidget ??
            (widget.errorText != null
                ? Text(widget.errorText!)
                : _config.defaultErrorWidget);
      case ActionState.idle:
      case ActionState.disabled:
        return widget.child ?? const SizedBox.shrink();
    }
  }

  Color _getBackgroundColor() {
    final style = widget.style;
    switch (_currentState) {
      case ActionState.loading:
        return style?.loadingBackgroundColor ??
            style?.backgroundColor ??
            Theme.of(context).primaryColor;
      case ActionState.success:
        return style?.successBackgroundColor ?? Colors.green;
      case ActionState.error:
        return style?.errorBackgroundColor ?? Colors.red;
      case ActionState.disabled:
        return style?.disabledBackgroundColor ?? Colors.grey;
      case ActionState.idle:
        return style?.backgroundColor ?? Theme.of(context).primaryColor;
    }
  }

  Color _getForegroundColor() {
    final style = widget.style;
    switch (_currentState) {
      case ActionState.disabled:
        return style?.disabledForegroundColor ?? Colors.grey.shade400;
      default:
        return style?.foregroundColor ?? Colors.white;
    }
  }

  Widget _buildButton() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    final buttonWidth = widget.width ??
        (isTablet ? _config.defaultWidth * 1.2 : _config.defaultWidth);
    final buttonHeight = widget.height ?? _config.defaultHeight;

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_scaleController.value * 0.05),
          child: AnimatedContainer(
            duration:
                widget.animationDuration ?? _config.defaultAnimationDuration,
            width: buttonWidth,
            height: buttonHeight,
            child: child,
          ),
        );
      },
      child: _buildButtonByType(),
    );
  }

  Widget _buildButtonByType() {
    final backgroundColor = _getBackgroundColor();
    final foregroundColor = _getForegroundColor();
    final isEnabled =
        _currentState == ActionState.idle && widget.onPressed != null;

    switch (widget.type) {
      case ButtonType.elevated:
        return ElevatedButton(
          onPressed: isEnabled ? _handlePress : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: widget.style?.elevation,
            shadowColor: widget.style?.shadowColor,
            padding: widget.style?.padding,
            alignment: widget.style?.alignment,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                widget.style?.borderRadius ?? _config.defaultBorderRadius,
              ),
            ),
          ),
          child: _buildChild(),
        );
      case ButtonType.filled:
        return FilledButton(
          onPressed: isEnabled ? _handlePress : null,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: widget.style?.padding,
            alignment: widget.style?.alignment,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                widget.style?.borderRadius ?? _config.defaultBorderRadius,
              ),
            ),
          ),
          child: _buildChild(),
        );
      case ButtonType.outlined:
        return OutlinedButton(
          onPressed: isEnabled ? _handlePress : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: widget.style?.padding,
            alignment: widget.style?.alignment,
            side: BorderSide(
              color: widget.style?.borderColor ?? foregroundColor,
              width: widget.style?.borderWidth ?? 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                widget.style?.borderRadius ?? _config.defaultBorderRadius,
              ),
            ),
          ),
          child: _buildChild(),
        );
      case ButtonType.text:
        return TextButton(
          onPressed: isEnabled ? _handlePress : null,
          style: TextButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: widget.style?.padding,
            alignment: widget.style?.alignment,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                widget.style?.borderRadius ?? _config.defaultBorderRadius,
              ),
            ),
          ),
          child: _buildChild(),
        );
      case ButtonType.icon:
        return IconButton(
          onPressed: isEnabled ? _handlePress : null,
          icon: _buildChild(),
          iconSize: widget.style?.iconSize,
          color: foregroundColor,
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor,
            padding: widget.style?.padding,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _currentState == ActionState.idle && widget.onPressed != null,
      label: _getSemanticLabel(),
      child: _buildButton(),
    );
  }

  String _getSemanticLabel() {
    switch (_currentState) {
      case ActionState.loading:
        return widget.loadingText ?? 'Loading';
      case ActionState.success:
        return widget.successText ?? 'Success';
      case ActionState.error:
        return widget.errorText ?? 'Error';
      case ActionState.disabled:
        return 'Disabled';
      case ActionState.idle:
        return 'Button';
    }
  }
}
