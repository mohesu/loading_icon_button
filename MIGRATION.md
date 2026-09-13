# Migration guide

`loading_icon_button` — how to move between major versions of this package.

The package name has always been **`loading_icon_button`**, and every public
symbol comes from a single library:

```dart
import 'package:loading_icon_button/loading_icon_button.dart';
```

> **Correction.** An earlier revision of this guide told readers to import and
> depend on `loading_button`. That is a *different*, unrelated package on
> pub.dev. If you followed it, change the dependency back to
> `loading_icon_button`. The same revision used `ButtonState` throughout; that
> enum has been called [`ActionState`](#102--buttonstate-is-now-actionstate)
> since 1.0.2.

| You are on | Read |
| --- | --- |
| 0.0.x | [0.0.x → 1.0.x](#00x--10x), then [1.0.x → 1.1.0](#10x--110) |
| 1.0.0 – 1.0.3 | [1.0.x → 1.1.0](#10x--110) |
| 1.1.0 | [What 2.0.0 will change](#what-200-will-change) |

---

## 0.0.x → 1.0.x

1.0.0 was a full rewrite of `LoadingButton` plus a large set of new widgets.
It is the only release in the package's history with wide source-breaking
changes.

### The shape of the change

In 0.0.x, `LoadingButton` was an animation shell that you drove yourself:

* `controller` was **required** — a `LoadingButtonController` that you
  constructed, held, and called `start()` / `stop()` / `success()` / `error()` /
  `reset()` on.
* `onPressed` was a plain `VoidCallback`, invoked *after* the squeeze animation
  finished, and the button had no idea whether your work succeeded. Reaching
  `success` or `error` was entirely up to your calls on the controller.
* Every visual knob was a top-level constructor argument (`primaryColor`,
  `successColor`, `borderRadius`, `elevation`, `showBox`, …).

In 1.0.x, the button owns the state machine and derives it from a future:

* There is **no `controller` argument at all** — the class
  `LoadingButtonController` was removed in 1.0.0. (A new, unrelated
  `LoadingButtonController` was introduced in
  [1.1.0](#optional-what-110-adds); it is a
  `ValueNotifier`, not the 0.0.x listener bag.)
* `onPressed` is an `AsyncCallback` (`Future<void> Function()`). The button goes
  to `loading` for the life of the future, then to `success`, or to `error` if
  it throws.
* Visual knobs moved into a single `LoadingButtonStyle`.
* The Material button family (`type: ButtonType.elevated | filled | outlined |
  text | icon`) replaced the hand-rolled `ElevatedButton` shell.

### Before / after

```dart
// 0.0.x
final controller = LoadingButtonController();

LoadingButton(
  controller: controller,
  onPressed: () async {
    controller.start();
    try {
      await submit();
      controller.success();
    } catch (_) {
      controller.error();
    }
  },
  child: const Text('Submit'),
  iconData: Icons.send,
  primaryColor: Colors.blue,
  successColor: Colors.green,
  errorColor: Colors.red,
  borderRadius: 25,
  elevation: 5,
  width: 225,
  height: 55,
)
```

```dart
// 1.0.x
LoadingButton(
  type: ButtonType.elevated,
  onPressed: () async => submit(), // throwing is how you reach `error`
  child: const Text('Submit'),
  style: const LoadingButtonStyle(
    backgroundColor: Colors.blue,
    successBackgroundColor: Colors.green,
    errorBackgroundColor: Colors.red,
    borderRadius: 25,
    elevation: 5,
  ),
  width: 225,
  height: 55,
  onError: (error) => report(error), // see the 1.1.0 deprecations table
)
```

### Argument map

| 0.0.x argument | 1.0.x equivalent |
| --- | --- |
| `controller` (required) | Removed. The future returned by `onPressed` drives the state. |
| `onPressed` (`VoidCallback`) | `onPressed` (`AsyncCallback?`) |
| `child`, `iconData` | `child` only — compose your own `Row` of an `Icon` and a `Text`. |
| `primaryColor` | `style.backgroundColor` |
| `valueColor`, `iconColor` | `style.foregroundColor` |
| `successColor` | `style.successBackgroundColor` |
| `errorColor` | `style.errorBackgroundColor` |
| `disabledColor` | `style.disabledBackgroundColor` / `style.disabledForegroundColor` |
| `shadowColor` | `style.shadowColor` |
| `borderRadius` | `style.borderRadius` |
| `elevation` | `style.elevation` |
| `width`, `height` | `width`, `height` (unchanged) |
| `duration` | `animationDuration` |
| `resetDuration` | `successDuration` and `errorDuration` (separate windows) |
| `resetAfterDuration` | `resetAfterDuration` (now defaults to `true`) |
| `successIcon`, `failedIcon` | `successWidget`, `errorWidget` (full widgets, not `IconData`) |
| `loaderSize`, `loaderStrokeWidth` | `loadingWidget` (supply your own indicator) |
| `animateOnTap`, `showBox`, `spaceBetween`, `curve`, `completionCurve`, `completionDuration` | Removed. |
| — | `loadingText`, `successText`, `errorText` (also used as accessible labels) |
| — | `onStateChanged`, `onError`, `enableHapticFeedback`, `type` |

### Also new in 1.0.0

* `ElevatedLoadingButton`, `FilledLoadingButton`, `OutlinedLoadingButton` and
  `TextLoadingButton` — Material buttons driven by an `isLoading` flag. There is
  no `IconLoadingButton`; use `IconAutoLoadingButton` for an icon button.
* `ElevatedAutoLoadingButton`, `FilledAutoLoadingButton`,
  `OutlinedAutoLoadingButton`, `TextAutoLoadingButton` and
  `IconAutoLoadingButton` — the same buttons, loading for as long as an async
  callback runs.
* `LoadingButtonBuilder` — a fluent builder over `LoadingButton`.
* `LoadingButtonConfig` — a global defaults singleton
  ([deprecated in 1.1.0](#deprecations-in-110)).
* `ButtonState` gained a `disabled` value, plus `ButtonStateExtension`
  (`isIdle`, `isLoading`, …).

`ArgonButton` and `ArgonTimerButton` were not changed in 1.0.0 beyond becoming
`part` files of the single library; their arguments are the same.

### SDK floor in 1.0.0

`sdk: ">=2.15.1 <4.0.0"` became `sdk: ">=2.17.0 <4.0.0"`. The declared
`flutter: ">=1.17.0"` was left alone — see
[the 1.1.0 SDK correction](#the-one-hard-requirement-the-sdk-floor) for why
that number was already wrong.

### 1.0.1

URLs in the README and `pubspec.yaml` only. No code change.

### 1.0.2 — `ButtonState` is now `ActionState`

The enum was renamed. **No deprecated alias was kept**, so this was a
source-breaking change shipped in a patch release. Every value keeps its name:

```dart
// 1.0.1 and earlier
onStateChanged: (ButtonState state) {
  if (state == ButtonState.loading) { /* … */ }
}

// 1.0.2 and later
onStateChanged: (ActionState state) {
  if (state == ActionState.loading) { /* … */ }
}
```

A find-and-replace of `ButtonState` → `ActionState` is sufficient, with two
exceptions that must be left alone: `ArgonButtonState` (a different enum, for
`ArgonButton`) and `LoadingButtonState` (the `State` class). In 1.0.2 the
extension was still called `ButtonStateExtension`; it is
[renamed in 1.1.0](#the-actionstate-extension-was-renamed).

### 1.0.3

A `mounted` guard so that a widget disposed while `onPressed` was still running
no longer throws (`setState`/state emission on a defunct `State`). Fix only, no
API change.

---

## 1.0.x → 1.1.0

**The only thing you are required to do is be on Dart 3.4 / Flutter 3.22 or
newer.** Everything else in this section is either optional or a behaviour
change you get for free. No public member was removed or renamed in 1.1.0,
with the single narrow exception of
[the extension rename](#the-actionstate-extension-was-renamed), and one
parameter type was narrowed:
[`ArgonTimerButton.loader`](#argontimerbuttonloader-is-typed-more-tightly).

### The one hard requirement: the SDK floor

```yaml
environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.22.0"
```

**This is a correction, not a removal of support.** The `*LoadingButton`
widgets have used `WidgetStatesController` since 1.0.0, and that API landed in
Flutter 3.22 / Dart 3.4. The `flutter: ">=1.17.0"` the package declared had
therefore been fiction for several releases: the package could not build on
anything close to that floor.

What actually changed is *how you find out*. Before 1.1.0, a project on an
older SDK resolved the package happily and then failed deep inside
`package:loading_icon_button` with `Undefined class 'WidgetStatesController'`
— an error that looks like a bug in the package. From 1.1.0 on, `pub` refuses
the resolution up front and tells you the real constraint. No configuration
that previously *worked* has stopped working.

If `pub get` now reports that `loading_icon_button` requires a newer SDK, your
project was already outside the range where this package compiled. Upgrade
Flutter to 3.22 or later, or pin `loading_icon_button: 1.0.3`.

### Deprecations in 1.1.0

Everything below still works exactly as before. Each is annotated
`@Deprecated` so the analyzer points at it, and **each keeps working until
2.0.0**, when it will be removed.

| Deprecated | Write instead | Notes |
| --- | --- | --- |
| `LoadingButton.onError` — `Function(dynamic)?` | `LoadingButton.onFailure` — `void Function(Object error, StackTrace stackTrace)?` | Both fire when `onPressed` throws, and both are called if you supply both. `onFailure` also receives the stack trace, which `onError` discarded. |
| `LoadingButtonBuilder.onError(…)` | `LoadingButtonBuilder.onFailure(…)` | Same signature change as above. |
| `LoadingButtonConfig` (the whole class) | `LoadingButtonThemeData` + `LoadingButtonTheme`, or a `ThemeExtension` on `ThemeData` | A process-wide mutable singleton cannot vary by subtree or by brightness, and its `reset()` does not rebuild anything. Still read as the **last** fallback, after widget arguments and after the theme, so existing code is unaffected. |
| `IconButtonLoading` | Compose a `Row`/`Wrap` of an `Icon` and a `Text` | Unused inside the package. |
| `buildChildWithIcon(…)` | Same — compose the row yourself | Top-level function that leaks into every importing library's namespace. |
| `buildChildWithIC(…)` | Same | As above. |
| `buildText(text, style)` | `Text(text, style: style)` | As above. |

Moving off `onError`:

```dart
// before
LoadingButton(
  onPressed: submit,
  onError: (error) => report(error),
  child: const Text('Submit'),
)

// after
LoadingButton(
  onPressed: submit,
  onFailure: (Object error, StackTrace stackTrace) => report(error, stackTrace),
  child: const Text('Submit'),
)
```

Moving off `LoadingButtonConfig`:

```dart
// before — anywhere, once, at startup
LoadingButtonConfig().defaultAnimationDuration = const Duration(milliseconds: 500);
LoadingButtonConfig().defaultSuccessDuration = const Duration(seconds: 1);
LoadingButtonConfig().enableHapticFeedback = false;

// after — as a ThemeExtension, so it resolves per brightness
MaterialApp(
  theme: ThemeData(
    extensions: const <ThemeExtension<dynamic>>[
      LoadingButtonThemeData(
        animationDuration: Duration(milliseconds: 500),
        successDuration: Duration(seconds: 1),
        enableHapticFeedback: false,
      ),
    ],
  ),
)

// …or for one subtree only
LoadingButtonTheme(
  data: const LoadingButtonThemeData(enableHapticFeedback: false),
  child: checkoutFlow,
)
```

`LoadingButtonThemeData.of(context)` resolves in this order: the nearest
`LoadingButtonTheme` widget, then the `ThemeExtension` on `ThemeData`, then an
empty instance.

### The `ActionState` extension was renamed

`ButtonStateExtension` is now `ActionStateExtension` — finishing the 1.0.2
rename. No alias is kept behind it, deliberately: a second extension declaring
the same members on the same enum would make every `state.isLoading` call site
an `ambiguous_extension_member_access` compile error in *your* code, and
`typedef ButtonStateExtension = ActionStateExtension;` is not legal Dart
(extensions are not types).

In practice this breaks nothing, because extension members resolve by member
name on the receiver's type, not by the extension's name. `state.isIdle`,
`state.isLoading`, `state.isSuccess`, `state.isError` and `state.isDisabled`
all keep compiling unchanged. Only an explicit extension override —
`ButtonStateExtension(state).isIdle` — has to be rewritten as
`ActionStateExtension(state).isIdle`.

One member changed meaning:

| Member | Before 1.1.0 | From 1.1.0 |
| --- | --- | --- |
| `isInteractive` | `state == idle` — an exact duplicate of `isIdle` | `state != loading && state != disabled`, so a button resting in `success` or `error` correctly reports as pressable |

If you relied on the old meaning, use `isIdle`, which is unchanged.

### `ArgonTimerButton.loader` is typed more tightly

This is the one signature change in 1.1.0, and it is source-breaking for a
narrow case.

| | Type |
| --- | --- |
| Up to 1.0.3 | `final Function(int time)? loader;` |
| From 1.1.0 | `final Widget Function(int time)? loader;` |

The value has always been used in a `child:` position, so the tighter type only
writes down what the widget already needed — nothing about the rendered result
changes. What does change is assignability. The old bare `Function(int time)`
placed no constraint at all on the return type, so anything compiled; the new
type requires a non-nullable `Widget`.

```dart
// Still fine — returns a Widget on every path.
loader: (int time) => Text('$time'),

// Compiled before. Now: "The returned type 'Text?' isn't returnable
// from a 'Widget' function".
loader: (int time) => time > 0 ? Text('$time') : null,

// Compiled before. Now: "The body might complete normally, causing
// 'null' to be returned, but the return type, 'Widget', is a
// potentially non-nullable type".
loader: (int time) {
  debugPrint('$time');
},

// Also affected: any torn-off function or typedef whose declared return
// type is dynamic, void, or a nullable Widget.
```

The fix is to return a non-nullable `Widget` on every path — `const
SizedBox.shrink()` for the "show nothing" case. Annotating the closure as
`Widget Function(int time)` will point the analyzer at whichever path does not.

### Behaviour changes

None of these change a signature; all of them are observable at runtime.

| What you will notice | Why it changed |
| --- | --- |
| A callback that throws on an `*AutoLoadingButton` no longer leaves the button stuck as a spinner. | `doPress`/`doLongPress` shared no code, and only the success path cleared the pending-future flag. A throwing callback left that flag set forever, so the button stayed disabled and spinning, every awaiter of `doPress()` hung, and the error surfaced as an unhandled async error. Both paths now clear it. Tap-path failures are reported through `FlutterError.reportError` with package context; if you call `doPress()` yourself, you receive the error on the returned future and can handle it normally. |
| A fast double tap on `LoadingButton` runs `onPressed` once, not twice. | The old guard read the current state, then awaited haptic feedback and a 200 ms press animation *before* moving to `loading`. Two taps inside that window both passed the guard. There is now a synchronous latch set before the first `await`. |
| `onPressed` runs immediately on tap instead of roughly 200 ms later. | The press path used to `await` the scale animation's forward and reverse legs (100 ms each) before invoking your callback. The button now enters `loading` and starts your work straight away. |
| Haptic feedback is fired and forgotten rather than awaited. | `await HapticFeedback.lightImpact()` delayed the user's callback by a platform-channel round trip — and on a test binding the channel never completes, which made any widget test of a press hang. |
| `onStateChanged` no longer fires a spurious `ActionState.idle` when the button is first built. | State used to flow through a `BehaviorSubject` seeded with `idle`, so subscribing in `initState` replayed that seed as if it were a transition. `onStateChanged` is now called only for real changes. |
| Screen readers announce the button once, not twice. | The button was wrapped in its own `Semantics(button: true, …)` node on top of the Material button's own node, producing a duplicate. The transient state text (`loadingText` / `successText` / `errorText`) now rides on the child as a `liveRegion` label instead, so state changes are announced without a second button node. |
| A disposed `LoadingButton` cancels its pending reset instead of firing it. | The success/error reset was a `Future.delayed` that could not be cancelled; it is now a `Timer` cancelled in `dispose` and re-armed on each state change. |
| `ArgonButton` with a null `onTap` renders as disabled instead of throwing. | `ArgonButton.onTap` was force-unwrapped as `widget.onTap!(…)` in the tap handler despite being nullable, so the first tap on a button without an `onTap` threw. Escaping `startLoading`/`stopLoading` closures and the timer callbacks are now `mounted`-guarded too. |
| `ArgonButton` with a null `loader` shows a default spinner instead of nothing. | The old code did **not** crash here: `loader` went straight into a `child:` position, where null is legal, so a button with no `loader` animated down to a pill and showed an empty pill for the whole busy window. A spinner is the more useful default. To keep the old empty pill, pass `loader: const SizedBox.shrink()`. |
| `ArgonTimerButton` with a null `loader` shows a default spinner instead of throwing. | This is the one that crashed: the countdown builder called `widget.loader!(secondsLeft)`, so any `ArgonTimerButton` without a `loader` threw as soon as the timer started. |
| `ArgonTimerButton.startTimer` throws `ArgumentError` on a bad timer value. | It used to `throw` a bare `String`, which cannot be caught as an `Exception` and prints poorly. |

If a widget test of yours asserted any of the old behaviours — a double-fired
`onPressed`, the leading `idle` callback, two semantics button nodes — it will
need updating. That is the full list of test-visible changes.

### Optional: what 1.1.0 adds

Nothing here is required; the defaults are unchanged from 1.0.x.

* **`LoadingButtonController`** — a `ValueNotifier<LoadingButtonValue>` with
  `start` / `setProgress` / `success` / `error` / `reset` / `setEnabled` /
  `setActionState` / `press` / `startCooldown`. Pass it as
  `LoadingButton.controller` to drive the button from outside the tree.
* **`LoadingButtonSizing`** — `.legacy` (the default: the old fixed 200×50 box,
  widened to 240 above 600 logical pixels), `.intrinsic({constraints})`,
  `.expand({height})`, `.fixed({width, height})`.
* **`LoadingIndicator`** — `.circular()`, `.orb()`, `.widget()`, `.builder()`,
  accepted by `LoadingButton.indicator` and by the `indicator` argument now on
  the Material loading buttons.
* **`ThinkingOrb`** — nine animated `OrbState` indicators (`working`,
  `searching`, `solving`, `listening`, `connecting`, `weaving`, `composing`,
  `breathing`, `shaping`), reduced-motion aware.
* **Determinate progress** — `LoadingButton.progress` (0.0–1.0) with
  `LoadingProgressStyle.indicator | fill | both`.
* **`LoadingButtonColors` / `LoadingButtonColorStrategy`** — keep `.legacy`
  colours or opt into `.material3`, which derives everything from the ambient
  `ColorScheme` and is safe in dark mode.
* **Press control** — `enabled`, `debounce`, `cooldown`.
* **Passthroughs** — `buttonStyle` (a plain Material `ButtonStyle`),
  `focusNode`, `autofocus`, `tooltip`, `transitionBuilder`, `onSuccess`.

```dart
LoadingButton(
  onPressed: () async => upload(),
  child: const Text('Upload'),
  sizing: const LoadingButtonSizing.intrinsic(),
  colorStrategy: LoadingButtonColorStrategy.material3,
  indicator: const LoadingIndicator.orb(state: OrbState.working),
  debounce: const Duration(milliseconds: 300),
  onFailure: (Object error, StackTrace stack) => report(error, stack),
)
```

---

## What 2.0.0 will change

Announced now so you can adopt the new defaults early and upgrade without a
diff. Nothing below is in effect in 1.1.0.

| Change | How to adopt it today | How to keep the old behaviour in 2.0.0 |
| --- | --- | --- |
| `LoadingButton.sizing` defaults to `LoadingButtonSizing.intrinsic()` instead of `.legacy`, and `.legacy` is removed. | Pass `sizing: const LoadingButtonSizing.intrinsic()`, or set `sizing` on your `LoadingButtonThemeData`. | Pass an explicit `LoadingButtonSizing.fixed(width: 200, height: 50)` (the legacy tablet widening will not be reproducible). |
| `LoadingButton.colorStrategy` defaults to `LoadingButtonColorStrategy.material3` instead of `.legacy`. | Pass `colorStrategy: LoadingButtonColorStrategy.material3`, or set it on the theme. | Pass `colorStrategy: LoadingButtonColorStrategy.legacy`, or supply explicit `colors`. |
| Every member deprecated in 1.1.0 is removed. | Work through [the deprecations table](#deprecations-in-110); the analyzer lists them all. | Not available — migrate before upgrading. |

Both default flips are visual, not source-breaking: buttons will size to their
content rather than to a fixed 200×50 box, and state colours will come from
your `ColorScheme` rather than from `primaryColor` plus hardcoded green and
red.

---

## Getting help

* [API documentation](https://pub.dev/documentation/loading_icon_button/latest/)
* [Example app](https://github.com/itsarvinddev/loading_icon_button/tree/master/example)
* [Issue tracker](https://github.com/itsarvinddev/loading_icon_button/issues)
