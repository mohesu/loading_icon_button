part of '../loading_icon_button.dart';

/// [ElevatedAutoLoadingButton]，[FilledAutoLoadingButton]&[State]parent class
///
/// Provide standard implementation
abstract class AutoLoadingButtonState<T extends StatefulWidget>
    extends State<T> {
  /// Trigger the execution of the widget's onPressed event and enter the loading state
  ///
  /// Call by passing [GlobalKey]
  ///
  /// Return the future of the original onPressed event completion.
  /// If the widget does not pass the original onPressed event, nothing will happen,
  /// If the widget is in the loading state, the future of the current loading event will be returned, and the event will not be triggered repeatedly
  Future<void> doPress() =>
      _run(() => _onPressed, () => _onPressedFuture, (Future<void>? f) {
        _onPressedFuture = f;
      });

  /// Trigger the execution of the widget's onLongPress event
  ///
  /// Call by passing [GlobalKey]
  ///
  /// Return the future of the original onLongPress event completion.
  /// If the widget does not pass the original onLongPress event, nothing will happen,
  /// If the widget is in the loading state, the future of the current loading event will be returned, and the event will not be triggered repeatedly
  Future<void> doLongPress() =>
      _run(() => _onLongPress, () => _onLongPressFuture, (Future<void>? f) {
        _onLongPressFuture = f;
      });

  /// Shared body of [doPress] and [doLongPress].
  ///
  /// The loading flag is cleared on BOTH completion paths. Before 1.1.0 only
  /// the success path cleared it, so a callback that threw left the button
  /// disabled with a spinner forever, hung every awaiter, and surfaced the
  /// error as an unhandled async error instead of returning it to the caller.
  Future<void> _run(
    AsyncCallback? Function() getCallback,
    Future<void>? Function() getPending,
    void Function(Future<void>?) setPending,
  ) {
    final Future<void>? pending = getPending();
    if (pending != null) return pending;

    final AsyncCallback? callback = getCallback();
    if (callback == null) return Future<void>.value();

    final Completer<void> completer = Completer<void>();
    final Future<void> future = completer.future;
    setPending(future);
    if (mounted) {
      setState(() {});
    }

    void finish() {
      setPending(null);
      if (mounted) {
        setState(() {});
      }
    }

    // Invoking the callback may itself throw synchronously.
    Future<void> result;
    try {
      result = callback();
    } catch (error, stackTrace) {
      finish();
      completer.completeError(error, stackTrace);
      return future;
    }

    result.then<void>(
      (_) {
        finish();
        completer.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        finish();
        completer.completeError(error, stackTrace);
      },
    );

    return future;
  }

  /// Whether the current is in the loading state
  bool get _isLoading => _onPressedFuture != null || _onLongPressFuture != null;

  /// If the current is executing the onPressed loading event, then its completion future, otherwise null
  Future<void>? _onPressedFuture;

  /// If the current is executing the onLongPress loading event, then its completion future, otherwise null
  Future<void>? _onLongPressFuture;

  /// Original widget click event
  AsyncCallback? get _onPressed;

  /// Original widget long press event
  AsyncCallback? get _onLongPress;

  /// [_onPressed] event wrapper
  VoidCallback? _wrapOnPressed() {
    return _onPressed == null ? null : () => _reportIfUnobserved(doPress());
  }

  /// [_onLongPress] event wrapper
  VoidCallback? _wrapOnLongPress() {
    return _onLongPress == null
        ? null
        : () => _reportIfUnobserved(doLongPress());
  }

  /// Routes a failure from the TAP path to [FlutterError].
  ///
  /// A tap discards the future, so without this a throwing callback would
  /// surface as an unhandled async error with no useful context. Callers that
  /// invoke [doPress] themselves are not routed through here, so they receive
  /// the error on the returned future and can handle it normally.
  void _reportIfUnobserved(Future<void> future) {
    future.catchError((Object error, StackTrace stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'loading_icon_button',
        context:
            ErrorDescription('while running an AutoLoadingButton callback'),
      ));
    });
  }
}

class _ButtonWithIconChild extends StatelessWidget {
  const _ButtonWithIconChild({
    required this.label,
    required this.icon,
  });

  final Widget label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final double scale = MediaQuery.maybeOf(context)?.textScaler.scale(1) ?? 1;
    final double gap = scale <= 1 ? 8 : lerpDouble(8, 4, min(scale - 1, 1))!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[icon, SizedBox(width: gap), Flexible(child: label)],
    );
  }
}

class _LoadingChild extends StatelessWidget {
  const _LoadingChild();

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    Widget result = CircularProgressIndicator(
      strokeWidth: 2,
      color: iconTheme.color,
    );

    result = Padding(
      padding: const EdgeInsets.all(2),
      child: result,
    );

    result = SizedBox.square(
      dimension: iconTheme.size ?? 24,
      child: result,
    );

    return result;
  }
}

/// Resolves the widget shown while an `XxxLoadingButton` is busy.
///
/// Called from constructor initializer lists, where there is no
/// [BuildContext] yet, so the actual resolution is deferred to
/// [_IndicatorChild.build].
Widget _resolveLoadingIcon(Widget? loadingIcon, LoadingIndicator? indicator) =>
    loadingIcon ?? _IndicatorChild(indicator: indicator);

/// Builds an explicit [LoadingIndicator], the ambient
/// [LoadingButtonThemeData.indicator], or the package default, in that order.
class _IndicatorChild extends StatelessWidget {
  const _IndicatorChild({this.indicator});

  final LoadingIndicator? indicator;

  @override
  Widget build(BuildContext context) {
    final LoadingIndicator? resolved =
        indicator ?? LoadingButtonThemeData.of(context).indicator;
    return resolved?.build(context) ?? const _LoadingChild();
  }
}
