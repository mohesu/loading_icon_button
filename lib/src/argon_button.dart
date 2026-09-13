part of '../loading_icon_button.dart';

/// Argon Button State Enum
enum ArgonButtonState { busy, idle }

/// Argon Button
class ArgonButton extends StatefulWidget {
  /// Button height
  final double height;

  /// Button width
  final double width;

  /// Button min width
  final double minWidth;

  /// Button loader
  final Widget? loader;

  /// Animation duration
  final Duration animationDuration;

  /// Curve animation
  final Curve curve;

  /// Reverse curve animation
  final Curve reverseCurve;

  /// Child widget
  final Widget child;

  /// Function to call on button pressed
  final void Function(
    Function startLoading,
    Function stopLoading,
    ArgonButtonState btnState,
  )? onTap;

  /// Button color
  final Color? color;

  /// Focus color
  final Color? focusColor;

  /// Hover color
  final Color? hoverColor;

  /// Highlight color
  final Color? highlightColor;

  /// Splash color
  final Color? splashColor;

  /// Brightness
  final Brightness? colorBrightness;
  final double? elevation;
  final double? focusElevation;
  final double? hoverElevation;
  final double? highlightElevation;
  final EdgeInsetsGeometry padding;
  final Clip? clipBehavior;
  final FocusNode? focusNode;
  final MaterialTapTargetSize? materialTapTargetSize;
  final bool roundLoadingShape;
  final double borderRadius;
  final BorderSide borderSide;
  final double? disabledElevation;
  final Color? disabledColor;
  final Color? disabledTextColor;

  const ArgonButton(
      {super.key,
      required this.height,
      required this.width,
      required this.child,
      this.minWidth = 0,
      this.loader,
      this.animationDuration = const Duration(milliseconds: 450),
      this.curve = Curves.easeInOutCirc,
      this.reverseCurve = Curves.easeInOutCirc,
      this.onTap,
      this.color,
      this.focusColor,
      this.hoverColor,
      this.highlightColor,
      this.splashColor,
      this.colorBrightness,
      this.elevation,
      this.focusElevation,
      this.hoverElevation,
      this.highlightElevation,
      this.padding = const EdgeInsets.all(0),
      this.borderRadius = 0.0,
      this.clipBehavior = Clip.none,
      this.focusNode,
      this.materialTapTargetSize,
      this.roundLoadingShape = true,
      this.borderSide = const BorderSide(color: Colors.transparent, width: 0),
      this.disabledElevation,
      this.disabledColor,
      this.disabledTextColor})
      : assert(elevation == null || elevation >= 0.0),
        assert(focusElevation == null || focusElevation >= 0.0),
        assert(hoverElevation == null || hoverElevation >= 0.0),
        assert(highlightElevation == null || highlightElevation >= 0.0),
        assert(disabledElevation == null || disabledElevation >= 0.0),
        assert(clipBehavior != null);

  @override
  State<ArgonButton> createState() => _ArgonButtonState();
}

class _ArgonButtonState extends State<ArgonButton>
    with TickerProviderStateMixin {
  double? loaderWidth;

  late Animation<double> _animation;
  late AnimationController _controller;
  ArgonButtonState btn = ArgonButtonState.idle;

  final GlobalKey _buttonKey = GlobalKey();
  double _minWidth = 0;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);

    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve));

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          btn = ArgonButtonState.idle;
        });
      }
    });

    minWidth = widget.height;
    loaderWidth = widget.height;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateForward() {
    if (!mounted) return;
    setState(() {
      btn = ArgonButtonState.busy;
    });
    _controller.forward();
  }

  void animateReverse() {
    if (!mounted) return;
    _controller.reverse();
  }

  /// Interpolates the button width between its full and collapsed sizes.
  ///
  /// A zero endpoint means "unconstrained", so null is returned and the
  /// button is left to size itself.
  double? lerpWidth(double a, double b, double t) {
    if (a == 0.0 || b == 0.0) {
      return null;
    } else {
      return a + (b - a) * t;
    }
  }

  double get minWidth => _minWidth;

  set minWidth(double w) {
    if (widget.minWidth == 0) {
      _minWidth = w;
    } else {
      _minWidth = widget.minWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return buttonBody();
      },
    );
  }

  /// Enters the loading state. Safe to call after the widget is gone.
  void _startLoading() {
    if (!mounted) return;
    animateForward();
  }

  /// Leaves the loading state. Safe to call after the widget is gone.
  ///
  /// The callbacks handed to [ArgonButton.onTap] routinely outlive the button
  /// — a network call completing after the user has navigated away is the
  /// normal case — so both guard on `mounted` rather than driving a disposed
  /// controller.
  void _stopLoading() {
    if (!mounted) return;
    animateReverse();
  }

  Widget buttonBody() {
    final void Function(Function, Function, ArgonButtonState)? onTap =
        widget.onTap;
    return SizedBox(
      height: widget.height,
      width: lerpWidth(widget.width, minWidth, _animation.value),
      child: ButtonTheme(
        height: widget.height,
        shape: RoundedRectangleBorder(
          side: widget.borderSide,
          borderRadius: BorderRadius.circular(widget.roundLoadingShape
              ? lerpDouble(
                  widget.borderRadius, widget.height / 2, _animation.value)!
              : widget.borderRadius),
        ),
        child: MaterialButton(
            key: _buttonKey,
            color: widget.color,
            focusColor: widget.focusColor,
            hoverColor: widget.hoverColor,
            highlightColor: widget.highlightColor,
            splashColor: widget.splashColor,
            colorBrightness: widget.colorBrightness,
            elevation: widget.elevation,
            focusElevation: widget.focusElevation,
            hoverElevation: widget.hoverElevation,
            highlightElevation: widget.highlightElevation,
            padding: widget.padding,
            clipBehavior: widget.clipBehavior!,
            focusNode: widget.focusNode,
            materialTapTargetSize: widget.materialTapTargetSize,
            disabledElevation: widget.disabledElevation,
            disabledColor: widget.disabledColor,
            disabledTextColor: widget.disabledTextColor,
            onPressed: onTap == null
                ? null
                : () => onTap(
                      _startLoading,
                      _stopLoading,
                      btn,
                    ),
            child: btn == ArgonButtonState.idle
                ? widget.child
                : widget.loader ?? const _LoadingChild()),
      ),
    );
  }
}

class ArgonTimerButton extends StatefulWidget {
  final double height;
  final double width;
  final double minWidth;
  final Widget Function(int time)? loader;
  final Duration animationDuration;
  final Curve curve;
  final Curve reverseCurve;
  final Widget child;
  final void Function(Function startTimer, ArgonButtonState? btnState)? onTap;
  final Color? color;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final Brightness? colorBrightness;
  final double? elevation;
  final double? focusElevation;
  final double? hoverElevation;
  final double? highlightElevation;
  final EdgeInsetsGeometry padding;
  final Clip? clipBehavior;
  final FocusNode? focusNode;
  final MaterialTapTargetSize? materialTapTargetSize;
  final bool roundLoadingShape;
  final double borderRadius;
  final BorderSide borderSide;
  final double? disabledElevation;
  final Color? disabledColor;
  final Color? disabledTextColor;
  final int initialTimer;

  const ArgonTimerButton({
    super.key,
    required this.height,
    required this.width,
    required this.child,
    this.minWidth = 0,
    this.loader,
    this.animationDuration = const Duration(milliseconds: 450),
    this.curve = Curves.easeInOutCirc,
    this.reverseCurve = Curves.easeInOutCirc,
    this.onTap,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.colorBrightness,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.highlightElevation,
    this.padding = const EdgeInsets.all(0),
    this.borderRadius = 0.0,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.materialTapTargetSize,
    this.roundLoadingShape = true,
    this.borderSide = const BorderSide(color: Colors.transparent, width: 0),
    this.disabledElevation,
    this.disabledColor,
    this.disabledTextColor,
    this.initialTimer = 0,
  })  : assert(elevation == null || elevation >= 0.0),
        assert(focusElevation == null || focusElevation >= 0.0),
        assert(hoverElevation == null || hoverElevation >= 0.0),
        assert(highlightElevation == null || highlightElevation >= 0.0),
        assert(disabledElevation == null || disabledElevation >= 0.0),
        assert(clipBehavior != null);

  @override
  State<ArgonTimerButton> createState() => _ArgonTimerButtonState();
}

class _ArgonTimerButtonState extends State<ArgonTimerButton>
    with TickerProviderStateMixin {
  double? loaderWidth;

  late Animation<double> _animation;
  late AnimationController _controller;
  ArgonButtonState? btn;
  int secondsLeft = 0;
  Timer? _timer;
  final Stream<void> emptyStream = const Stream<void>.empty();
  double _minWidth = 0;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);

    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve));

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        btn = ArgonButtonState.idle;
      }
    });

    if (widget.initialTimer == 0) {
      btn = ArgonButtonState.idle;
    } else {
      startTimer(widget.initialTimer);
      btn = ArgonButtonState.busy;
    }

    minWidth = widget.height;
    loaderWidth = widget.height;
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
    _controller.dispose();
    super.dispose();
  }

  void animateForward() {
    setState(() {
      btn = ArgonButtonState.busy;
    });
    _controller.forward();
  }

  void animateReverse() {
    if (!mounted) return;
    _controller.reverse();
  }

  /// Interpolates the button width between its full and collapsed sizes.
  ///
  /// A zero endpoint means "unconstrained", so null is returned and the
  /// button is left to size itself.
  double? lerpWidth(double a, double b, double t) {
    if (a == 0.0 || b == 0.0) {
      return null;
    } else {
      return a + (b - a) * t;
    }
  }

  double get minWidth => _minWidth;

  set minWidth(double w) {
    if (widget.minWidth == 0) {
      _minWidth = w;
    } else {
      _minWidth = widget.minWidth;
    }
  }

  void startTimer(int newTime) {
    if (newTime <= 0) {
      throw ArgumentError.value(
        newTime,
        'newTime',
        'Countdown duration must be greater than zero seconds',
      );
    }

    animateForward();

    setState(() {
      secondsLeft = newTime;
    });

    if (_timer != null) {
      _timer!.cancel();
    }

    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          if (secondsLeft < 1) {
            timer.cancel();
          } else {
            secondsLeft = secondsLeft - 1;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return buttonBody();
      },
    );
  }

  Widget buttonBody() {
    final void Function(Function, ArgonButtonState?)? onTap = widget.onTap;
    return SizedBox(
      height: widget.height,
      width: lerpWidth(widget.width, minWidth, _animation.value),
      child: ButtonTheme(
        height: widget.height,
        shape: RoundedRectangleBorder(
          side: widget.borderSide,
          borderRadius: BorderRadius.circular(widget.roundLoadingShape
              ? lerpDouble(
                  widget.borderRadius, widget.height / 2, _animation.value)!
              : widget.borderRadius),
        ),
        child: MaterialButton(
          color: widget.color,
          focusColor: widget.focusColor,
          hoverColor: widget.hoverColor,
          highlightColor: widget.highlightColor,
          splashColor: widget.splashColor,
          colorBrightness: widget.colorBrightness,
          elevation: widget.elevation,
          focusElevation: widget.focusElevation,
          hoverElevation: widget.hoverElevation ?? 1,
          highlightElevation: widget.highlightElevation,
          padding: widget.padding,
          clipBehavior: widget.clipBehavior!,
          focusNode: widget.focusNode,
          materialTapTargetSize: widget.materialTapTargetSize,
          disabledElevation: widget.disabledElevation,
          disabledColor: widget.disabledColor,
          disabledTextColor: widget.disabledTextColor,
          onPressed: onTap == null
              ? null
              : () => onTap((int newCounter) {
                    if (mounted) startTimer(newCounter);
                  }, btn),
          child: btn == ArgonButtonState.idle
              ? widget.child
              : StreamBuilder(
                  stream: emptyStream,
                  builder: (context, snapshot) {
                    if (secondsLeft == 0) {
                      animateReverse();
                    }
                    return widget.loader?.call(secondsLeft) ??
                        const _LoadingChild();
                  },
                ),
        ),
      ),
    );
  }
}
