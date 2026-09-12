import 'package:flutter/material.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

import '../gallery.dart';

/// Which ink the orbs on this page use.
enum _Tint { none, primary, tertiary }

/// All nine [OrbState]s at both tuned size tiers, with live controls for
/// theme, speed, pause and tint.
class OrbsPage extends StatefulWidget {
  const OrbsPage({super.key});

  @override
  State<OrbsPage> createState() => _OrbsPageState();
}

class _OrbsPageState extends State<OrbsPage> {
  OrbTheme _theme = OrbTheme.auto;
  _Tint _tint = _Tint.none;
  double _speed = 1;
  bool _paused = false;

  Color? get _color {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (_tint) {
      case _Tint.primary:
        return scheme.primary;
      case _Tint.tertiary:
        return scheme.tertiary;
      case _Tint.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Thinking orbs',
      blurb: 'Nine animations over a rotated, z-sorted 3D point field. No '
          'shaders, no blurs, no assets — one CustomPainter, identical on '
          'every platform Flutter supports.',
      children: <Widget>[
        _controls(),
        _grid(),
        _inline(),
        _notes(),
      ],
    );
  }

  // -------------------------------------------------------------- controls

  Widget _controls() => GallerySection(
        title: 'Controls',
        subtitle: 'Every mounted orb reads the same static clock, so the whole '
            'page stays in step no matter when each orb was built.',
        code: 'ThinkingOrb(state: OrbState.searching, size: 64, speed: 1.0, '
            'paused: false, theme: OrbTheme.auto)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _controlRow(
              'theme',
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<OrbTheme>(
                  segments: const <ButtonSegment<OrbTheme>>[
                    ButtonSegment<OrbTheme>(
                      value: OrbTheme.auto,
                      label: Text('auto'),
                    ),
                    ButtonSegment<OrbTheme>(
                      value: OrbTheme.light,
                      label: Text('light'),
                    ),
                    ButtonSegment<OrbTheme>(
                      value: OrbTheme.dark,
                      label: Text('dark'),
                    ),
                  ],
                  selected: <OrbTheme>{_theme},
                  onSelectionChanged: (Set<OrbTheme> selection) =>
                      setState(() => _theme = selection.first),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _controlRow(
              'tint',
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_Tint>(
                  segments: const <ButtonSegment<_Tint>>[
                    ButtonSegment<_Tint>(
                      value: _Tint.none,
                      label: Text('monochrome'),
                    ),
                    ButtonSegment<_Tint>(
                      value: _Tint.primary,
                      label: Text('primary'),
                    ),
                    ButtonSegment<_Tint>(
                      value: _Tint.tertiary,
                      label: Text('tertiary'),
                    ),
                  ],
                  selected: <_Tint>{_tint},
                  onSelectionChanged: (Set<_Tint> selection) =>
                      setState(() => _tint = selection.first),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _controlRow(
              'speed',
              Row(
                children: <Widget>[
                  Expanded(
                    child: Slider(
                      value: _speed,
                      min: 0.25,
                      max: 3,
                      divisions: 11,
                      label: '${_speed.toStringAsFixed(2)}x',
                      onChanged: (double value) =>
                          setState(() => _speed = value),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text('${_speed.toStringAsFixed(2)}x'),
                  ),
                ],
              ),
            ),
            _controlRow(
              'paused',
              Row(
                children: <Widget>[
                  Switch(
                    key: const Key('orb-pause-switch'),
                    value: _paused,
                    onChanged: (bool value) => setState(() => _paused = value),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _paused
                          ? 'frozen on the current frame'
                          : 'animating (also stops automatically when the '
                              'route is inactive or the platform asks for '
                              'reduced motion)',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _controlRow(String label, Widget control) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(child: control),
        ],
      );

  // ------------------------------------------------------------------ grid

  Widget _grid() => GallerySection(
        title: 'Nine states, two tiers',
        subtitle:
            'Sizes below kOrbTierBreakpoint (${kOrbTierBreakpoint.toInt()}'
            ') use the inline tuning; sizes at or above it use the avatar '
            'tuning. They are separate designs with their own dot counts, dot '
            'sizes and speeds, not one design scaled — which is what keeps a '
            '20px orb legible.',
        code: 'const ThinkingOrb(state: OrbState.solving, size: 64)',
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            for (final OrbState state in OrbState.values)
              _OrbCell(
                state: state,
                theme: _theme,
                speed: _speed,
                paused: _paused,
                color: _color,
              ),
          ],
        ),
      );

  // ---------------------------------------------------------------- inline

  Widget _inline() => GallerySection(
        title: 'At text size',
        subtitle: 'The inline tier is tuned at 20 logical pixels, for sitting '
            'beside a line of copy.',
        code: 'ThinkingOrb(state: OrbState.breathing, size: 20)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final OrbState state in <OrbState>[
              OrbState.breathing,
              OrbState.searching,
              OrbState.connecting,
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: <Widget>[
                    ThinkingOrb(
                      state: state,
                      size: 20,
                      theme: _theme,
                      speed: _speed,
                      paused: _paused,
                      color: _color,
                      semanticLabel: '',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${kOrbSemanticLabels[state]}… this is what an orb '
                        'looks like next to body copy.',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  // ----------------------------------------------------------------- notes

  Widget _notes() => GallerySection(
        title: 'Accessibility and testing',
        subtitle: 'Each state ships a default screen-reader label from '
            'kOrbSemanticLabels. Pass semanticLabel: \'\' to hide an orb from '
            'assistive tech when a nearby label already describes it — which '
            'is exactly what LoadingIndicator.orb() does inside a button.',
        code: 'const ThinkingOrb(state: OrbState.working, paused: true) '
            '// for pumpAndSettle',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final MapEntry<OrbState, String> entry
                in kOrbSemanticLabels.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('OrbState.${entry.key.name} → "${entry.value}"'),
              ),
            const SizedBox(height: 12),
            Text(
              'An orb animates continuously, so tester.pumpAndSettle() never '
              'settles while one is mounted. Drive widget tests with '
              'tester.pump(duration), or mount the orb with paused: true.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
}

/// One state, shown at both tuned tiers with its label.
class _OrbCell extends StatelessWidget {
  const _OrbCell({
    required this.state,
    required this.theme,
    required this.speed,
    required this.paused,
    required this.color,
  });

  final OrbState state;
  final OrbTheme theme;
  final double speed;
  final bool paused;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 168,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Avatar tier.
              ThinkingOrb(
                key: Key('orb-avatar-${state.name}'),
                state: state,
                size: 64,
                theme: theme,
                speed: speed,
                paused: paused,
                color: color,
              ),
              const SizedBox(width: 20),
              // Inline tier.
              ThinkingOrb(
                key: Key('orb-inline-${state.name}'),
                state: state,
                size: 20,
                theme: theme,
                speed: speed,
                paused: paused,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.name,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            '64 · 20',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
