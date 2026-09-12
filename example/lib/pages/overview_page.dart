import 'package:flutter/material.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

import '../gallery.dart';

/// The landing page: what the package ships, with one live sample of each
/// family and a jump to its full page.
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.onNavigate});

  /// Switches the shell to the destination at this index.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return GalleryPage(
      title: 'loading_icon_button',
      blurb: 'Four button families with a built-in busy state, plus nine '
          'animated thinking orbs. Everything below is live — press it.',
      children: <Widget>[
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                const ThinkingOrb(state: OrbState.breathing, size: 56),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'One busy state, four ways to drive it',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Drive it from an async callback, from a plain bool, '
                        'or from a controller you hold yourself.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _FamilyCard(
          title: 'LoadingButton',
          description: 'A full idle → loading → success/error state machine in '
              'one widget, in any of the five Material button shapes.',
          code: "LoadingButton(onPressed: submit, child: Text('Submit'))",
          onOpen: () => onNavigate(1),
          demo: LoadingButton(
            type: ButtonType.filled,
            onPressed: fakeWork,
            successText: 'Saved',
            child: const Text('Save changes'),
          ),
        ),
        _FamilyCard(
          title: 'Auto-loading buttons',
          description: 'Thin wrappers over the Material buttons that stay busy '
              'for exactly as long as their async callback runs. Their '
              'flag-driven twins take an isLoading bool instead.',
          code: 'ElevatedAutoLoadingButton(onPressed: () async { ... })',
          onOpen: () => onNavigate(2),
          demo: DemoWrap(
            children: <Widget>[
              ElevatedAutoLoadingButton(
                onPressed: fakeWork,
                child: const Text('Elevated'),
              ),
              FilledAutoLoadingButton.tonalIcon(
                onPressed: fakeWork,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Tonal'),
              ),
              IconAutoLoadingButton.filled(
                onPressed: fakeWork,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        _FamilyCard(
          title: 'Argon buttons',
          description: 'A button that collapses into its own loader, and a '
              'countdown variant for "resend in 30s" affordances.',
          code: 'ArgonButton(height: 48, width: 200, onTap: ...)',
          onOpen: () => onNavigate(3),
          demo: ArgonButton(
            height: 48,
            width: 200,
            minWidth: 48,
            borderRadius: 24,
            color: scheme.primary,
            loader: const Padding(
              padding: EdgeInsets.all(10),
              child: ThinkingOrb(state: OrbState.working, size: 28),
            ),
            onTap: (Function startLoading, Function stopLoading,
                ArgonButtonState state) async {
              if (state != ArgonButtonState.idle) return;
              startLoading();
              await fakeWork();
              stopLoading();
            },
            child: Text(
              'Collapse me',
              style: TextStyle(color: scheme.onPrimary),
            ),
          ),
        ),
        _FamilyCard(
          title: 'Thinking orbs',
          description: 'Nine hand-tuned dotted-sphere animations for AI and '
              'agent interfaces, each with a separate tuning for inline and '
              'avatar sizes. No shaders, no assets, one CustomPainter.',
          code: 'ThinkingOrb(state: OrbState.searching, size: 64)',
          onOpen: () => onNavigate(4),
          demo: const DemoWrap(
            children: <Widget>[
              ThinkingOrb(state: OrbState.working, size: 48),
              ThinkingOrb(state: OrbState.searching, size: 48),
              ThinkingOrb(state: OrbState.connecting, size: 48),
              ThinkingOrb(state: OrbState.shaping, size: 48),
              ThinkingOrb(state: OrbState.listening, size: 48),
            ],
          ),
        ),
        GallerySection(
          title: 'Indicators are interchangeable',
          subtitle: 'Every family accepts the same LoadingIndicator, so '
              'swapping an app from spinners to orbs is one line in a theme.',
          code: 'LoadingButtonTheme(data: LoadingButtonThemeData('
              'indicator: LoadingIndicator.orb()), child: app)',
          child: DemoWrap(
            children: <Widget>[
              LoadingButton(
                onPressed: fakeWork,
                indicator: const LoadingIndicator.circular(),
                child: const Text('Spinner'),
              ),
              LoadingButton(
                type: ButtonType.filled,
                onPressed: fakeWork,
                indicator: const LoadingIndicator.orb(
                  state: OrbState.weaving,
                  size: 22,
                ),
                child: const Text('Orb'),
              ),
              ElevatedAutoLoadingButton(
                onPressed: fakeWork,
                indicator: const LoadingIndicator.orb(
                  state: OrbState.solving,
                  size: 22,
                ),
                child: const Text('Orb, auto'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.title,
    required this.description,
    required this.code,
    required this.demo,
    required this.onOpen,
  });

  final String title;
  final String description;
  final String code;
  final Widget demo;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: title,
      subtitle: description,
      code: code,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          demo,
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('See every option'),
            ),
          ),
        ],
      ),
    );
  }
}
