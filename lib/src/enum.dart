part of '../loading_icon_button.dart';

/// Enum representing the different states of a loading button
enum ActionState {
  /// Button is in idle state and ready to be pressed
  idle,

  /// Button is in loading state
  loading,

  /// Button completed successfully
  success,

  /// Button encountered an error
  error,

  /// Button is disabled
  disabled,
}

/// Convenience predicates on [ActionState].
///
/// ## Renamed in 1.1.0
///
/// This extension was called `ButtonStateExtension` until 1.1.0 — a name left
/// over from before the `ButtonState` to [ActionState] rename in 1.0.2. It is
/// now `ActionStateExtension`, with no deprecated alias kept behind it, and
/// that is deliberate:
///
/// * Keeping a second extension declaring the same members on the same type
///   would make **every** call site ambiguous. Verified with the analyzer:
///   two extensions on one enum both declaring `isLoading` turn
///   `state.isLoading` into
///   `ambiguous_extension_member_access` — "a member named 'isLoading' is
///   defined in ... and neither is more specific". That is a compile error in
///   consumer code, which is far worse than a rename.
/// * A `typedef ButtonStateExtension = ActionStateExtension;` is not legal
///   Dart either. Also verified with the analyzer: it reports
///   `ActionStateExtension isn't a type`, because extensions are not types.
///
/// So the extension was simply renamed. Extension members resolve
/// structurally, by member name on the receiver's type, not by the extension's
/// name — verified by analyzing a consumer library that only imports the
/// renamed extension and calls `state.isLoading` unqualified, which reports no
/// issues. Existing code that writes `state.isLoading`, `state.isIdle` and so
/// on therefore keeps compiling unchanged. Only code that named the extension
/// explicitly in an extension override — `ButtonStateExtension(state).isIdle`
/// — has to be updated, which is vanishingly rare.
extension ActionStateExtension on ActionState {
  /// Check if button is in idle state
  bool get isIdle => this == ActionState.idle;

  /// Check if button is loading
  bool get isLoading => this == ActionState.loading;

  /// Check if button is in success state
  bool get isSuccess => this == ActionState.success;

  /// Check if button is in error state
  bool get isError => this == ActionState.error;

  /// Check if button is disabled
  bool get isDisabled => this == ActionState.disabled;

  /// Whether a press would be accepted in this state.
  ///
  /// True for every state except [ActionState.loading] (a run is already in
  /// flight) and [ActionState.disabled].
  ///
  /// ## Behaviour change in 1.1.0
  ///
  /// Before 1.1.0 this was an exact duplicate of [isIdle] — it returned true
  /// only for [ActionState.idle], which made it useless as a distinct
  /// predicate and wrong for the terminal states. A button resting in
  /// [ActionState.success] or [ActionState.error] is pressable, so those now
  /// report true. If you relied on the old meaning, use [isIdle], which is
  /// unchanged.
  bool get isInteractive =>
      this != ActionState.loading && this != ActionState.disabled;
}

/// Enum representing different types of buttons
enum ButtonType {
  /// Elevated button style
  elevated,

  /// Filled button style
  filled,

  /// Outlined button style
  outlined,

  /// Text button style
  text,

  /// Icon button style
  icon,
}
