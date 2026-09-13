import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

import '../gallery.dart';

/// Everything [LoadingButton] can do: its five shapes, its state machine, the
/// controller, determinate progress, sizing, colours, indicators and the
/// interaction guards.
class LoadingButtonPage extends StatefulWidget {
  const LoadingButtonPage({super.key});

  @override
  State<LoadingButtonPage> createState() => _LoadingButtonPageState();
}

class _LoadingButtonPageState extends State<LoadingButtonPage> {
  /// Drives two buttons at once, from outside the widget tree.
  final LoadingButtonController _controller = LoadingButtonController();

  /// Held in the loading state so determinate progress stays on screen.
  final LoadingButtonController _scrub = LoadingButtonController(
    value: const LoadingButtonValue(
      state: ActionState.loading,
      progress: 0.35,
    ),
  );

  /// Driven by a real (well, fake) upload loop.
  final LoadingButtonController _upload = LoadingButtonController();

  /// Pinned to one state each, so all three colours are visible at once.
  final LoadingButtonController _pinLoading = LoadingButtonController(
    value: const LoadingButtonValue(state: ActionState.loading),
  );
  final LoadingButtonController _pinSuccess = LoadingButtonController(
    value: const LoadingButtonValue(state: ActionState.success),
  );
  final LoadingButtonController _pinError = LoadingButtonController(
    value: const LoadingButtonValue(state: ActionState.error),
  );

  /// Pinned loading, one per indicator flavour.
  final List<LoadingButtonController> _pinIndicators =
      List<LoadingButtonController>.generate(
    3,
    (int _) => LoadingButtonController(
      value: const LoadingButtonValue(state: ActionState.loading),
    ),
  );

  /// Pinned loading with progress, to show a styled progress fill at rest.
  final LoadingButtonController _pinStyled = LoadingButtonController(
    value: const LoadingButtonValue(
      state: ActionState.loading,
      progress: 0.45,
    ),
  );

  /// Pinned loading *with* progress, so the builder indicator receives a value.
  final LoadingButtonController _pinBuilder = LoadingButtonController(
    value: const LoadingButtonValue(
      state: ActionState.loading,
      progress: 0.62,
    ),
  );

  /// Reaches a button's [LoadingButtonState] without a controller.
  final GlobalKey<LoadingButtonState> _stateKey =
      GlobalKey<LoadingButtonState>();

  final FocusNode _focusNode = FocusNode(debugLabel: 'loading-button-demo');

  double _progress = 0.35;
  LoadingProgressStyle _progressStyle = LoadingProgressStyle.both;
  int _sizingIndex = 1;
  int _colorIndex = 1;
  bool _enabled = true;
  int _debouncedTaps = 0;
  ActionState _lastObservedState = ActionState.idle;

  @override
  void dispose() {
    for (final LoadingButtonController c in <LoadingButtonController>[
      _controller,
      _scrub,
      _upload,
      _pinLoading,
      _pinSuccess,
      _pinError,
      _pinStyled,
      _pinBuilder,
      ..._pinIndicators,
    ]) {
      c.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _runUpload() async {
    for (int step = 1; step <= 20; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      _upload.setProgress(step / 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'LoadingButton',
      blurb: 'One widget, one state machine: idle → loading → success or '
          'error → idle. Press it, drive it from a controller, or both.',
      children: <Widget>[
        _shapes(),
        _outcomes(),
        _controllerSection(),
        _progressSection(),
        _sizingSection(),
        _coloursSection(),
        _styleSection(),
        _indicatorSection(),
        _guardsSection(),
        _stateKeySection(),
        _builderSection(),
        _subtreeThemeSection(),
      ],
    );
  }

  // ---------------------------------------------------------------- shapes

  Widget _shapes() => GallerySection(
        title: 'Five shapes',
        subtitle: 'ButtonType picks which Material button is rendered. The '
            'state machine is identical in all five.',
        code: 'LoadingButton(type: ButtonType.filled, onPressed: submit, '
            "child: Text('Submit'))",
        child: DemoWrap(
          children: <Widget>[
            for (final ButtonType type in ButtonType.values)
              LoadingButton(
                key: Key('shape-${type.name}'),
                type: type,
                onPressed: fakeWork,
                tooltip: 'ButtonType.${type.name}',
                child: type == ButtonType.icon
                    ? const Icon(Icons.favorite_border)
                    : Text(_titleCase(type.name)),
              ),
          ],
        ),
      );

  // -------------------------------------------------------------- outcomes

  Widget _outcomes() => GallerySection(
        title: 'Success, failure and custom content',
        subtitle: 'A throwing callback lands in the error state and calls '
            'onFailure with the error and its stack trace. Each phase can '
            'show a label or a widget of your own.',
        code:
            'onFailure: (Object error, StackTrace stack) => report(error, stack)',
        child: DemoWrap(
          children: <Widget>[
            LoadingButton(
              key: const Key('outcome-success'),
              type: ButtonType.filled,
              onPressed: fakeWork,
              loadingText: 'Sending…',
              successText: 'Sent',
              onSuccess: () => showNote(context, 'onSuccess fired'),
              child: const Text('Succeeds'),
            ),
            LoadingButton(
              key: const Key('outcome-failure'),
              type: ButtonType.filled,
              onPressed: fakeFailure,
              errorText: 'Rejected',
              onFailure: (Object error, StackTrace stackTrace) =>
                  showNote(context, 'onFailure: $error'),
              child: const Text('Fails'),
            ),
            LoadingButton(
              type: ButtonType.outlined,
              onPressed: fakeWork,
              loadingWidget: const SizedBox.square(
                dimension: 22,
                child: ThinkingOrb(state: OrbState.listening, size: 22),
              ),
              successWidget: const Icon(Icons.thumb_up_outlined, size: 20),
              errorWidget: const Icon(Icons.thumb_down_outlined, size: 20),
              child: const Text('Custom widgets'),
            ),
            LoadingButton(
              type: ButtonType.text,
              onPressed: fakeWork,
              resetAfterDuration: false,
              successText: 'Stays done',
              child: const Text('No auto-reset'),
            ),
          ],
        ),
      );

  // ------------------------------------------------------------ controller

  Widget _controllerSection() => GallerySection(
        title: 'LoadingButtonController',
        subtitle: 'A ValueNotifier<LoadingButtonValue>. Attach it to as many '
            'buttons as you like — they all mirror the same value, and '
            'press() runs every attached callback.',
        code: 'LoadingButton(controller: controller, onPressed: upload, '
            "child: Text('Upload'))",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ValueListenableBuilder<LoadingButtonValue>(
              valueListenable: _controller,
              builder: (BuildContext context, LoadingButtonValue value, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(
                      key: const Key('controller-state'),
                      label: Text('state: ${value.state.name}'),
                    ),
                    Chip(
                      label: Text(
                        value.isDeterminate
                            ? 'progress: ${(value.progress! * 100).round()}%'
                            : 'progress: indeterminate',
                      ),
                    ),
                    Chip(
                      label: Text('attached to ${_controller.attachmentCount}'),
                    ),
                    // ActionStateExtension: isIdle, isLoading, isSuccess,
                    // isError, isDisabled and isInteractive.
                    Chip(
                      label: Text(
                        value.state.isInteractive
                            ? 'a press would be accepted'
                            : 'presses are ignored',
                      ),
                    ),
                    if (value.error != null)
                      Chip(label: Text('error: ${value.error}')),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            DemoWrap(
              children: <Widget>[
                LoadingButton(
                  key: const Key('controller-primary'),
                  type: ButtonType.filled,
                  controller: _controller,
                  onPressed: fakeWork,
                  child: const Text('Primary'),
                ),
                LoadingButton(
                  type: ButtonType.outlined,
                  controller: _controller,
                  onPressed: fakeWork,
                  child: const Text('Mirror'),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              'Drive it from here',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _cmd('start()', () => _controller.start()),
                _cmd('setProgress(0.5)', () => _controller.setProgress(0.5)),
                _cmd('setProgress(null)', () => _controller.setProgress(null)),
                _cmd('success()', _controller.success),
                _cmd('error(…)', () => _controller.error('Disk full')),
                _cmd('reset()', _controller.reset),
                _cmd(
                  'setEnabled(false)',
                  () => _controller.setEnabled(false),
                ),
                _cmd('setEnabled(true)', () => _controller.setEnabled(true)),
                _cmd(
                  'setActionState(disabled)',
                  () => _controller.setActionState(ActionState.disabled),
                ),
                _cmd(
                  'startCooldown(3s)',
                  () => _controller.startCooldown(const Duration(seconds: 3)),
                ),
                _cmd('press()', () => unawaited(_controller.press())),
              ],
            ),
          ],
        ),
      );

  Widget _cmd(String label, VoidCallback onPressed) =>
      OutlinedButton(onPressed: onPressed, child: Text(label));

  // -------------------------------------------------------------- progress

  Widget _progressSection() => GallerySection(
        title: 'Determinate progress',
        subtitle: 'Report 0.0–1.0 and choose how it is drawn: on the '
            'indicator, as a fill clipped to the button shape, or both. The '
            'button below is pinned to the loading state so you can scrub it.',
        code: 'LoadingButton(progressStyle: LoadingProgressStyle.both, '
            'controller: controller)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<LoadingProgressStyle>(
                segments: const <ButtonSegment<LoadingProgressStyle>>[
                  ButtonSegment<LoadingProgressStyle>(
                    value: LoadingProgressStyle.indicator,
                    label: Text('indicator'),
                  ),
                  ButtonSegment<LoadingProgressStyle>(
                    value: LoadingProgressStyle.fill,
                    label: Text('fill'),
                  ),
                  ButtonSegment<LoadingProgressStyle>(
                    value: LoadingProgressStyle.both,
                    label: Text('both'),
                  ),
                ],
                selected: <LoadingProgressStyle>{_progressStyle},
                onSelectionChanged: (Set<LoadingProgressStyle> selection) =>
                    setState(() => _progressStyle = selection.first),
              ),
            ),
            Slider(
              value: _progress,
              label: '${(_progress * 100).round()}%',
              divisions: 20,
              onChanged: (double value) {
                setState(() => _progress = value);
                _scrub.setProgress(value);
              },
            ),
            LoadingButton(
              type: ButtonType.filled,
              controller: _scrub,
              resetAfterDuration: false,
              progressStyle: _progressStyle,
              sizing: const LoadingButtonSizing.expand(height: 52),
              child: const Text('Pinned to loading'),
            ),
            const SizedBox(height: 20),
            Text(
              'And the same thing driven by a real callback:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            LoadingButton(
              type: ButtonType.elevated,
              controller: _upload,
              onPressed: _runUpload,
              progressStyle: _progressStyle,
              successText: 'Uploaded',
              sizing: const LoadingButtonSizing.expand(height: 52),
              child: const Text('Upload 20 chunks'),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------- sizing

  Widget _sizingSection() {
    final LoadingButtonSizing sizing = switch (_sizingIndex) {
      1 => const LoadingButtonSizing.intrinsic(),
      2 => const LoadingButtonSizing.expand(height: 52),
      3 => const LoadingButtonSizing.fixed(width: 260, height: 64),
      _ => LoadingButtonSizing.legacy,
    };

    return GallerySection(
      title: 'Sizing',
      subtitle: 'legacy is a fixed 200x50 box (240 wide above a 600px window) '
          'and is still the package default. The other three are new in '
          '1.1.0. The dashed frame below is 340px wide.',
      code: 'LoadingButton(sizing: LoadingButtonSizing.intrinsic())',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(value: 0, label: Text('legacy')),
                ButtonSegment<int>(value: 1, label: Text('intrinsic')),
                ButtonSegment<int>(value: 2, label: Text('expand')),
                ButtonSegment<int>(value: 3, label: Text('fixed')),
              ],
              selected: <int>{_sizingIndex},
              onSelectionChanged: (Set<int> selection) =>
                  setState(() => _sizingIndex = selection.first),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 340,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LoadingButton(
              type: ButtonType.filled,
              sizing: sizing,
              onPressed: fakeWork,
              successText: 'Done',
              child: const Text('Resize me'),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- colours

  Widget _coloursSection() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final LoadingButtonColorStrategy strategy = _colorIndex == 0
        ? LoadingButtonColorStrategy.legacy
        : LoadingButtonColorStrategy.material3;

    final LoadingButtonColors? colors = switch (_colorIndex) {
      2 => LoadingButtonColors.traffic(theme.brightness),
      // fromScheme gives you contrast-safe role pairs; copyWith adjusts the
      // ones you care about without restating the rest.
      3 => LoadingButtonColors.fromScheme(scheme).copyWith(
          loading: scheme.secondaryContainer,
          onLoading: scheme.onSecondaryContainer,
          success: const Color(0xFF0F766E),
          onSuccess: Colors.white,
        ),
      _ => null,
    };

    Widget pinned(String label, LoadingButtonController controller) =>
        LabelledDemo(
          label: label,
          width: 170,
          child: LoadingButton(
            type: ButtonType.filled,
            controller: controller,
            resetAfterDuration: false,
            colorStrategy: strategy,
            colors: colors,
            sizing: const LoadingButtonSizing.expand(height: 48),
            successText: 'Done',
            errorText: 'Failed',
            child: const Text('Submit'),
          ),
        );

    return GallerySection(
      title: 'Colours',
      subtitle: 'legacy is the pre-1.1.0 behaviour: primaryColor plus an '
          'unconditional white foreground, which is not dark-mode safe. '
          'material3 derives everything from the ColorScheme. Toggle the app '
          'theme in the title bar to see the difference.',
      code:
          'LoadingButton(colorStrategy: LoadingButtonColorStrategy.material3)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(value: 0, label: Text('legacy')),
                ButtonSegment<int>(value: 1, label: Text('material3')),
                ButtonSegment<int>(value: 2, label: Text('traffic')),
                ButtonSegment<int>(value: 3, label: Text('custom')),
              ],
              selected: <int>{_colorIndex},
              onSelectionChanged: (Set<int> selection) =>
                  setState(() => _colorIndex = selection.first),
            ),
          ),
          const SizedBox(height: 16),
          DemoWrap(
            children: <Widget>[
              pinned('loading', _pinLoading),
              pinned('success', _pinSuccess),
              pinned('error', _pinError),
              LabelledDemo(
                label: 'live',
                width: 170,
                child: LoadingButton(
                  type: ButtonType.filled,
                  colorStrategy: strategy,
                  colors: colors,
                  onPressed: fakeWork,
                  successText: 'Done',
                  sizing: const LoadingButtonSizing.expand(height: 48),
                  child: const Text('Press me'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- style

  Widget _styleSection() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GallerySection(
      title: 'Styling',
      subtitle: 'buttonStyle is a plain Material ButtonStyle and is applied '
          'first; LoadingButtonStyle layers the package-specific bits (the '
          'per-state backgrounds, the border radius the progress fill is '
          'clipped to) on top. Reach for buttonStyle whenever Material '
          'already models what you want.',
      code: 'LoadingButton(buttonStyle: ButtonStyle(...), '
          'style: LoadingButtonStyle(borderRadius: 28))',
      child: DemoWrap(
        children: <Widget>[
          LabelledDemo(
            label: 'buttonStyle',
            width: 220,
            child: LoadingButton(
              type: ButtonType.elevated,
              onPressed: fakeWork,
              successText: 'Done',
              buttonStyle: ButtonStyle(
                backgroundColor:
                    WidgetStatePropertyAll<Color>(scheme.tertiaryContainer),
                foregroundColor:
                    WidgetStatePropertyAll<Color>(scheme.onTertiaryContainer),
                elevation: const WidgetStatePropertyAll<double>(6),
                shape: WidgetStatePropertyAll<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              sizing: const LoadingButtonSizing.expand(height: 52),
              child: const Text('Material style'),
            ),
          ),
          LabelledDemo(
            label: 'LoadingButtonStyle',
            width: 220,
            child: LoadingButton(
              type: ButtonType.outlined,
              onPressed: fakeWork,
              successText: 'Done',
              style: LoadingButtonStyle(
                backgroundColor: scheme.surfaceContainerHighest,
                foregroundColor: scheme.onSurface,
                loadingBackgroundColor: scheme.secondaryContainer,
                successBackgroundColor: scheme.tertiaryContainer,
                errorBackgroundColor: scheme.errorContainer,
                borderColor: scheme.outline,
                borderWidth: 1.5,
                borderRadius: 28,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              sizing: const LoadingButtonSizing.expand(height: 52),
              child: const Text('Package style'),
            ),
          ),
          LabelledDemo(
            label: 'both, with a progress fill',
            width: 220,
            child: LoadingButton(
              type: ButtonType.filled,
              controller: _pinStyled,
              resetAfterDuration: false,
              progressStyle: LoadingProgressStyle.both,
              buttonStyle: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(scheme.primary),
                foregroundColor:
                    WidgetStatePropertyAll<Color>(scheme.onPrimary),
              ),
              // The fill is clipped to this radius, so keep the two in step.
              style: const LoadingButtonStyle(borderRadius: 28),
              sizing: const LoadingButtonSizing.expand(height: 52),
              child: const Text('Styled fill'),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- indicator

  Widget _indicatorSection() => GallerySection(
        title: 'Indicators',
        subtitle: 'LoadingIndicator has four constructors and every button '
            'family in the package understands all of them. These four are '
            'pinned to the loading state.',
        code: 'LoadingButton(indicator: LoadingIndicator.orb('
            'state: OrbState.composing))',
        child: DemoWrap(
          children: <Widget>[
            LabelledDemo(
              label: '.circular()',
              width: 160,
              child: LoadingButton(
                type: ButtonType.filled,
                controller: _pinIndicators[0],
                resetAfterDuration: false,
                indicator: const LoadingIndicator.circular(
                  size: 22,
                  strokeWidth: 2.5,
                ),
                sizing: const LoadingButtonSizing.expand(height: 48),
                child: const Text('Busy'),
              ),
            ),
            LabelledDemo(
              label: '.orb()',
              width: 160,
              child: LoadingButton(
                type: ButtonType.filled,
                controller: _pinIndicators[1],
                resetAfterDuration: false,
                indicator: const LoadingIndicator.orb(
                  state: OrbState.composing,
                  size: 24,
                  speed: 1.2,
                ),
                sizing: const LoadingButtonSizing.expand(height: 48),
                child: const Text('Busy'),
              ),
            ),
            LabelledDemo(
              label: '.widget()',
              width: 160,
              child: LoadingButton(
                type: ButtonType.filled,
                controller: _pinIndicators[2],
                resetAfterDuration: false,
                indicator: const LoadingIndicator.widget(
                  Icon(Icons.hourglass_bottom, size: 22),
                ),
                sizing: const LoadingButtonSizing.expand(height: 48),
                child: const Text('Busy'),
              ),
            ),
            LabelledDemo(
              label: '.builder()',
              width: 160,
              child: LoadingButton(
                type: ButtonType.filled,
                controller: _pinBuilder,
                resetAfterDuration: false,
                indicator: LoadingIndicator.builder(
                  (BuildContext context, double? progress) => Text(
                    progress == null ? '…' : '${(progress * 100).round()}%',
                  ),
                ),
                sizing: const LoadingButtonSizing.expand(height: 48),
                child: const Text('Busy'),
              ),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------- guards

  Widget _guardsSection() => GallerySection(
        title: 'Guards and niceties',
        subtitle: 'debounce ignores taps that arrive too soon after the last '
            'accepted one; cooldown holds the button disabled after a run; '
            'enabled maps straight onto ActionState.disabled.',
        code: 'LoadingButton(debounce: Duration(seconds: 2), '
            'cooldown: Duration(seconds: 3), enabled: false)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoWrap(
              children: <Widget>[
                LabelledDemo(
                  label: 'debounce 2s — accepted: $_debouncedTaps',
                  width: 240,
                  child: LoadingButton(
                    type: ButtonType.filled,
                    debounce: const Duration(seconds: 2),
                    successDuration: const Duration(milliseconds: 400),
                    onPressed: () async {
                      setState(() => _debouncedTaps++);
                      await fakeWork(const Duration(milliseconds: 300));
                    },
                    sizing: const LoadingButtonSizing.expand(height: 48),
                    child: const Text('Tap me fast'),
                  ),
                ),
                LabelledDemo(
                  label: 'cooldown 3s',
                  width: 200,
                  child: LoadingButton(
                    type: ButtonType.outlined,
                    cooldown: const Duration(seconds: 3),
                    successDuration: const Duration(milliseconds: 400),
                    onPressed: () =>
                        fakeWork(const Duration(milliseconds: 400)),
                    successText: 'Sent',
                    sizing: const LoadingButtonSizing.expand(height: 48),
                    child: const Text('Resend code'),
                  ),
                ),
                LabelledDemo(
                  label: 'transitionBuilder',
                  width: 200,
                  child: LoadingButton(
                    type: ButtonType.filled,
                    onPressed: fakeWork,
                    successText: 'Zoomed',
                    animationDuration: const Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) =>
                            ScaleTransition(scale: animation, child: child),
                    sizing: const LoadingButtonSizing.expand(height: 48),
                    child: const Text('Scale, not fade'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: <Widget>[
                Switch(
                  key: const Key('enabled-switch'),
                  value: _enabled,
                  onChanged: (bool value) => setState(() => _enabled = value),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _enabled
                        ? 'enabled: true'
                        : 'enabled: false — the button reports '
                            'ActionState.disabled',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LoadingButton(
              key: const Key('enabled-button'),
              type: ButtonType.filled,
              enabled: _enabled,
              autofocus: false,
              focusNode: _focusNode,
              tooltip: 'Focusable, and disabled by the switch above',
              onPressed: fakeWork,
              onStateChanged: (ActionState state) =>
                  setState(() => _lastObservedState = state),
              sizing: const LoadingButtonSizing.expand(height: 48),
              child: const Text('Focusable button'),
            ),
            const SizedBox(height: 10),
            Text('onStateChanged saw: ${_lastObservedState.name}'),
          ],
        ),
      );

  // ------------------------------------------------------------- state key

  Widget _stateKeySection() => GallerySection(
        title: 'Reaching the State directly',
        subtitle: 'LoadingButtonState is public, so a GlobalKey gets you '
            'press() and currentState without a controller. A controller is '
            'usually the better tool, but this works.',
        code: 'GlobalKey<LoadingButtonState>().currentState?.press()',
        child: DemoWrap(
          children: <Widget>[
            LoadingButton(
              key: _stateKey,
              type: ButtonType.filled,
              onPressed: fakeWork,
              successText: 'Ran',
              child: const Text('Target'),
            ),
            OutlinedButton(
              onPressed: () => unawaited(
                  _stateKey.currentState?.press() ?? Future<void>.value()),
              child: const Text('press() it from here'),
            ),
            OutlinedButton(
              onPressed: () => showNote(
                context,
                'currentState: '
                '${_stateKey.currentState?.currentState.name ?? 'unmounted'}',
              ),
              child: const Text('read currentState'),
            ),
          ],
        ),
      );

  // --------------------------------------------------------------- builder

  Widget _builderSection() => GallerySection(
        title: 'Fluent builder',
        subtitle: 'LoadingButtonBuilder is a mutable, single-use builder: '
            'configure it, build it once.',
        code: 'LoadingButtonBuilder.filled().onPressed(submit)'
            ".child(Text('Go')).build()",
        child: LoadingButtonBuilder.filled()
            .onPressed(fakeWork)
            .child(const Text('Built fluently'))
            .indicator(
                const LoadingIndicator.orb(state: OrbState.solving, size: 22))
            .successText('Built and done')
            .sizing(const LoadingButtonSizing.intrinsic())
            .tooltip('Every LoadingButton parameter has a setter')
            .onFailure((Object error, StackTrace stack) => debugPrint('$error'))
            .build(),
      );

  // ---------------------------------------------------------- subtree theme

  Widget _subtreeThemeSection() => GallerySection(
        title: 'Defaults for a subtree',
        subtitle: 'A LoadingButtonTheme widget beats the ThemeExtension, which '
            'beats the package defaults. Both buttons below inherit an orb '
            'indicator, a custom success widget and expanded sizing without '
            'saying so themselves.',
        code: 'LoadingButtonTheme(data: LoadingButtonThemeData(...), '
            'child: subtree)',
        child: LoadingButtonTheme(
          data: const LoadingButtonThemeData(
            indicator: LoadingIndicator.orb(state: OrbState.weaving, size: 24),
            successWidget: Icon(Icons.done_all, size: 20),
            sizing: LoadingButtonSizing.expand(height: 52),
            colorStrategy: LoadingButtonColorStrategy.material3,
            successDuration: Duration(milliseconds: 1200),
          ),
          child: Column(
            children: <Widget>[
              LoadingButton(
                type: ButtonType.filled,
                onPressed: fakeWork,
                child: const Text('Inherits everything'),
              ),
              const SizedBox(height: 12),
              LoadingButton(
                type: ButtonType.outlined,
                onPressed: fakeWork,
                child: const Text('So does this one'),
              ),
            ],
          ),
        ),
      );

  static String _titleCase(String value) =>
      value[0].toUpperCase() + value.substring(1);
}
