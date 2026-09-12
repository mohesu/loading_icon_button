# loading_icon_button gallery

A multi-page Material 3 gallery for every public widget in
[`loading_icon_button`](../), in light and dark.

| Page              | What it covers                                                                                                                                 |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **Overview**      | One live sample of each family, and how to swap spinners for orbs globally.                                                                      |
| **LoadingButton** | All five `ButtonType`s, success/failure, `LoadingButtonController`, determinate progress, `LoadingButtonSizing`, `LoadingButtonColors`/`LoadingButtonColorStrategy`, `buttonStyle` vs `LoadingButtonStyle`, `LoadingIndicator`, debounce/cooldown/enabled, `LoadingButtonBuilder`, and `LoadingButtonTheme`. |
| **Auto-loading**  | `ElevatedAutoLoadingButton` and friends (including `.icon`, `.tonal`, `.tonalIcon` and all four `IconAutoLoadingButton` variants), `AutoLoadingButtonState.doPress()`, and the flag-driven `XxxLoadingButton` twins. |
| **Argon**         | `ArgonButton` and `ArgonTimerButton`: collapse shape, easing, custom loaders, countdowns.                                                         |
| **Thinking orbs** | All nine `OrbState`s at both tuned size tiers, with theme, tint, speed and pause controls.                                                        |

Deprecated API (`LoadingButtonConfig`, `IconButtonLoading`, `buildChildWithIcon`,
`buildChildWithIC`, `buildText`, `LoadingButton.onError`) is deliberately absent —
the gallery only shows what you should reach for in new code.

## Running it

```sh
cd example
flutter create . --platforms=macos        # or android,ios,web,linux,windows
flutter run
```

The first step is only needed once per checkout, and only for the platforms you
actually want. See "Platform folders" below for why it isn't done for you.

Everything else works without it:

```sh
flutter pub get
flutter analyze
flutter test
```

## Platform folders

`android/`, `ios/`, `linux/`, `macos/`, `web/` and `windows/` are **not** checked
in, and are listed in `.gitignore`. Three reasons:

1. They were stale. The committed runners were generated years before the
   current Flutter version and had drifted from what `flutter create` produces.
2. They were incomplete. Only four of the package's six supported platforms had
   a runner at all.
3. `windows/flutter/generated_plugins.cmake` is a **generated** file that
   `flutter pub get` rewrites. Keeping it in git meant every `pub get` dirtied
   the working tree, which made `flutter pub publish` refuse to package a clean
   tree.

Nothing about the gallery is platform-specific — no plugins, no native code, no
third-party dependencies at all — so `flutter create .` regenerates a correct,
current runner for whichever platforms you want in a couple of seconds. It also
rewrites `.metadata` to add a `migration:` section for the platforms you asked
for; that edit is local scaffolding bookkeeping, so `git checkout -- .metadata`
before you commit anything else.

CI does exactly this — see the `example` job in
[`.github/workflows/ci.yaml`](../.github/workflows/ci.yaml), which runs
`flutter create . --platforms=web` and then `flutter build web --release` on
every push.

## Dependencies

Only `loading_icon_button` itself, via a path dependency, plus `flutter_lints`
for analysis. No `google_fonts`, no `phosphor_flutter`: the gallery uses Material
icons and the platform's default type ramp, so `flutter pub get` here pulls
nothing from the network beyond the SDK's own packages.

## Layout

```
lib/
  main.dart              app shell: themes, the light/dark toggle, navigation
  gallery.dart           page/section chrome shared by the demos
  pages/
    overview_page.dart
    loading_button_page.dart
    auto_loading_page.dart
    argon_page.dart
    orbs_page.dart
test/
  widget_test.dart       drives the real app: navigation, theming, each family
```

## A note on tests

A `ThinkingOrb` animates continuously, and the gallery mounts orbs on four of
its five pages, so `tester.pumpAndSettle()` will never return. `widget_test.dart`
drives time with explicit `tester.pump(duration)` calls instead — the same
advice the package gives its own users. Mounting an orb with `paused: true` is
the other way out.
