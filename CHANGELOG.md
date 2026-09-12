# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this
project adheres to [semantic versioning](https://semver.org/spec/v2.0.0.html).

## 1.1.0

Requires **Dart >=3.4.0 / Flutter >=3.22.0**. See the
[Migration Guide](https://github.com/itsarvinddev/loading_icon_button/blob/master/MIGRATION.md#10x--110)
— nothing else in this release is required, and no public member was removed.

### Added

- `ThinkingOrb`, a family of animated indicators for AI and agent interfaces,
  with nine `OrbState` animations (`working`, `searching`, `solving`,
  `listening`, `connecting`, `weaving`, `composing`, `breathing`, `shaping`),
  two size tiers, a shared clock, `TickerMode` awareness and a static frame
  under reduced motion. Exported alongside `OrbTheme` and `kOrbSemanticLabels`.
- `LoadingIndicator`, a sealed type with `.circular()`, `.orb()`, `.widget()`
  and `.builder()` constructors, plus `LoadingProgressStyle`
  (`indicator`, `fill`, `both`). Accepted by `LoadingButton.indicator` and by a
  new `indicator` argument on every Material loading button.
- `LoadingButtonController` and `LoadingButtonValue` for driving a button from
  outside the widget tree: `start`, `setProgress`, `success`, `error`, `reset`,
  `setEnabled`, `setActionState`, `press` and `startCooldown`.
- `LoadingButtonSizing`: `legacy` (the default, unchanged 200x50 geometry),
  `.intrinsic({constraints})`, `.expand({height})` and
  `.fixed({width, height})`.
- `LoadingButtonColors` with `.fromScheme()`, `.traffic()` and `.legacy`, and
  `LoadingButtonColorStrategy` (`legacy` by default, or `material3` to derive
  every state colour from the ambient `ColorScheme`).
- `LoadingButtonThemeData`, a `ThemeExtension`, and the `LoadingButtonTheme`
  inherited widget, for per-subtree and per-brightness defaults.
- `LoadingButton` arguments: `buttonStyle`, `sizing`, `controller`,
  `indicator`, `progress`, `progressStyle`, `colors`, `colorStrategy`,
  `enabled`, `debounce`, `cooldown`, `focusNode`, `autofocus`, `tooltip`,
  `transitionBuilder`, `onSuccess` and `onFailure(Object, StackTrace)`.
- `LoadingButtonState` is now public, exposing `press()` and `currentState` for
  use through a `GlobalKey`.
- Matching `LoadingButtonBuilder` methods for all of the above.

### Changed

- **The declared SDK floor is now Dart >=3.4.0 / Flutter >=3.22.0.** This is a
  correction, not a drop in support: the package has used
  `WidgetStatesController` (Flutter 3.22+) since 1.0.0, so the previously
  declared `flutter: ">=1.17.0"` had been fiction for several releases. Older
  SDKs got a confusing compile error inside the package instead of a clean
  `pub` resolution message; they now get the resolution message.
- `LoadingButton` no longer uses `rxdart` internally; state is a plain
  `ValueNotifier`.
- `onPressed` now runs immediately on tap. It used to wait for an awaited
  haptic round trip and a ~200 ms scale animation first.
- Haptic feedback is fired and forgotten rather than awaited, which also stops
  widget tests of a press from hanging on a test binding.
- `onStateChanged` is called only for real state changes; it no longer fires a
  spurious `ActionState.idle` when the button is first built.
- Screen readers announce a `LoadingButton` once: the duplicate
  `Semantics(button: true)` wrapper is gone, and transient state text is
  announced through a `liveRegion` label on the child instead.
- `ActionState.disabled` is now reachable, via the `enabled` argument or a
  controller.
- `ButtonStateExtension` is renamed `ActionStateExtension`, finishing the 1.0.2
  rename. Member access (`state.isLoading` and friends) is unaffected, since
  extension members resolve by member name, not by extension name; only
  explicit extension overrides need updating.
- `ActionStateExtension.isInteractive` now means "a press would be accepted"
  (`!loading && !disabled`) instead of being an exact duplicate of `isIdle`.
  Use `isIdle` for the old meaning.

### Fixed

- A throwing callback on an `*AutoLoadingButton` no longer leaves the button a
  dead spinner. `doPress` and `doLongPress` share one implementation that
  clears the loading flag on both the success and the failure path; tap-path
  errors are reported via `FlutterError.reportError`, and callers that await
  `doPress()` receive the error instead.
- A fast double tap can no longer run `LoadingButton.onPressed` twice; the
  press path is latched synchronously before the first `await`.
- The success/error reset is a cancellable `Timer` instead of an uncancellable
  `Future.delayed`, so a disposed button no longer fires a stale reset.
- `LoadingButton` reads `MediaQuery.sizeOf`, so it no longer rebuilds on every
  unrelated `MediaQuery` change.
- `ArgonButton` no longer force-unwraps a nullable `onTap` or `loader`; a null
  `onTap` renders the button disabled instead of throwing. The escaping
  `startLoading`/`stopLoading` closures and the animation callbacks are
  `mounted`-guarded.
- `ArgonTimerButton.startTimer` throws an `ArgumentError` instead of a bare
  `String`.
- `buildChildWithIC` no longer pushes its label off the end of the row when the
  icon is null, and its gap no longer adds vertical padding.

### Deprecated

All of these keep working until 2.0.0.

- `LoadingButton.onError` and `LoadingButtonBuilder.onError` — use `onFailure`,
  which also receives the `StackTrace`.
- `LoadingButtonConfig` — use `LoadingButtonThemeData` with
  `LoadingButtonTheme`, or as a `ThemeExtension` on `ThemeData`. It is still
  read as the last fallback, so existing code is unaffected.
- The top-level helpers in `icon_button.dart` — `IconButtonLoading`,
  `buildChildWithIcon`, `buildChildWithIC` and `buildText`. Compose a `Row` or
  a `Text` yourself.

## 1.0.3

### Fixed

- A widget disposed while `onPressed` was still running no longer throws; the
  success and error transitions are `mounted`-guarded
  ([#8](https://github.com/itsarvinddev/loading_icon_button/pull/8)).

## 1.0.2

### Changed

- **Breaking:** `ButtonState` is renamed `ActionState`, with no deprecated
  alias. Replace `ButtonState` with `ActionState` (leave `ArgonButtonState` and
  `LoadingButtonState` alone).

## 1.0.1

- URLs updated.

## 1.0.0

- Full refactor of the package.
- Added new material buttons.
- See the
  [Migration Guide](https://github.com/itsarvinddev/loading_icon_button/blob/master/MIGRATION.md#00x--10x)
  for details.

## 0.0.7

- Dependencies updated.

## 0.0.6

- Dependencies updated.

## 0.0.5

- Readme updated.

## 0.0.4

- New Argon buttons added, inspired by
  [argon_buttons_flutter](https://pub.dev/packages/argon_buttons_flutter).
- Dependencies updated.

## 0.0.3

- Example application android bug fixed.
- Text alignment fixed.

## 0.0.2

- Readme updated.

## 0.0.1

- Initial release.
