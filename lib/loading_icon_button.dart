library loading_icon_button;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

enum ButtonState { idle, loading, success, error }

class LoadingButton extends StatefulWidget {
  /// Constructor for the LoadingButton widget.
  LoadingButton({
    Key? key,
    this.height = 55,
    this.width = 225,
    this.child,
    this.iconData,
    required this.onPressed,
    required this.controller,
    this.loaderSize = 50.0,
    this.loaderStrokeWidth = 1.5,
    this.animateOnTap = true,
    this.borderRadius = 25,
    this.elevation = 5,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOutCirc,
    this.primaryColor,
    this.errorColor = Colors.redAccent,
    this.successColor = Colors.green,
    this.shadowColor,
    this.valueColor,
    this.disabledColor,
    this.iconColor,
    this.resetDuration = const Duration(seconds: 15),
    this.resetAfterDuration = false,
    this.successIcon = Icons.check,
    this.failedIcon = Icons.close,
    this.completionCurve = Curves.elasticOut,
    this.completionDuration = const Duration(milliseconds: 1000),
    this.spaceBetween = 10,
    this.showBox = true,
  }) : super(key: key) {
    assert(child != null || iconData != null);
  }

  /// Required button controller
  final LoadingButtonController controller;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Child widget
  final Widget? child;

  /// Icon for button
  final IconData? iconData;

  /// Icon color for button
  final Color? iconColor;

  /// Primary color or the button
  final Color? primaryColor;

  /// Vertical extent of the button
  final double height;

  /// Horizontal extent of the button
  final double width;

  /// Spacing between icon and the child widget
  final double spaceBetween;

  /// Size of CircularProgressIndicator
  final double loaderSize;

  /// Stroke width of CircularProgressIndicator
  final double loaderStrokeWidth;

  /// Whether to trigger the animation on the tap event
  final bool animateOnTap;

  /// The color of the static icons
  final Color? valueColor;

  /// Reset the animation after specified duration,
  final bool resetAfterDuration;

  /// The curve of the shrink animation
  final Curve curve;

  /// The radius of the button border
  final double borderRadius;

  /// The duration of the button animation
  final Duration duration;

  /// The elevation of the raised button
  final double elevation;

  /// Duration after which reset the button
  final Duration resetDuration;

  /// The color of the button when it is in the error state
  final Color? errorColor;

  /// The color of the button when it is in the success state
  final Color? successColor;

  /// The color of the button when it is disabled
  final Color? disabledColor;

  /// The color of the shadow of the button
  final Color? shadowColor;

  /// The icon for the success state
  final IconData successIcon;

  /// The icon for the failed state
  final IconData failedIcon;

  /// The curve of the completion animation
  final Curve completionCurve;

  /// The duration of the success and failed animation
  final Duration completionDuration;

  /// Show background box for the button
  /// Default is true
  final bool showBox;

  Duration get _borderDuration {
    return Duration(milliseconds: (duration.inMilliseconds / 2).round());
  }

  @override
  _LoadingButtonState createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late AnimationController _borderController;
  late AnimationController _checkButtonController;

  late Animation _squeezeAnimation;
  late Animation _bounceAnimation;
  late Animation _borderAnimation;

  final _state = BehaviorSubject<ButtonState>.seeded(ButtonState.idle);

  @override
  void initState() {
    super.initState();
    _buttonController =
        AnimationController(duration: widget.duration, vsync: this);

    _checkButtonController =
        AnimationController(duration: widget.completionDuration, vsync: this);

    _borderController =
        AnimationController(duration: widget._borderDuration, vsync: this);

    _bounceAnimation = Tween<double>(begin: 0, end: widget.height).animate(
        CurvedAnimation(
            parent: _checkButtonController, curve: widget.completionCurve));
    _bounceAnimation.addListener(() {
      setState(() {});
    });

    _squeezeAnimation = Tween<double>(begin: widget.width, end: widget.height)
        .animate(
            CurvedAnimation(parent: _buttonController, curve: widget.curve));

    _squeezeAnimation.addListener(() {
      setState(() {});
    });

    _squeezeAnimation.addStatusListener((state) {
      if (state == AnimationStatus.completed && widget.animateOnTap) {
        if (widget.onPressed != null) {
          widget.onPressed!();
        }
      }
    });

    _borderAnimation = BorderRadiusTween(
            begin: BorderRadius.circular(widget.borderRadius),
            end: BorderRadius.circular(widget.height))
        .animate(_borderController);

    _borderAnimation.addListener(() {
      setState(() {});
    });

    // There is probably a better way of doing this...
    _state.stream.listen((event) {
      widget.controller._state.sink.add(event);
    });

    widget.controller._addListeners(_start, _stop, _success, _error, _reset);
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _checkButtonController.dispose();
    _borderController.dispose();
    _state.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var _check = Container(
      alignment: FractionalOffset.center,
      decoration: BoxDecoration(
        color: _state.value == ButtonState.idle
            ? theme.primaryColor
            : Colors.transparent,
        border: Border.all(
          color: widget.successColor ?? theme.primaryColor,
          width: widget.loaderStrokeWidth,
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(
            _bounceAnimation.value / 2,
          ),
        ),
      ),
      width: _bounceAnimation.value,
      height: _bounceAnimation.value,
      child: _bounceAnimation.value > 20
          ? Icon(
              widget.successIcon,
              color: widget.successColor ?? theme.primaryColor,
            )
          : null,
    );

    var _cross = Container(
      alignment: FractionalOffset.center,
      decoration: BoxDecoration(
        color: _state.value == ButtonState.idle
            ? theme.primaryColor
            : Colors.transparent,
        border: Border.all(
          color: widget.errorColor ?? theme.primaryColor,
          width: widget.loaderStrokeWidth,
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(
            _bounceAnimation.value / 2,
          ),
        ),
      ),
      width: _bounceAnimation.value,
      height: _bounceAnimation.value,
      child: _bounceAnimation.value > 20
          ? Icon(
              widget.failedIcon,
              color: widget.errorColor ?? theme.primaryColor,
            )
          : null,
    );

    var _loader = SizedBox(
      width: widget.loaderSize,
      height: widget.loaderSize,
      child: Container(
        decoration: BoxDecoration(
          color: (widget.showBox) ? widget.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(
              (widget.child != null) ? widget.borderRadius : 360),
        ),
        child: Stack(
          children: [
            SizedBox(
              height: widget.loaderSize,
              width: widget.loaderSize,
              child: CircularProgressIndicator(
                backgroundColor: widget.valueColor?.withOpacity(0.10) ??
                    theme.colorScheme.primary.withOpacity(0.10),
                valueColor: (widget.showBox)
                    ? AlwaysStoppedAnimation<Color>(
                        widget.valueColor ?? theme.colorScheme.onPrimary)
                    : AlwaysStoppedAnimation<Color>(
                        widget.valueColor ?? theme.primaryColor),
                strokeWidth: widget.loaderStrokeWidth,
              ),
            ),
            Center(
              child: Icon(
                widget.iconData,
                color: _state.value == ButtonState.loading
                    ? widget.valueColor
                    : widget.iconColor,
              ),
            ),
          ],
        ),
      ),
    );

    var childStream = StreamBuilder(
      stream: _state,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: snapshot.data == ButtonState.loading
              ? _loader
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.iconData != null)
                      Icon(
                        widget.iconData,
                        color: widget.iconColor,
                      ),
                    if (widget.child != null || widget.iconData == null)
                      SizedBox(
                        width: widget.spaceBetween,
                      ),
                    widget.child ?? const SizedBox(),
                  ],
                ),
        );
      },
    );

    final _btn = ButtonTheme(
      shape: RoundedRectangleBorder(borderRadius: _borderAnimation.value),
      disabledColor: widget.disabledColor,
      padding: const EdgeInsets.all(0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          onSurface: widget.disabledColor,
          minimumSize: Size(
              (widget.child != null) ? _squeezeAnimation.value : 55,
              widget.height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                (widget.child != null) ? widget.borderRadius : 360),
          ),
          primary: (widget.showBox) ? widget.primaryColor : Colors.transparent,
          elevation: (widget.showBox) ? widget.elevation : 0,
          shadowColor: (widget.showBox || kIsWeb)
              ? widget.shadowColor
              : Colors.transparent,
          onPrimary: (widget.showBox)
              ? theme.colorScheme.onPrimary
              : theme.primaryColor,
          padding: const EdgeInsets.all(0),
        ),
        onPressed: widget.onPressed == null ? null : _btnPressed,
        child: childStream,
      ),
    );

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Center(
        child: _state.value == ButtonState.error
            ? _cross
            : _state.value == ButtonState.success
                ? _check
                : _btn,
      ),
    );
  }

  _btnPressed() async {
    if (widget.animateOnTap) {
      _start();
    } else {
      if (widget.onPressed != null) {
        widget.onPressed!();
      }
    }
  }

  _start() {
    _state.sink.add(ButtonState.loading);
    _borderController.forward();
    _buttonController.forward();
    if (widget.resetAfterDuration) _reset();
  }

  _stop() {
    _state.sink.add(ButtonState.idle);
    _buttonController.reverse();
    _borderController.reverse();
  }

  _success() {
    _state.sink.add(ButtonState.success);
    _checkButtonController.forward();
  }

  _error() {
    _state.sink.add(ButtonState.error);
    _checkButtonController.forward();
  }

  _reset() async {
    if (widget.resetAfterDuration) await Future.delayed(widget.resetDuration);
    _state.sink.add(ButtonState.idle);
    _buttonController.reverse();
    _borderController.reverse();
    _checkButtonController.reset();
  }
}

/// Options that can be chosen by the controller
class LoadingButtonController {
  late VoidCallback _startListener;
  late VoidCallback _stopListener;
  late VoidCallback _successListener;
  late VoidCallback _errorListener;
  late VoidCallback _resetListener;

  _addListeners(
      VoidCallback startListener,
      VoidCallback stopListener,
      VoidCallback successListener,
      VoidCallback errorListener,
      VoidCallback resetListener) {
    _startListener = startListener;
    _stopListener = stopListener;
    _successListener = successListener;
    _errorListener = errorListener;
    _resetListener = resetListener;
  }

  final BehaviorSubject<ButtonState> _state =
      BehaviorSubject<ButtonState>.seeded(ButtonState.idle);

  /// A read-only stream of the button state
  Stream<ButtonState> get stateStream => _state.stream;

  /// Gets the current state
  ButtonState? get currentState => _state.value;

  /// Notify listeners to start the loading animation
  void start() {
    _startListener();
  }

  /// Notify listeners to start the stop animation
  void stop() {
    _stopListener();
  }

  /// Notify listeners to start the sucess animation
  void success() {
    _successListener();
  }

  /// Notify listeners to start the error animation
  void error() {
    _errorListener();
  }

  /// Notify listeners to start the reset animation
  void reset() {
    _resetListener();
  }
}
