part of '../../loading_icon_button.dart';

/// The complete observable state of a loading button: one value, one
/// notification.
///
/// Bundling the state, the progress and the last error together means a
/// listener can never observe a torn read — an [ActionState.error] paired with
/// a stale [progress], say.
@immutable
class LoadingButtonValue {
  const LoadingButtonValue({
    this.state = ActionState.idle,
    this.progress,
    this.error,
    this.stackTrace,
  }) : assert(
          progress == null || (progress >= 0.0 && progress <= 1.0),
          'progress must be null (indeterminate) or within 0.0..1.0',
        );

  /// The resting value: idle, indeterminate, no error.
  static const LoadingButtonValue idle = LoadingButtonValue();

  /// Which phase the button is in.
  final ActionState state;

  /// Determinate progress in 0.0..1.0, or null for an indeterminate spinner.
  final double? progress;

  /// The error from the most recent failed run, if any.
  final Object? error;

  /// The stack trace that accompanied [error].
  final StackTrace? stackTrace;

  /// Whether the button is mid-run.
  bool get isLoading => state.isLoading;

  /// Whether [progress] is being reported.
  bool get isDeterminate => progress != null;

  /// Returns a copy with the given fields replaced.
  ///
  /// Standard `copyWith` semantics apply, which is worth stating explicitly
  /// for the nullable fields: passing `progress: null` KEEPS the current
  /// progress, because null is indistinguishable from "not supplied". To drop
  /// back to an indeterminate indicator pass `clearProgress: true`; likewise
  /// `clearError: true` to forget [error] and [stackTrace].
  LoadingButtonValue copyWith({
    ActionState? state,
    double? progress,
    bool clearProgress = false,
    Object? error,
    StackTrace? stackTrace,
    bool clearError = false,
  }) {
    return LoadingButtonValue(
      state: state ?? this.state,
      progress: clearProgress ? null : (progress ?? this.progress),
      error: clearError ? null : (error ?? this.error),
      stackTrace: clearError ? null : (stackTrace ?? this.stackTrace),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingButtonValue &&
          other.state == state &&
          other.progress == progress &&
          other.error == error &&
          other.stackTrace == stackTrace;

  @override
  int get hashCode => Object.hash(state, progress, error, stackTrace);

  @override
  String toString() => 'LoadingButtonValue(${state.name}'
      '${progress == null ? '' : ', progress: $progress'}'
      '${error == null ? '' : ', error: $error'})';
}

/// Drives a [LoadingButton] from outside the widget tree.
///
/// Attach one to a button with `LoadingButton(controller: myController)` and
/// call [start], [setProgress], [success], [error] or [reset] from anywhere —
/// no `GlobalKey`, and no need to own the button's `State`.
///
/// ```dart
/// final controller = LoadingButtonController();
///
/// LoadingButton(
///   controller: controller,
///   onPressed: _upload,
///   child: const Text('Upload'),
/// );
///
/// // elsewhere
/// controller.setProgress(0.4);
/// ```
///
/// This is a [ValueNotifier], so a [ValueListenableBuilder] can render other
/// parts of the UI from the same state.
///
/// A controller may be attached to more than one button, in which case every
/// attached button mirrors the same value and [press] runs each one's
/// `onPressed`. Dispose it when you are done, like any [ChangeNotifier].
class LoadingButtonController extends ValueNotifier<LoadingButtonValue> {
  LoadingButtonController({LoadingButtonValue value = LoadingButtonValue.idle})
      : super(value);

  final List<_LoadingButtonBinding> _bindings = <_LoadingButtonBinding>[];

  Timer? _cooldownTimer;
  DateTime? _cooldownUntil;

  /// The current phase.
  ActionState get state => value.state;

  /// The current determinate progress, or null when indeterminate.
  double? get progress => value.progress;

  /// The error from the most recent failed run.
  Object? get lastError => value.error;

  /// The stack trace that accompanied [lastError].
  StackTrace? get lastStackTrace => value.stackTrace;

  /// Whether at least one button is currently using this controller.
  bool get isAttached => _bindings.isNotEmpty;

  /// How many buttons are currently using this controller.
  int get attachmentCount => _bindings.length;

  /// Whether a cooldown is currently holding the button disabled.
  bool get isCoolingDown => cooldownRemaining > Duration.zero;

  /// How much of the current cooldown is left.
  Duration get cooldownRemaining {
    final DateTime? until = _cooldownUntil;
    if (until == null) return Duration.zero;
    final Duration left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Moves to [ActionState.loading], optionally with determinate [progress].
  void start({double? progress}) => value = LoadingButtonValue(
        state: ActionState.loading,
        progress: progress,
      );

  /// Reports determinate progress. Passing null restores the indeterminate
  /// indicator without leaving the loading state.
  void setProgress(double? progress) {
    assert(
      progress == null || (progress >= 0.0 && progress <= 1.0),
      'progress must be null or within 0.0..1.0',
    );
    value = value.copyWith(progress: progress, clearProgress: progress == null);
  }

  /// Moves to [ActionState.success].
  void success() => value = const LoadingButtonValue(
        state: ActionState.success,
      );

  /// Moves to [ActionState.error], recording [error] and [stackTrace].
  void error([Object? error, StackTrace? stackTrace]) =>
      value = LoadingButtonValue(
        state: ActionState.error,
        error: error,
        stackTrace: stackTrace,
      );

  /// Returns to [ActionState.idle] and clears progress and the last error.
  void reset() => value = LoadingButtonValue.idle;

  /// Enables or disables the button, without touching progress or the error.
  ///
  /// Disabling is a no-op while a run is in flight.
  void setEnabled(bool enabled) {
    if (value.isLoading) return;
    value = value.copyWith(
      state: enabled ? ActionState.idle : ActionState.disabled,
    );
  }

  /// Sets the phase directly. The escape hatch for states the named commands
  /// do not cover.
  ///
  /// Progress is preserved unless [progress] is given or [clearProgress] is
  /// set — passing neither changes the phase and nothing else.
  void setActionState(
    ActionState state, {
    double? progress,
    bool clearProgress = false,
  }) =>
      value = value.copyWith(
        state: state,
        progress: progress,
        clearProgress: clearProgress,
      );

  /// Runs an attached button's `onPressed`, exactly as a tap would.
  ///
  /// Honours each button's press latch, so a programmatic press cannot race a
  /// user's tap. Returns when the callback has settled.
  ///
  /// With several buttons attached, only ONE run happens: they share this
  /// controller's value, so the first button to accept the press moves the
  /// value to [ActionState.loading] and the rest decline. Which button that is
  /// follows attachment order, so attach one button per controller when it
  /// matters.
  Future<void> press() async {
    if (_bindings.isEmpty) return;
    await Future.wait(<Future<void>>[
      for (final _LoadingButtonBinding b
          in List<_LoadingButtonBinding>.of(_bindings))
        b._invokePressed(),
    ]);
  }

  /// Holds the button disabled for [duration], then returns it to idle.
  ///
  /// Used for "resend code in 30s" affordances. Calling it again restarts the
  /// window.
  void startCooldown(Duration duration) {
    _cooldownTimer?.cancel();
    if (duration <= Duration.zero) {
      _cooldownUntil = null;
      return;
    }
    _cooldownUntil = DateTime.now().add(duration);
    value = value.copyWith(state: ActionState.disabled);
    _cooldownTimer = Timer(duration, () {
      _cooldownUntil = null;
      _cooldownTimer = null;
      // Only release a cooldown we are still holding; anything else has since
      // taken over the value.
      if (value.state == ActionState.disabled) reset();
    });
  }

  void _attach(_LoadingButtonBinding binding) => _bindings.add(binding);

  void _detach(_LoadingButtonBinding binding) => _bindings.remove(binding);

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    // Bindings are NOT cleared here. Each button detaches itself when it is
    // unmounted, so clearing would make [attachmentCount] report zero while
    // buttons are still bound — hiding the misuse of disposing a controller
    // that is still in use, which is exactly when you want to be told.
    super.dispose();
  }
}

/// The private handshake a button implements so a controller can drive it.
abstract class _LoadingButtonBinding {
  Future<void> _invokePressed();
}
