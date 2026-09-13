part of '../../loading_icon_button.dart';

/// [IconButton] with automatic loading state management implementation
///
/// When the button event is triggered, it will automatically enter the loading state, display the loading icon, and not respond to click events,
/// If [loadingIcon] is null, the default [CircularProgressIndicator] will be used.
/// At the same time, the event returns a [Future], which is completed when the loading ends, and automatically returns to the non-loading state (can refer to the mode of [RefreshIndicator]).
///
/// [style] Please refer to [IconButton.styleFrom] for generation
class IconAutoLoadingButton extends StatefulWidget {
  const IconAutoLoadingButton({
    super.key,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    required this.onPressed,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    this.selectedLoadingIcon,
    this.loadingIcon,
    this.indicator,
    required this.icon,
  })  : assert(splashRadius == null || splashRadius > 0),
        _variant = _IconButtonVariant.standard;

  /// Create a filled variant of IconButton.
  ///
  /// Filled icon buttons have higher visual impact and should be used for
  /// high emphasis actions, such as turning off a microphone or camera.
  const IconAutoLoadingButton.filled({
    super.key,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    required this.onPressed,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    this.selectedLoadingIcon,
    this.loadingIcon,
    this.indicator,
    required this.icon,
  })  : assert(splashRadius == null || splashRadius > 0),
        _variant = _IconButtonVariant.filled;

  /// Create a filled tonal variant of IconButton.
  ///
  /// Filled tonal icon buttons are a middle ground between filled and outlined
  /// icon buttons. They’re useful in contexts where the button requires slightly
  /// more emphasis than an outline would give, such as a secondary action paired
  /// with a high emphasis action.
  const IconAutoLoadingButton.filledTonal({
    super.key,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    required this.onPressed,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    this.selectedLoadingIcon,
    this.loadingIcon,
    this.indicator,
    required this.icon,
  })  : assert(splashRadius == null || splashRadius > 0),
        _variant = _IconButtonVariant.filledTonal;

  /// Create a filled tonal variant of IconButton.
  ///
  /// Outlined icon buttons are medium-emphasis buttons. They’re useful when an
  /// icon button needs more emphasis than a standard icon button but less than
  /// a filled or filled tonal icon button.
  const IconAutoLoadingButton.outlined({
    super.key,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    required this.onPressed,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    this.selectedLoadingIcon,
    this.loadingIcon,
    this.indicator,
    required this.icon,
  })  : assert(splashRadius == null || splashRadius > 0),
        _variant = _IconButtonVariant.outlined;

  /// Button click event
  ///
  /// When the click is triggered, the button will automatically enter the loading state and no longer receive new events,
  /// Until the completion of this event, the loading state can be ended
  ///
  /// If both this value and [onLongPress] are null, the button is disabled
  final AsyncCallback? onPressed;

  /// The size of the icon inside the button.
  ///
  /// If null, uses [IconThemeData.size]. If it is also null, the default size
  /// is 24.0.
  ///
  /// The size given here is passed down to the widget in the [icon] property
  /// via an [IconTheme]. Setting the size here instead of in, for example, the
  /// [Icon.size] property allows the [IconButton] to size the splash area to
  /// fit the [Icon]. If you were to set the size of the [Icon] using
  /// [Icon.size] instead, then the [IconButton] would default to 24.0 and then
  /// the [Icon] itself would likely get clipped.
  ///
  /// If [ThemeData.useMaterial3] is set to true and this is null, the size of the
  /// [IconButton] would default to 24.0. The size given here is passed down to the
  /// [ButtonStyle.iconSize] property.
  final double? iconSize;

  /// Defines how compact the icon button's layout will be.
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  ///
  /// This property can be null. If null, it defaults to [VisualDensity.standard]
  /// in Material Design 3 to make sure the button will be circular on all platforms.
  ///
  /// See also:
  ///
  ///  * [ThemeData.visualDensity], which specifies the [visualDensity] for all
  ///    widgets within a [Theme].
  final VisualDensity? visualDensity;

  /// The padding around the button's icon. The entire padded icon will react
  /// to input gestures.
  ///
  /// This property can be null. If null, it defaults to 8.0 padding on all sides.
  final EdgeInsetsGeometry? padding;

  /// Defines how the icon is positioned within the IconButton.
  ///
  /// This property can be null. If null, it defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry? alignment;

  /// The splash radius.
  ///
  /// If [ThemeData.useMaterial3] is set to true, this will not be used.
  ///
  /// If null, default splash radius of [Material.defaultSplashRadius] is used.
  final double? splashRadius;

  /// The color for the button when it has the input focus.
  ///
  /// If [ThemeData.useMaterial3] is set to true, this [focusColor] will be mapped
  /// to be the [ButtonStyle.overlayColor] in focused state, which paints on top of
  /// the button, as an overlay. Therefore, using a color with some transparency
  /// is recommended. For example, one could customize the [focusColor] below:
  ///
  /// ```dart
  /// IconButton(
  ///   focusColor: Colors.orange.withOpacity(0.3),
  ///   icon: const Icon(Icons.sunny),
  ///   onPressed: () {
  ///     // ...
  ///   },
  /// )
  /// ```
  ///
  /// Defaults to [ThemeData.focusColor] of the ambient theme.
  final Color? focusColor;

  /// The color for the button when a pointer is hovering over it.
  ///
  /// If [ThemeData.useMaterial3] is set to true, this [hoverColor] will be mapped
  /// to be the [ButtonStyle.overlayColor] in hovered state, which paints on top of
  /// the button, as an overlay. Therefore, using a color with some transparency
  /// is recommended. For example, one could customize the [hoverColor] below:
  ///
  /// ```dart
  /// IconButton(
  ///   hoverColor: Colors.orange.withOpacity(0.3),
  ///   icon: const Icon(Icons.ac_unit),
  ///   onPressed: () {
  ///     // ...
  ///   },
  /// )
  /// ```
  ///
  /// Defaults to [ThemeData.hoverColor] of the ambient theme.
  final Color? hoverColor;

  /// The color to use for the icon inside the button, if the icon is enabled.
  /// Defaults to leaving this up to the [icon] widget.
  ///
  /// The icon is enabled if [onPressed] is not null.
  ///
  /// ```dart
  /// IconButton(
  ///   color: Colors.blue,
  ///   icon: const Icon(Icons.sunny_snowing),
  ///   onPressed: () {
  ///     // ...
  ///   },
  /// )
  /// ```
  final Color? color;

  /// The primary color of the button when the button is in the down (pressed) state.
  /// The splash is represented as a circular overlay that appears above the
  /// [highlightColor] overlay. The splash overlay has a center point that matches
  /// the hit point of the user touch event. The splash overlay will expand to
  /// fill the button area if the touch is held for long enough time. If the splash
  /// color has transparency then the highlight and button color will show through.
  ///
  /// If [ThemeData.useMaterial3] is set to true, this will not be used. Use
  /// [highlightColor] instead to show the overlay color of the button when the button
  /// is in the pressed state.
  ///
  /// Defaults to the Theme's splash color, [ThemeData.splashColor].
  final Color? splashColor;

  /// The secondary color of the button when the button is in the down (pressed)
  /// state. The highlight color is represented as a solid color that is overlaid over the
  /// button color (if any). If the highlight color has transparency, the button color
  /// will show through. The highlight fades in quickly as the button is held down.
  ///
  /// If [ThemeData.useMaterial3] is set to true, this [highlightColor] will be mapped
  /// to be the [ButtonStyle.overlayColor] in pressed state, which paints on top
  /// of the button, as an overlay. Therefore, using a color with some transparency
  /// is recommended. For example, one could customize the [highlightColor] below:
  ///
  /// ```dart
  /// IconButton(
  ///   highlightColor: Colors.orange.withOpacity(0.3),
  ///   icon: const Icon(Icons.question_mark),
  ///   onPressed: () {
  ///     // ...
  ///   },
  /// )
  /// ```
  ///
  /// Defaults to the Theme's highlight color, [ThemeData.highlightColor].
  final Color? highlightColor;

  /// The color to use for the icon inside the button, if the icon is disabled.
  /// Defaults to the [ThemeData.disabledColor] of the current [Theme].
  ///
  /// The icon is disabled if [onPressed] is null.
  final Color? disabledColor;

  /// {@macro flutter.material.RawMaterialButton.mouseCursor}
  ///
  /// If set to null, will default to
  /// - [SystemMouseCursors.basic], if [onPressed] is null
  /// - [SystemMouseCursors.click], otherwise
  final MouseCursor? mouseCursor;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String? tooltip;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  /// Optional size constraints for the button.
  ///
  /// When unspecified, defaults to:
  /// ```dart
  /// const BoxConstraints(
  ///   minWidth: kMinInteractiveDimension,
  ///   minHeight: kMinInteractiveDimension,
  /// )
  /// ```
  /// where [kMinInteractiveDimension] is 48.0, and then with visual density
  /// applied.
  ///
  /// The default constraints ensure that the button is accessible.
  /// Specifying this parameter enables creation of buttons smaller than
  /// the minimum size, but it is not recommended.
  ///
  /// The visual density uses the [visualDensity] parameter if specified,
  /// and `Theme.of(context).visualDensity` otherwise.
  final BoxConstraints? constraints;

  /// Customizes this button's appearance.
  ///
  /// Non-null properties of this style override the corresponding
  /// properties in [_IconButtonM3.themeStyleOf] and [_IconButtonM3.defaultStyleOf].
  /// [WidgetStateProperty]s that resolve to non-null values will similarly
  /// override the corresponding [WidgetStateProperty]s in [_IconButtonM3.themeStyleOf]
  /// and [_IconButtonM3.defaultStyleOf].
  ///
  /// The [style] is only used for Material 3 [IconButton]. If [ThemeData.useMaterial3]
  /// is set to true, [style] is preferred for icon button customization, and any
  /// parameters defined in [style] will override the same parameters in [IconButton].
  ///
  /// For example, if [IconButton]'s [visualDensity] is set to [VisualDensity.standard]
  /// and [style]'s [visualDensity] is set to [VisualDensity.compact],
  /// the icon button will have [VisualDensity.compact] to define the button's layout.
  ///
  /// Null by default.
  final ButtonStyle? style;

  /// The optional selection state of the icon button.
  ///
  /// If this property is null, the button will behave as a normal push button,
  /// otherwise, the button will toggle between showing [icon] and [selectedIcon]
  /// based on the value of [isSelected]. If true, it will show [selectedIcon],
  /// if false it will show [icon].
  ///
  /// This property is only used if [ThemeData.useMaterial3] is true.
  final bool? isSelected;

  /// The icon to display inside the button when [isSelected] is true. This property
  /// can be null. The original [icon] will be used for both selected and unselected
  /// status if it is null.
  ///
  /// The [Icon.size] and [Icon.color] of the icon is configured automatically
  /// based on the [iconSize] and [color] properties using an [IconTheme] and
  /// therefore should not be explicitly configured in the icon widget.
  ///
  /// This property is only used if [ThemeData.useMaterial3] is true.
  ///
  /// See also:
  ///
  /// * [Icon], for icons based on glyphs from fonts instead of images.
  /// * [ImageIcon], for showing icons from [AssetImage]s or other [ImageProvider]s.
  final Widget? selectedIcon;

  /// The loading icon displayed when the button is in the loading state and [selectedIcon] is not null
  ///
  /// If it is empty, the [loadingIcon] will be used, if it is also empty, the default implementation [_LoadingChild] will be used
  final Widget? selectedLoadingIcon;

  /// The loading icon displayed when the button is in the loading state
  ///
  /// The default implementation is [_LoadingChild]
  final Widget? loadingIcon;

  /// What to show while loading. Overridden by [loadingIcon]; falls back to
  /// [LoadingButtonThemeData.indicator] and then to a
  /// [CircularProgressIndicator].
  final LoadingIndicator? indicator;

  /// The icon to display inside the button.
  ///
  /// The [Icon.size] and [Icon.color] of the icon is configured automatically
  /// based on the [iconSize] and [color] properties of _this_ widget using an
  /// [IconTheme] and therefore should not be explicitly given in the icon
  /// widget.
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  /// Variant
  final _IconButtonVariant _variant;

  @override
  State createState() => _IconAutoLoadingButtonState();
}

class _IconAutoLoadingButtonState
    extends AutoLoadingButtonState<IconAutoLoadingButton> {
  @override
  AsyncCallback? get _onPressed => widget.onPressed;

  @override
  AsyncCallback? get _onLongPress => null;

  @override
  Widget build(BuildContext context) {
    Widget icon = widget.icon;
    Widget? selectedIcon = widget.selectedIcon;

    if (_isLoading) {
      icon = _resolveLoadingIcon(widget.loadingIcon, widget.indicator);

      if (selectedIcon != null) {
        selectedIcon = widget.selectedLoadingIcon ?? icon;
      }
    }

    switch (widget._variant) {
      case _IconButtonVariant.standard:
        return IconButton(
          iconSize: widget.iconSize,
          visualDensity: widget.visualDensity,
          padding: widget.padding,
          alignment: widget.alignment,
          splashRadius: widget.splashRadius,
          color: widget.color,
          focusColor: widget.focusColor,
          hoverColor: widget.hoverColor,
          highlightColor: widget.highlightColor,
          splashColor: widget.splashColor,
          disabledColor: widget.disabledColor,
          mouseCursor: widget.mouseCursor,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          tooltip: widget.tooltip,
          enableFeedback: widget.enableFeedback,
          constraints: widget.constraints,
          style: widget.style,
          isSelected: widget.isSelected,
          onPressed: _isLoading ? null : _wrapOnPressed(),
          selectedIcon: selectedIcon,
          icon: icon,
        );
      case _IconButtonVariant.filled:
        return IconButton.filled(
          iconSize: widget.iconSize,
          visualDensity: widget.visualDensity,
          padding: widget.padding,
          alignment: widget.alignment,
          splashRadius: widget.splashRadius,
          color: widget.color,
          focusColor: widget.focusColor,
          hoverColor: widget.hoverColor,
          highlightColor: widget.highlightColor,
          splashColor: widget.splashColor,
          disabledColor: widget.disabledColor,
          mouseCursor: widget.mouseCursor,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          tooltip: widget.tooltip,
          enableFeedback: widget.enableFeedback,
          constraints: widget.constraints,
          style: widget.style,
          isSelected: widget.isSelected,
          onPressed: _isLoading ? null : _wrapOnPressed(),
          selectedIcon: selectedIcon,
          icon: icon,
        );
      case _IconButtonVariant.filledTonal:
        return IconButton.filledTonal(
          iconSize: widget.iconSize,
          visualDensity: widget.visualDensity,
          padding: widget.padding,
          alignment: widget.alignment,
          splashRadius: widget.splashRadius,
          color: widget.color,
          focusColor: widget.focusColor,
          hoverColor: widget.hoverColor,
          highlightColor: widget.highlightColor,
          splashColor: widget.splashColor,
          disabledColor: widget.disabledColor,
          mouseCursor: widget.mouseCursor,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          tooltip: widget.tooltip,
          enableFeedback: widget.enableFeedback,
          constraints: widget.constraints,
          style: widget.style,
          isSelected: widget.isSelected,
          onPressed: _isLoading ? null : _wrapOnPressed(),
          selectedIcon: selectedIcon,
          icon: icon,
        );
      case _IconButtonVariant.outlined:
        return IconButton.outlined(
          iconSize: widget.iconSize,
          visualDensity: widget.visualDensity,
          padding: widget.padding,
          alignment: widget.alignment,
          splashRadius: widget.splashRadius,
          color: widget.color,
          focusColor: widget.focusColor,
          hoverColor: widget.hoverColor,
          highlightColor: widget.highlightColor,
          splashColor: widget.splashColor,
          disabledColor: widget.disabledColor,
          mouseCursor: widget.mouseCursor,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          tooltip: widget.tooltip,
          enableFeedback: widget.enableFeedback,
          constraints: widget.constraints,
          style: widget.style,
          isSelected: widget.isSelected,
          onPressed: _isLoading ? null : _wrapOnPressed(),
          selectedIcon: selectedIcon,
          icon: icon,
        );
    }
  }
}

enum _IconButtonVariant { standard, filled, filledTonal, outlined }
