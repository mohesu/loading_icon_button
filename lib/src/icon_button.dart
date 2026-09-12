part of '../loading_icon_button.dart';

/// A text-and-icon pair for [buildChildWithIcon].
///
/// Unused inside this package and superseded by composing a [Row] (or a
/// [Wrap]) yourself, which gives you control over alignment, overflow and
/// spacing that this type never exposed.
@Deprecated(
  'Compose your own Row/Wrap of an Icon and a Text instead. '
  'This feature was deprecated after v1.1.0.',
)
class IconButtonLoading {
  /// The label shown beside [icon], if any.
  final String? text;

  /// The leading icon, if any.
  final Icon? icon;

  /// The colour the caller intended for the pair. Never applied by
  /// [buildChildWithIcon]; it was always the caller's job.
  final Color color;

  /// Creates an [IconButtonLoading].
  const IconButtonLoading({
    this.text,
    this.icon,
    required this.color,
  });
}

/// Lays out [IconButtonLoading.icon] and [IconButtonLoading.text] in a row.
///
/// A public top-level function that is used nowhere in this package and leaks
/// into the namespace of every library that imports it. Compose the row
/// yourself instead:
///
/// ```dart
/// Row(
///   mainAxisSize: MainAxisSize.min,
///   children: [
///     icon,
///     SizedBox(width: gap),
///     Text(text, style: textStyle),
///   ],
/// )
/// ```
@Deprecated(
  'Compose your own Row of an Icon, a SizedBox gap and a Text instead. '
  'This feature was deprecated after v1.1.0.',
)
Widget buildChildWithIcon(
  // ignore: deprecated_member_use_from_same_package
  IconButtonLoading iconButtonLoading,
  double iconPadding,
  TextStyle textStyle,
) {
  // ignore: deprecated_member_use_from_same_package
  return buildChildWithIC(
    iconButtonLoading.text,
    iconButtonLoading.icon,
    iconPadding,
    textStyle,
  );
}

/// Lays out [icon] and [text] in a row separated by [gap].
///
/// A public top-level function that is used nowhere in this package and leaks
/// into the namespace of every library that imports it. Compose the row
/// yourself instead — see [buildChildWithIcon] for the shape.
@Deprecated(
  'Compose your own Row of an Icon, a SizedBox gap and a Text instead. '
  'This feature was deprecated after v1.1.0.',
)
Widget buildChildWithIC(
  String? text,
  Icon? icon,
  double gap,
  TextStyle textStyle,
) {
  final children = <Widget>[];
  // A bare Container() has no child and no constraints, so inside the Wrap
  // below it takes the full available width and pushes the text off the end.
  // SizedBox.shrink() occupies nothing, which is what a missing icon means.
  children.add(icon ?? const SizedBox.shrink());
  if (text != null) {
    // A childless Padding pads on all four sides, so it added vertical space
    // as well as the horizontal gap it was meant to be. A SizedBox with only a
    // width is a pure horizontal spacer.
    children.add(SizedBox(width: gap));
    children.add(
      // ignore: deprecated_member_use_from_same_package
      buildText(text, textStyle),
    );
  }

  return Wrap(
    direction: Axis.horizontal,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

/// Wraps [text] in a [Text] with [style].
///
/// A public top-level function that is used nowhere in this package and leaks
/// into the namespace of every library that imports it. Write
/// `Text(text, style: style)` instead.
@Deprecated(
  'Write Text(text, style: style) instead. '
  'This feature was deprecated after v1.1.0.',
)
Widget buildText(String text, TextStyle style) {
  return Text(
    text,
    style: style,
  );
}
