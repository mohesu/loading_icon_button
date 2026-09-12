import 'package:flutter/material.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

import '../gallery.dart';

/// [ArgonButton] collapses into its own loader; [ArgonTimerButton] does the
/// same and counts down before it comes back.
class ArgonPage extends StatefulWidget {
  const ArgonPage({super.key});

  @override
  State<ArgonPage> createState() => _ArgonPageState();
}

class _ArgonPageState extends State<ArgonPage> {
  bool _roundLoadingShape = true;
  double _borderRadius = 24;

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Argon buttons',
      blurb: 'A width animation rather than a content swap: the button shrinks '
          'to a circle around its loader, then springs back.',
      children: <Widget>[
        _basics(),
        _shapeControls(),
        _loaders(),
        _timer(),
      ],
    );
  }

  ColorScheme get _scheme => Theme.of(context).colorScheme;

  TextStyle get _labelStyle => TextStyle(
        color: _scheme.onPrimary,
        fontWeight: FontWeight.w600,
      );

  // ---------------------------------------------------------------- basics

  Widget _basics() => GallerySection(
        title: 'The shape of it',
        subtitle: 'onTap hands you startLoading, stopLoading and the current '
            'state. Call startLoading, do the work, call stopLoading — both '
            'are safe to call after the button is gone.',
        code: 'onTap: (startLoading, stopLoading, state) async { '
            'startLoading(); await save(); stopLoading(); }',
        child: DemoWrap(
          children: <Widget>[
            ArgonButton(
              key: const Key('argon-basic'),
              height: 50,
              width: 220,
              minWidth: 50,
              borderRadius: 25,
              color: _scheme.primary,
              loader: Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _scheme.onPrimary,
                ),
              ),
              onTap: _run,
              child: Text('Sign in', style: _labelStyle),
            ),
            ArgonButton(
              height: 50,
              width: 220,
              minWidth: 50,
              borderRadius: 12,
              color: _scheme.tertiary,
              elevation: 0,
              borderSide: BorderSide(color: _scheme.outline),
              loader: Padding(
                padding: const EdgeInsets.all(10),
                child: ThinkingOrb(
                  state: OrbState.weaving,
                  size: 30,
                  color: _scheme.onTertiary,
                ),
              ),
              onTap: _run,
              child: Text(
                'Orb loader',
                style: TextStyle(
                  color: _scheme.onTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ArgonButton(
              height: 50,
              width: 220,
              minWidth: 50,
              borderRadius: 25,
              disabledColor: _scheme.surfaceContainerHighest,
              disabledTextColor: _scheme.onSurfaceVariant,
              // A null onTap disables the button. Before 1.1.0 this threw.
              onTap: null,
              child: Text(
                'Disabled (onTap: null)',
                style: TextStyle(color: _scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );

  Future<void> _run(
    Function startLoading,
    Function stopLoading,
    ArgonButtonState state,
  ) async {
    if (state != ArgonButtonState.idle) return;
    startLoading();
    await fakeWork(const Duration(milliseconds: 1600));
    stopLoading();
  }

  // ---------------------------------------------------------------- shapes

  Widget _shapeControls() => GallerySection(
        title: 'Collapsed shape',
        subtitle: 'roundLoadingShape animates the corner radius to a full '
            'circle while loading. Turn it off to keep the resting radius.',
        code: 'ArgonButton(roundLoadingShape: false, borderRadius: 8)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Switch(
                  key: const Key('round-shape-switch'),
                  value: _roundLoadingShape,
                  onChanged: (bool value) =>
                      setState(() => _roundLoadingShape = value),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('roundLoadingShape: $_roundLoadingShape'),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                const Text('borderRadius'),
                Expanded(
                  child: Slider(
                    value: _borderRadius,
                    max: 25,
                    divisions: 25,
                    label: _borderRadius.round().toString(),
                    onChanged: (double value) =>
                        setState(() => _borderRadius = value),
                  ),
                ),
                Text(_borderRadius.round().toString()),
              ],
            ),
            const SizedBox(height: 8),
            ArgonButton(
              height: 56,
              width: 260,
              minWidth: 56,
              borderRadius: _borderRadius,
              roundLoadingShape: _roundLoadingShape,
              color: _scheme.primary,
              loader: Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _scheme.onPrimary,
                ),
              ),
              onTap: _run,
              child: Text('Watch the corners', style: _labelStyle),
            ),
          ],
        ),
      );

  // --------------------------------------------------------------- loaders

  Widget _loaders() => GallerySection(
        title: 'Timing and easing',
        subtitle: 'animationDuration, curve and reverseCurve control the '
            'collapse; minWidth is how narrow it gets.',
        code: 'ArgonButton(animationDuration: Duration(milliseconds: 900), '
            'curve: Curves.elasticOut)',
        child: DemoWrap(
          children: <Widget>[
            ArgonButton(
              height: 50,
              width: 200,
              minWidth: 50,
              borderRadius: 25,
              animationDuration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInBack,
              color: _scheme.secondary,
              loader: Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _scheme.onSecondary,
                ),
              ),
              onTap: _run,
              child: Text(
                'Springy',
                style: TextStyle(
                  color: _scheme.onSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ArgonButton(
              height: 50,
              width: 200,
              minWidth: 160,
              borderRadius: 25,
              color: _scheme.primary,
              loader: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ThinkingOrb(
                    state: OrbState.listening,
                    size: 24,
                    color: _scheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text('Wait…', style: _labelStyle),
                ],
              ),
              onTap: _run,
              child: Text('Wide loader', style: _labelStyle),
            ),
          ],
        ),
      );

  // ----------------------------------------------------------------- timer

  Widget _timer() => GallerySection(
        title: 'ArgonTimerButton',
        subtitle: 'The countdown variant. startTimer(seconds) collapses the '
            'button and rebuilds the loader once a second with the seconds '
            'left; it throws an ArgumentError on a non-positive duration.',
        code: 'onTap: (startTimer, state) => startTimer(10)',
        child: DemoWrap(
          children: <Widget>[
            ArgonTimerButton(
              key: const Key('argon-timer'),
              height: 50,
              width: 220,
              minWidth: 50,
              borderRadius: 25,
              color: _scheme.primary,
              loader: (int seconds) => Text(
                'Resend in $seconds',
                style: _labelStyle,
              ),
              onTap: (Function startTimer, ArgonButtonState? state) {
                if (state == ArgonButtonState.idle) {
                  startTimer(10);
                }
              },
              child: Text('Send code', style: _labelStyle),
            ),
            ArgonTimerButton(
              height: 50,
              width: 220,
              minWidth: 160,
              borderRadius: 12,
              // Starts counting down the moment it is mounted.
              initialTimer: 5,
              color: _scheme.tertiary,
              loader: (int seconds) => Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ThinkingOrb(
                    state: OrbState.breathing,
                    size: 22,
                    color: _scheme.onTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${seconds}s left',
                    style: TextStyle(
                      color: _scheme.onTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              onTap: (Function startTimer, ArgonButtonState? state) {
                if (state == ArgonButtonState.idle) {
                  startTimer(5);
                }
              },
              child: Text(
                'initialTimer: 5',
                style: TextStyle(
                  color: _scheme.onTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}
