part of '../../loading_icon_button.dart';

/// How a [LoadingButton] derives its colours.
enum LoadingButtonColorStrategy {
  /// The pre-1.1.0 behaviour: `Theme.of(context).primaryColor` for the
  /// background and an unconditional white foreground, with hardcoded green
  /// and red for success and error.
  ///
  /// This is the default so upgrading does not restyle anything, but it is
  /// not dark-mode safe and it paints a filled background onto text and
  /// outlined buttons. 2.0.0 will default to [material3].
  legacy,

  /// Colours come from the ambient [ColorScheme].
  ///
  /// Success and error use container/on-container role pairs, whose contrast
  /// is guaranteed in both brightnesses, and the button's own [ButtonStyle]
  /// is left alone in the idle state so Material theming applies normally.
  material3,
}

/// The per-state colours a [LoadingButton] paints.
///
/// A null field means "leave this state's colour to the button's own
/// [ButtonStyle]", which is what keeps [LoadingButtonColorStrategy.material3]
/// from overriding an app's theme while idle.
@immutable
class LoadingButtonColors {
  const LoadingButtonColors({
    this.loading,
    this.onLoading,
    this.success,
    this.onSuccess,
    this.error,
    this.onError,
  });

  /// Material 3 role pairs. Contrast-safe in both brightnesses.
  factory LoadingButtonColors.fromScheme(ColorScheme scheme) =>
      LoadingButtonColors(
        success: scheme.tertiaryContainer,
        onSuccess: scheme.onTertiaryContainer,
        error: scheme.errorContainer,
        onError: scheme.onErrorContainer,
      );

  /// Conventional traffic-light colours, tone-mapped per [brightness] for apps
  /// that want green and red rather than scheme roles.
  factory LoadingButtonColors.traffic(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;
    return LoadingButtonColors(
      success: dark ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32),
      onSuccess: Colors.white,
      error: dark ? const Color(0xFFB3261E) : const Color(0xFFD32F2F),
      onError: Colors.white,
    );
  }

  /// Exactly the pre-1.1.0 colours.
  static const LoadingButtonColors legacy = LoadingButtonColors(
    success: Colors.green,
    onSuccess: Colors.white,
    error: Colors.red,
    onError: Colors.white,
  );

  /// Background while loading. Null leaves the idle background in place.
  final Color? loading;

  /// Foreground while loading.
  final Color? onLoading;

  /// Background in [ActionState.success].
  final Color? success;

  /// Foreground in [ActionState.success].
  final Color? onSuccess;

  /// Background in [ActionState.error].
  final Color? error;

  /// Foreground in [ActionState.error].
  final Color? onError;

  LoadingButtonColors copyWith({
    Color? loading,
    Color? onLoading,
    Color? success,
    Color? onSuccess,
    Color? error,
    Color? onError,
  }) =>
      LoadingButtonColors(
        loading: loading ?? this.loading,
        onLoading: onLoading ?? this.onLoading,
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        error: error ?? this.error,
        onError: onError ?? this.onError,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingButtonColors &&
          other.loading == loading &&
          other.onLoading == onLoading &&
          other.success == success &&
          other.onSuccess == onSuccess &&
          other.error == error &&
          other.onError == onError;

  @override
  int get hashCode =>
      Object.hash(loading, onLoading, success, onSuccess, error, onError);
}
