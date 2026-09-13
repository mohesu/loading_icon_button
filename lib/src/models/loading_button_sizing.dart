part of '../../loading_icon_button.dart';

/// How a [LoadingButton] decides its own width and height.
///
/// Before 1.1.0 every button was wrapped in a fixed 200x50 box — and silently
/// 240x50 whenever the window was wider than 600 logical pixels — with no way
/// to let the content or the parent decide. [LoadingButtonSizing] makes that
/// choice explicit.
///
/// The default is [legacy], so existing layouts are unchanged. New code should
/// prefer [LoadingButtonSizing.intrinsic], which is how every other Material
/// button behaves.
sealed class LoadingButtonSizing {
  const LoadingButtonSizing();

  /// The pre-1.1.0 geometry: a fixed 200x50 box, scaled to 240 wide when the
  /// window is wider than 600 logical pixels.
  ///
  /// Kept as the default so upgrading does not move anything. 2.0.0 will make
  /// [LoadingButtonSizing.intrinsic] the default and remove this mode.
  static const LoadingButtonSizing legacy = _LegacySizing();

  /// Size to the content, like an ordinary [ElevatedButton].
  ///
  /// Pass [constraints] to bound the result.
  const factory LoadingButtonSizing.intrinsic({BoxConstraints? constraints}) =
      _IntrinsicSizing;

  /// Fill the parent's width, optionally at a fixed [height].
  const factory LoadingButtonSizing.expand({double? height}) = _ExpandSizing;

  /// A fixed size. A null dimension is left to the content.
  const factory LoadingButtonSizing.fixed({double? width, double? height}) =
      _FixedSizing;
}

class _LegacySizing extends LoadingButtonSizing {
  const _LegacySizing();
}

class _IntrinsicSizing extends LoadingButtonSizing {
  const _IntrinsicSizing({this.constraints});

  final BoxConstraints? constraints;
}

class _ExpandSizing extends LoadingButtonSizing {
  const _ExpandSizing({this.height});

  final double? height;
}

class _FixedSizing extends LoadingButtonSizing {
  const _FixedSizing({this.width, this.height});

  final double? width;
  final double? height;
}
