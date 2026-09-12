import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

import '../gallery.dart';

/// The two wrapper families over the stock Material buttons:
///
/// * `XxxAutoLoadingButton` — busy for exactly as long as the async callback
///   runs; you never touch a flag.
/// * `XxxLoadingButton` — busy while the `isLoading` flag you pass is true.
class AutoLoadingPage extends StatefulWidget {
  const AutoLoadingPage({super.key});

  @override
  State<AutoLoadingPage> createState() => _AutoLoadingPageState();
}

class _AutoLoadingPageState extends State<AutoLoadingPage> {
  /// Reaches an auto-loading button's state without a tap.
  final GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>>
      _programmaticKey =
      GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>>();

  final WidgetStatesController _statesController = WidgetStatesController();

  bool _isLoading = false;
  bool _bookmarked = false;

  @override
  void dispose() {
    _statesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Auto-loading and flag-driven buttons',
      blurb: 'Drop-in replacements for ElevatedButton, FilledButton, '
          'OutlinedButton, TextButton and IconButton that know how to be busy.',
      children: <Widget>[
        _autoSection(),
        _labelsSection(),
        _iconSection(),
        _programmaticSection(),
        _flagSection(),
      ],
    );
  }

  // ------------------------------------------------------------------ auto

  Widget _autoSection() => GallerySection(
        title: 'Driven by the callback',
        subtitle: 'The button enters the loading state on tap and leaves it '
            'when the returned future settles — including when it throws, '
            'which is the bug this family used to have.',
        code: 'ElevatedAutoLoadingButton(onPressed: () async => api.save(), '
            "child: Text('Save'))",
        child: DemoWrap(
          children: <Widget>[
            ElevatedAutoLoadingButton(
              key: const Key('auto-elevated'),
              onPressed: fakeWork,
              child: const Text('Elevated'),
            ),
            ElevatedAutoLoadingButton.icon(
              onPressed: fakeWork,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Elevated icon'),
            ),
            FilledAutoLoadingButton(
              onPressed: fakeWork,
              child: const Text('Filled'),
            ),
            FilledAutoLoadingButton.icon(
              onPressed: fakeWork,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Filled icon'),
            ),
            FilledAutoLoadingButton.tonal(
              onPressed: fakeWork,
              child: const Text('Tonal'),
            ),
            FilledAutoLoadingButton.tonalIcon(
              onPressed: fakeWork,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Tonal icon'),
            ),
            OutlinedAutoLoadingButton(
              onPressed: fakeWork,
              child: const Text('Outlined'),
            ),
            OutlinedAutoLoadingButton.icon(
              onPressed: fakeWork,
              icon: const Icon(Icons.tune),
              label: const Text('Outlined icon'),
            ),
            TextAutoLoadingButton(
              onPressed: fakeWork,
              child: const Text('Text'),
            ),
            TextAutoLoadingButton.icon(
              onPressed: fakeWork,
              icon: const Icon(Icons.link),
              label: const Text('Text icon'),
            ),
            ElevatedAutoLoadingButton(
              key: const Key('auto-throws'),
              onPressed: fakeFailure,
              child: const Text('Throws (recovers)'),
            ),
            const ElevatedAutoLoadingButton(
              onPressed: null,
              child: Text('Disabled'),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------- labels

  Widget _labelsSection() => GallerySection(
        title: 'What the busy state looks like',
        subtitle: 'By default the label is replaced by an indicator. Give it a '
            'loadingLabel to keep text beside the indicator, an indicator to '
            'choose what spins, or a loadingIcon to replace it outright.',
        code: 'FilledAutoLoadingButton(indicator: LoadingIndicator.orb(), '
            "loadingLabel: Text('Saving…'))",
        child: DemoWrap(
          children: <Widget>[
            FilledAutoLoadingButton(
              onPressed: fakeWork,
              loadingLabel: const Text('Saving…'),
              child: const Text('With a label'),
            ),
            FilledAutoLoadingButton(
              onPressed: fakeWork,
              indicator: const LoadingIndicator.orb(
                state: OrbState.searching,
                size: 22,
              ),
              loadingLabel: const Text('Searching…'),
              child: const Text('With an orb'),
            ),
            OutlinedAutoLoadingButton(
              onPressed: fakeWork,
              loadingIcon: const Icon(Icons.hourglass_top, size: 20),
              child: const Text('With an icon'),
            ),
            FilledAutoLoadingButton(
              onPressed: fakeWork,
              switchDuration: const Duration(milliseconds: 600),
              loadingLabel: const Text('Slowly…'),
              child: const Text('Slow size switch'),
            ),
            ElevatedAutoLoadingButton(
              onPressed: fakeWork,
              onLongPress: () => fakeWork(const Duration(seconds: 2)),
              statesController: _statesController,
              onHover: (bool hovering) {},
              onFocusChange: (bool focused) {},
              child: const Text('Long-press me too'),
            ),
          ],
        ),
      );

  // ----------------------------------------------------------------- icons

  Widget _iconSection() => GallerySection(
        title: 'IconAutoLoadingButton',
        subtitle: 'All four Material 3 icon-button variants, plus the '
            'selected/unselected pair.',
        code: 'IconAutoLoadingButton.filledTonal(onPressed: refresh, '
            'icon: Icon(Icons.refresh))',
        child: DemoWrap(
          children: <Widget>[
            LabelledDemo(
              label: 'standard',
              width: 110,
              child: IconAutoLoadingButton(
                onPressed: fakeWork,
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
              ),
            ),
            LabelledDemo(
              label: 'filled',
              width: 110,
              child: IconAutoLoadingButton.filled(
                onPressed: fakeWork,
                icon: const Icon(Icons.cloud_upload_outlined),
              ),
            ),
            LabelledDemo(
              label: 'filledTonal',
              width: 110,
              child: IconAutoLoadingButton.filledTonal(
                onPressed: fakeWork,
                indicator: const LoadingIndicator.orb(
                  state: OrbState.breathing,
                  size: 20,
                ),
                icon: const Icon(Icons.auto_awesome_outlined),
              ),
            ),
            LabelledDemo(
              label: 'outlined',
              width: 110,
              child: IconAutoLoadingButton.outlined(
                onPressed: fakeWork,
                icon: const Icon(Icons.delete_outline),
              ),
            ),
            LabelledDemo(
              label: 'selectable',
              width: 130,
              child: IconAutoLoadingButton.filledTonal(
                isSelected: _bookmarked,
                selectedIcon: const Icon(Icons.bookmark),
                selectedLoadingIcon: const Icon(Icons.bookmark_border),
                icon: const Icon(Icons.bookmark_outline),
                onPressed: () async {
                  await fakeWork(const Duration(milliseconds: 600));
                  if (mounted) setState(() => _bookmarked = !_bookmarked);
                },
              ),
            ),
            const LabelledDemo(
              label: 'disabled',
              width: 110,
              child: IconAutoLoadingButton(
                onPressed: null,
                icon: Icon(Icons.block),
              ),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------- programmatic

  Widget _programmaticSection() => GallerySection(
        title: 'Pressing one from code',
        subtitle: 'AutoLoadingButtonState is public. A GlobalKey onto it gives '
            'you doPress() and doLongPress(), each returning the future of the '
            'run — so a failure comes back to you instead of going unhandled.',
        code: 'GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>>()'
            '.currentState?.doPress()',
        child: DemoWrap(
          children: <Widget>[
            ElevatedAutoLoadingButton(
              key: _programmaticKey,
              onPressed: fakeWork,
              onLongPress: () => fakeWork(const Duration(seconds: 2)),
              child: const Text('Target'),
            ),
            OutlinedButton(
              onPressed: () => unawaited(_press(longPress: false)),
              child: const Text('doPress()'),
            ),
            OutlinedButton(
              onPressed: () => unawaited(_press(longPress: true)),
              child: const Text('doLongPress()'),
            ),
          ],
        ),
      );

  Future<void> _press({required bool longPress}) async {
    final AutoLoadingButtonState<ElevatedAutoLoadingButton>? state =
        _programmaticKey.currentState;
    if (state == null) return;
    try {
      await (longPress ? state.doLongPress() : state.doPress());
      if (mounted) showNote(context, 'Run finished');
    } catch (error) {
      if (mounted) showNote(context, 'Run failed: $error');
    }
  }

  // ------------------------------------------------------------------ flag

  Widget _flagSection() => GallerySection(
        title: 'Driven by a flag',
        subtitle: 'The same widgets with an isLoading bool instead of a '
            'callback, for when the busy state lives in your own state '
            'management. loadingClickable keeps the button tappable while busy.',
        code: 'FilledLoadingButton(isLoading: state.saving, '
            'onPressed: save, child: Text(\'Save\'))',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Switch(
                  key: const Key('is-loading-switch'),
                  value: _isLoading,
                  onChanged: (bool value) => setState(() => _isLoading = value),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('isLoading: $_isLoading')),
              ],
            ),
            const SizedBox(height: 16),
            DemoWrap(
              key: const Key('flag-driven-demos'),
              children: <Widget>[
                ElevatedLoadingButton(
                  isLoading: _isLoading,
                  onPressed: () {},
                  child: const Text('Elevated'),
                ),
                ElevatedLoadingButton.icon(
                  isLoading: _isLoading,
                  onPressed: () {},
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Elevated icon'),
                ),
                FilledLoadingButton(
                  isLoading: _isLoading,
                  onPressed: () {},
                  loadingLabel: const Text('Saving…'),
                  child: const Text('Filled'),
                ),
                FilledLoadingButton.icon(
                  isLoading: _isLoading,
                  onPressed: () {},
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Filled icon'),
                ),
                FilledLoadingButton.tonal(
                  isLoading: _isLoading,
                  onPressed: () {},
                  indicator: const LoadingIndicator.orb(
                    state: OrbState.working,
                    size: 20,
                  ),
                  child: const Text('Tonal'),
                ),
                FilledLoadingButton.tonalIcon(
                  isLoading: _isLoading,
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Tonal icon'),
                ),
                OutlinedLoadingButton(
                  isLoading: _isLoading,
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
                OutlinedLoadingButton.icon(
                  isLoading: _isLoading,
                  onPressed: () {},
                  icon: const Icon(Icons.tune),
                  label: const Text('Outlined icon'),
                ),
                TextLoadingButton(
                  isLoading: _isLoading,
                  onPressed: () {},
                  child: const Text('Text'),
                ),
                TextLoadingButton.icon(
                  isLoading: _isLoading,
                  onPressed: () {},
                  icon: const Icon(Icons.link),
                  label: const Text('Text icon'),
                ),
                FilledLoadingButton(
                  isLoading: _isLoading,
                  loadingClickable: true,
                  onPressed: () => showNote(context, 'Tapped while busy'),
                  loadingLabel: const Text('Still tappable'),
                  child: const Text('loadingClickable'),
                ),
              ],
            ),
          ],
        ),
      );
}
