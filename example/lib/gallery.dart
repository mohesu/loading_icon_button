/// Small presentation helpers shared by every gallery page.
///
/// Nothing here is part of `loading_icon_button`; it is just the chrome the
/// demos sit in, kept in one place so the pages stay about the package.
library;

import 'package:flutter/material.dart';

/// Pretends to do work for [duration], then returns.
Future<void> fakeWork([
  Duration duration = const Duration(milliseconds: 1200),
]) =>
    Future<void>.delayed(duration);

/// Pretends to do work for [duration], then throws.
Future<void> fakeFailure([
  Duration duration = const Duration(milliseconds: 900),
]) async {
  await Future<void>.delayed(duration);
  throw const _DemoException('The server said no.');
}

class _DemoException implements Exception {
  const _DemoException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The body of a gallery page: a centred, scrolling column of [GallerySection]s.
class GalleryPage extends StatelessWidget {
  const GalleryPage({
    super.key,
    required this.title,
    required this.blurb,
    required this.children,
  });

  /// Page heading.
  final String title;

  /// One or two sentences under the heading.
  final String blurb;

  /// The sections, in order.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 64),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: text.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  blurb,
                  style: text.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A titled card wrapping one demo.
class GallerySection extends StatelessWidget {
  const GallerySection({
    super.key,
    required this.title,
    this.subtitle,
    this.code,
    required this.child,
  });

  /// Section heading.
  final String title;

  /// What the demo is showing, in prose.
  final String? subtitle;

  /// The one line of API this section is really about.
  final String? code;

  /// The demo itself.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (code != null) ...<Widget>[
              const SizedBox(height: 10),
              CodeLine(code!),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// One line of monospaced Dart, scrollable sideways when it is too long.
class CodeLine extends StatelessWidget {
  const CodeLine(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: const <String>['Courier'],
            fontSize: 12.5,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A run of demo widgets that wraps onto the next line when space runs out.
class DemoWrap extends StatelessWidget {
  const DemoWrap({
    super.key,
    required this.children,
    this.alignment = WrapAlignment.start,
  });

  final List<Widget> children;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
}

/// A labelled demo, for grids where the label matters as much as the widget.
class LabelledDemo extends StatelessWidget {
  const LabelledDemo({
    super.key,
    required this.label,
    required this.child,
    this.width = 180,
  });

  final String label;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      );
}

/// Shows [message] in the nearest [ScaffoldMessenger], briefly.
void showNote(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        width: 360,
        duration: const Duration(seconds: 2),
      ),
    );
}
