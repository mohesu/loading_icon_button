# loading_icon_button

[![pub package](https://img.shields.io/pub/v/loading_icon_button.svg)](https://pub.dev/packages/loading_icon_button)
[![GitHub Stars](https://img.shields.io/github/stars/itsarvinddev/loading_icon_button.svg?style=social&label=Star)](https://github.com/itsarvinddev/loading_icon_button)
[![GitHub Issues](https://img.shields.io/github/issues/itsarvinddev/loading_icon_button.svg)](https://github.com/itsarvinddev/loading_icon_button/issues)
[![GitHub License](https://img.shields.io/github/license/itsarvinddev/loading_icon_button.svg)](https://github.com/itsarvinddev/loading_icon_button/blob/master/LICENSE)
[![X](https://img.shields.io/badge/X-Follow-blue)](https://x.com/itsarvinddev)

<img src="https://github.com/itsarvinddev/loading_icon_button/blob/master/doc/hero.webp?raw=true" width="760" alt="Three loading buttons animating at once: a spinner labelled Signing in, a thinking orb labelled Searching, and a determinate Uploading button with a progress fill — all three then flip to a green success state, with the nine orb animations running underneath" />

<sub>Left to right: a spinner, a `ThinkingOrb` indicator, and determinate progress shown as a
background fill — each running, then succeeding. Underneath, all nine orb states.</sub>

Loading buttons for Flutter with a real state machine: idle, loading, success, error, disabled.
Drive one from a callback, from a plain `bool`, or from a `LoadingButtonController` anywhere in your
app. Every button can wear a **`ThinkingOrb`** — one of nine hand-tuned animated indicators built
for AI and agent interfaces — instead of a spinner. Pure Dart, zero dependencies, every Flutter
platform.

## Contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Which button?](#which-button)
- [LoadingButton](#loadingbutton)
- [Thinking orbs](#thinking-orbs)
- [The AutoLoadingButton family](#the-autoloadingbutton-family)
- [The XxxLoadingButton family](#the-xxxloadingbutton-family)
- [ArgonButton and ArgonTimerButton](#argonbutton-and-argontimerbutton)
- [Accessibility](#accessibility)
- [Testing](#testing)
- [Platform support](#platform-support)
- [Deprecations](#deprecations)
- [LLM and AI assistant support](#llm-and-ai-assistant-support)
- [Attribution](#attribution)
- [Contributing](#contributing)
- [License and issues](#license-and-issues)

## Installation

```yaml
dependencies:
  loading_icon_button: ^1.1.0
```

```dart
import 'package:loading_icon_button/loading_icon_button.dart';
```

One import gives you everything. Requires Dart `>=3.4.0` and Flutter `>=3.22.0`.

## Quick start

```dart
LoadingButton(
  onPressed: () async => submit(),
  onSuccess: () => debugPrint('done'),
  onFailure: (Object error, StackTrace stack) => report(error, stack),
  child: const Text('Submit'),
)
```

The button runs `onPressed`, shows an indicator until the returned future settles, flashes success
or error, then returns to idle. `onPressed` is an `AsyncCallback` — it must be `() async { … }`.

## Which button?

Four families, distinguished by **who owns the loading state**. Pick a row:

| Family                                                                  | Loading state owned by                     | Success / error phases | Reach for it when                                       |
| ----------------------------------------------------------------------- | ------------------------------------------ | ---------------------- | ------------------------------------------------------- |
| [`LoadingButton`](#loadingbutton)                                       | The widget, or a `LoadingButtonController` | Yes                    | You want the full idle → loading → success/error cycle   |
| [`XxxAutoLoadingButton`](#the-autoloadingbutton-family)                 | The widget, while the future runs          | No                     | You want a stock Material button that spins while busy   |
| [`XxxLoadingButton`](#the-xxxloadingbutton-family)                      | **You**, via an `isLoading` flag           | No                     | The state already lives in your bloc/provider/notifier   |
| [`ArgonButton` / `ArgonTimerButton`](#argonbutton-and-argontimerbutton) | You, via callbacks                         | No                     | You want the collapse-into-a-pill look, or a countdown   |

<img src="https://github.com/itsarvinddev/loading_icon_button/blob/master/doc/families.png?raw=true" width="760" alt="Five labelled rows, each naming a widget and showing it rendered: LoadingButton as a Submit order button, ElevatedAutoLoadingButton as an Upload button with a cloud icon, FilledAutoLoadingButton.tonal as a Sync now button, IconAutoLoadingButton.filled as a round heart button, and ArgonButton as a wide Continue pill" />

<sub>One labelled row per widget, at rest. `ArgonButton` is the odd one out: it animates its own
width down to a pill, while the rest render standard Material buttons.</sub>

The first three families share the same [`LoadingIndicator`](#indicators) type (orbs included) and
take their defaults from the same [`LoadingButtonTheme`](#theming). `ArgonButton` is standalone: it
takes a plain `loader` widget and reads neither.

## LoadingButton

The widget for the full cycle. It owns a five-state machine and renders one of the five Material
button types for it.

### The state machine

`ActionState` has five values:

```
idle ──press──▶ loading ──┬─▶ success ──┐
                          └─▶ error   ──┴─▶ idle   (after successDuration / errorDuration)

disabled  ◀── enabled: false, controller.setEnabled(false), or an active cooldown
```

<img src="https://github.com/itsarvinddev/loading_icon_button/blob/master/doc/button-states-light.png?raw=true" width="760" alt="A four-by-four matrix in the light theme: elevated, filled, outlined and text buttons, each in its idle, loading, success and error state" />

<sub>The `elevated`, `filled`, `outlined` and `text` button types in every state, light theme
(`ButtonType.icon` is an `IconButton`, so it is not in the grid). The lavender loading container and
the green/red terminal states are a `LoadingButtonColors` layered over
`LoadingButtonColorStrategy.material3` — see [Colours](#colours).</sub>

<img src="https://github.com/itsarvinddev/loading_icon_button/blob/master/doc/button-states-dark.png?raw=true" width="760" alt="The same four-by-four matrix of button types and states, rendered in the dark theme" />

<sub>The same matrix in dark. State colours come from the ambient `ColorScheme`, so contrast holds in
both brightnesses.</sub>

```dart
LoadingButton(
  onPressed: () async => submit(),
  successText: 'Saved',
  errorText: 'Could not save',
  resetAfterDuration: true,
  onStateChanged: (ActionState state) => debugPrint(state.name),
  child: const Text('Save'),
)
```

Rules worth knowing:

- A press is accepted **only** from `idle`, and a synchronous latch closes before the first `await`,
  so a double tap cannot run `onPressed` twice.
- If `onPressed` throws, the button goes to `error` and calls `onFailure(error, stack)`. If neither
  `onFailure` nor the deprecated `onError` is set, the error is forwarded to
  `FlutterError.reportError` rather than swallowed.
- `resetAfterDuration: false` parks the button in its terminal state. A parked button is not
  pressable; `controller.reset()` is the only way out.
- `onStateChanged` fires on every transition except the initial `idle`.

`ActionState` carries the predicates `isIdle`, `isLoading`, `isSuccess`, `isError`, `isDisabled` and
`isInteractive` (every state except `loading` and `disabled`). `LoadingButton` is stricter than
`isInteractive`: it accepts a press only from `idle`, and renders disabled while it rests in
`success` or `error`. For "is this tappable right now", use `isIdle`.

### LoadingButtonController

`LoadingButtonController` is a `ValueNotifier<LoadingButtonValue>`, so one object drives the button
and renders the rest of your UI. No `GlobalKey` required.

```dart
final LoadingButtonController controller = LoadingButtonController();

LoadingButton(
  controller: controller,
  onPressed: _upload,
  progressStyle: LoadingProgressStyle.both,
  child: const Text('Upload'),
);

ValueListenableBuilder<LoadingButtonValue>(
  valueListenable: controller,
  builder: (BuildContext context, LoadingButtonValue value, _) => Text(
    value.isDeterminate ? '${(value.progress! * 100).round()}%' : value.state.name,
  ),
);

// from anywhere
controller.setProgress(0.4);
```

| Command                             | Effect                                                              |
| ----------------------------------- | ------------------------------------------------------------------- |
| `start({progress})`                 | Move to `loading`, optionally determinate                           |
| `setProgress(double?)`              | Report `0.0..1.0`; `null` restores the indeterminate indicator      |
| `success()`                         | Move to `success`                                                   |
| `error([error, stackTrace])`        | Move to `error`, recording both                                     |
| `reset()`                           | Back to `idle`, clearing progress and the last error                |
| `setEnabled(bool)`                  | Toggle `disabled` (a no-op mid-run)                                 |
| `setActionState(state, {progress})` | Escape hatch for states the named commands don't cover              |
| `press()`                           | Run every attached button's `onPressed`, honouring each press latch |
| `startCooldown(Duration)`           | Hold `disabled` for a window, then return to `idle`                 |

Readable state: `state`, `progress`, `lastError`, `lastStackTrace`, `isCoolingDown`,
`cooldownRemaining`, `isAttached`, `attachmentCount`.

`LoadingButtonValue` bundles `state`, `progress`, `error` and `stackTrace` into one immutable value,
so a listener can never observe an `error` paired with stale progress.

One controller may drive several buttons at once; they all mirror the same value. Because they share
it, `press()` starts exactly one run rather than one per button: the first button to accept the press
moves the shared value to `loading`, and the rest decline. Attach one button per controller when that
matters. Dispose it like any `ChangeNotifier`.

### Sizing

**The default is still the legacy geometry**: a fixed **200 × 50** box, silently widened to
**240 × 50** when the window is wider than 600 logical pixels. That is what every release before
1.1.0 did, and it stays the default so upgrading moves nothing.

It is almost never what you want. Opt into content sizing:

```dart
LoadingButton(
  onPressed: () async => submit(),
  sizing: const LoadingButtonSizing.intrinsic(),
  child: const Text('Sizes to its content'),
)
```

| Sizing                                         | Behaviour                                                                 |
| ---------------------------------------------- | ------------------------------------------------------------------------- |
| `LoadingButtonSizing.legacy` *(default)*       | Fixed 200×50; 240×50 above a 600px-wide window                            |
| `LoadingButtonSizing.intrinsic({constraints})` | Sizes to content like a normal `ElevatedButton`, animating between states |
| `LoadingButtonSizing.expand({height})`         | Fills the parent's width                                                  |
| `LoadingButtonSizing.fixed({width, height})`   | Exactly this size; a null dimension is left to content                    |

The explicit `width` / `height` parameters still win over whatever `sizing` computes. Set it once for
a whole app through [the theme](#theming).

> 2.0.0 will make `intrinsic` the default and remove `legacy`.

### Colours

Two strategies:

| `LoadingButtonColorStrategy` | Behaviour                                                                                                                                                                              |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `legacy` *(default)*         | `Theme.of(context).primaryColor` background, unconditional white foreground, hardcoded green/red. Not dark-mode safe, and it paints a filled background onto text and outlined buttons. |
| `material3`                  | Colours come from the ambient `ColorScheme`; container/on-container role pairs guarantee contrast in both brightnesses, and the idle state is left to your own `ButtonStyle`.            |

```dart
LoadingButton(
  onPressed: () async => submit(),
  colorStrategy: LoadingButtonColorStrategy.material3,
  child: const Text('Scheme colours'),
)
```

`LoadingButtonColors` overrides individual states. A `null` field means "leave this state to the
button's own `ButtonStyle`".

```dart
LoadingButtonColors.fromScheme(Theme.of(context).colorScheme); // M3 role pairs
LoadingButtonColors.traffic(Theme.of(context).brightness);     // tone-mapped green/red
LoadingButtonColors.legacy;                                    // exactly the old colours

const LoadingButtonColors(
  loading: Color(0xFF303F9F),
  onLoading: Colors.white,
  success: Color(0xFF1B5E20),
  onSuccess: Colors.white,
  error: Color(0xFFB3261E),
  onError: Colors.white,
);
```

> 2.0.0 will default to `material3`.

For geometry, elevation, padding and text style there are two layers: a standard Material
`buttonStyle`, applied first, and then the package-specific `style` (`LoadingButtonStyle`) plus the
state colours on top.

```dart
LoadingButton(
  type: ButtonType.filled,
  onPressed: () async => submit(),
  buttonStyle: FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  ),
  style: const LoadingButtonStyle(borderRadius: 24, elevation: 2),
  child: const Text('Styled'),
)
```

### Theming

`LoadingButtonThemeData` supplies defaults for every loading button beneath it. Its `indicator`
reaches all three Material families, not just `LoadingButton`; the rest of the fields are
`LoadingButton`'s. (`ArgonButton` reads none of it.)

```dart
const LoadingButtonThemeData(
  indicator: LoadingIndicator.orb(state: OrbState.working),
  sizing: LoadingButtonSizing.intrinsic(),
  colorStrategy: LoadingButtonColorStrategy.material3,
  successWidget: Icon(Icons.check_rounded),
  errorWidget: Icon(Icons.error_outline_rounded),
  animationDuration: Duration(milliseconds: 250),
  successDuration: Duration(seconds: 2),
  errorDuration: Duration(seconds: 3),
  enableHapticFeedback: true,
  progressStyle: LoadingProgressStyle.fill,
  debounce: Duration(milliseconds: 400),
  cooldown: Duration(seconds: 1),
)
```

Install it as a `ThemeExtension` on your `ThemeData` — resolved per brightness, and lerped across
theme animations — or with a `LoadingButtonTheme` widget around a subtree.

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const <ThemeExtension<dynamic>>[
      LoadingButtonThemeData(sizing: LoadingButtonSizing.intrinsic()),
    ],
  ),
  home: const HomePage(),
)
```

Resolution order, highest first:

1. The widget's own arguments
2. The ambient `LoadingButtonThemeData`
3. The deprecated `LoadingButtonConfig` singleton
4. Package defaults

That ambient data is the nearest `LoadingButtonTheme` widget if there is one, and otherwise the
`ThemeData` extension. The two are **not** merged — a `LoadingButtonTheme` widget replaces the
extension wholesale for its subtree, so put every field you still want into it.

Read it back with `LoadingButtonThemeData.of(context)`, or `LoadingButtonTheme.maybeOf(context)` for
just the widget-level one.

> `LoadingButtonConfig` — the process-wide singleton from earlier releases — is deprecated but still
> honoured. It cannot vary by subtree or by brightness, its `reset()` cannot reach already-built
> widgets, and its default widgets hardcode white. Move those values into a
> `LoadingButtonThemeData`.

### Determinate progress

Pass `progress` in `0.0..1.0` (or `null` for indeterminate) and choose how it is shown:

| `LoadingProgressStyle`  | Rendering                                                        |
| ----------------------- | ---------------------------------------------------------------- |
| `indicator` *(default)* | The loading indicator becomes determinate                        |
| `fill`                  | The background fills left to right, clipped to the button's shape |
| `both`                  | Both at once                                                     |

```dart
LoadingButton(
  progress: _progress,
  progressStyle: LoadingProgressStyle.fill,
  onPressed: () async {
    for (int i = 0; i <= 100; i += 10) {
      if (!mounted) return;
      setState(() => _progress = i / 100);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  },
  child: const Text('Upload'),
)
```

When a `controller` is attached, `controller.progress` wins over the `progress` argument. Orbs are
indeterminate by design, so with `LoadingIndicator.orb()` prefer `LoadingProgressStyle.fill`.

### Indicators

```dart
const LoadingIndicator.circular(size: 20, strokeWidth: 2, color: Colors.white);
const LoadingIndicator.orb(state: OrbState.listening, size: 22, speed: 1.2);
const LoadingIndicator.widget(Icon(Icons.hourglass_top));
LoadingIndicator.builder(
  (BuildContext context, double? progress) =>
      Text(progress == null ? '…' : '${(progress * 100).round()}%'),
);
```

On `LoadingButton` the widget shown while loading is resolved in this order:

`loadingWidget` → `loadingText` → `indicator` → the theme's indicator → the package default (a
`CircularProgressIndicator`).

Note the second entry: **`loadingText` replaces the indicator rather than labelling it.** A
`LoadingButton` given a `loadingText` shows that text alone — no spinner, no orb — so setting both
`loadingText` and `indicator` renders only the text. The same shape applies to
`successWidget`/`successText` and `errorWidget`/`errorText`. To show an indicator *and* a caption,
build the pair yourself and pass it as `loadingWidget`:

```dart
LoadingButton(
  onPressed: () async => submit(),
  loadingWidget: const Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      SizedBox(width: 8),
      Text('Submitting…'),
    ],
  ),
  child: const Text('Submit'),
)
```

### Presses: debounce, cooldown, enabling and focus

```dart
LoadingButton(
  onPressed: () async => resend(),
  debounce: const Duration(milliseconds: 500),
  cooldown: const Duration(seconds: 30),
  enabled: _formValid,
  tooltip: _formValid ? null : 'Fill in every field first',
  focusNode: _focusNode,
  autofocus: true,
  child: const Text('Resend code'),
)
```

- `debounce` ignores a tap arriving within that window of the previously **accepted** tap.
- `cooldown` holds the button `disabled` for that long after a run finishes and its success/error
  window has elapsed, then returns it to `idle`. `controller.isCoolingDown` and
  `controller.cooldownRemaining` let you render a countdown. Cooldown rides on the reset timer, so it
  does nothing when `resetAfterDuration: false` — drive the wait with
  `controller.startCooldown(duration)` instead.
- `enabled: false` puts the button in `ActionState.disabled`, which is also reachable via
  `controller.setEnabled(false)`.

### Custom transitions

The default is a cross fade over `animationDuration`. Replace it wholesale:

```dart
LoadingButton(
  onPressed: () async => submit(),
  transitionBuilder: (Widget child, Animation<double> animation) =>
      ScaleTransition(scale: animation, child: child),
  child: const Text('Scales between states'),
)
```

### Reaching the state directly

A `LoadingButtonController` is usually the better tool, but `LoadingButtonState` is public:

```dart
final GlobalKey<LoadingButtonState> key = GlobalKey<LoadingButtonState>();

LoadingButton(key: key, onPressed: () async => submit(), child: const Text('Submit'));

// elsewhere
if (key.currentState!.currentState.isIdle) {
  await key.currentState!.press();
}
```

### Fluent builder

```dart
LoadingButtonBuilder.filled()
    .onPressed(() async => submit())
    .child(const Text('Submit'))
    .indicator(const LoadingIndicator.orb(state: OrbState.working))
    .sizing(const LoadingButtonSizing.intrinsic())
    .colorStrategy(LoadingButtonColorStrategy.material3)
    .successText('Submitted')
    .onFailure((Object error, StackTrace stack) => report(error, stack))
    .build()
```

Factories: `.elevated()`, `.filled()`, `.outlined()`, `.text()`, `.icon()`.

A builder is **mutable and single-use**. Create one, configure it, build once. Two consequences of
that mutability:

- A setter called *after* `build()` does not affect the widget that was already built — `build()`
  snapshots the configuration, so late changes are silently lost.
- If you called `.key(…)`, building twice returns two different widgets carrying that same key, which
  is an error if both are mounted at once. With no `.key(…)` call both widgets get a null key and
  mounting both is legal.

### LoadingButton properties

| Property               | Type                                                        | Default              |
| ---------------------- | ----------------------------------------------------------- | -------------------- |
| `child`                | `Widget?`                                                   | `null`               |
| `onPressed`            | `AsyncCallback?`                                            | `null`               |
| `type`                 | `ButtonType`                                                | `elevated`           |
| `loadingWidget`        | `Widget?`                                                   | `null`               |
| `successWidget`        | `Widget?`                                                   | `null`               |
| `errorWidget`          | `Widget?`                                                   | `null`               |
| `loadingText`          | `String?` — **replaces** the indicator, see †               | `null`               |
| `successText`          | `String?` — **replaces** `successWidget`'s slot, see †      | `null`               |
| `errorText`            | `String?` — **replaces** `errorWidget`'s slot, see †        | `null`               |
| `indicator`            | `LoadingIndicator?`                                         | theme, then circular |
| `progress`             | `double?`                                                   | `null`               |
| `progressStyle`        | `LoadingProgressStyle?`                                     | `indicator`          |
| `controller`           | `LoadingButtonController?`                                  | `null`               |
| `sizing`               | `LoadingButtonSizing?`                                      | `legacy`             |
| `width` / `height`     | `double?`                                                   | `null`               |
| `style`                | `LoadingButtonStyle?`                                       | `null`               |
| `buttonStyle`          | `ButtonStyle?`                                              | `null`               |
| `colors`               | `LoadingButtonColors?`                                      | from the strategy    |
| `colorStrategy`        | `LoadingButtonColorStrategy?`                               | `legacy`             |
| `animationDuration`    | `Duration?`                                                 | `300ms`              |
| `successDuration`      | `Duration?`                                                 | `2s`                 |
| `errorDuration`        | `Duration?`                                                 | `2s`                 |
| `resetAfterDuration`   | `bool`                                                      | `true`               |
| `enabled`              | `bool`                                                      | `true`               |
| `debounce`             | `Duration?`                                                 | none                 |
| `cooldown`             | `Duration?`                                                 | none                 |
| `enableHapticFeedback` | `bool?`                                                     | `true`               |
| `focusNode`            | `FocusNode?`                                                | `null`               |
| `autofocus`            | `bool`                                                      | `false`              |
| `tooltip`              | `String?`                                                   | `null`               |
| `transitionBuilder`    | `Widget Function(Widget, Animation<double>)?`               | cross fade           |
| `onSuccess`            | `VoidCallback?`                                             | `null`               |
| `onFailure`            | `void Function(Object, StackTrace)?`                        | `null`               |
| `onStateChanged`       | `void Function(ActionState)?`                               | `null`               |
| `onError`              | `void Function(dynamic)?` — **deprecated**, use `onFailure` | `null`               |

† Each of `loadingText` / `successText` / `errorText` **replaces** the widget for that state rather
than captioning it, and doubles as the state's accessible label. See
[Indicators](#indicators) for the full resolution order and how to show both.

`ButtonType` is `elevated`, `filled`, `outlined`, `text` or `icon`.

## Thinking orbs

`ThinkingOrb` is an animated indicator for AI and agent interfaces: filled circles over a rotated,
z-sorted 3D point field, redrawn every frame by one `CustomPainter`. No shaders, no blurs, no image
assets. It is a Dart port of the [thinking-orbs](#attribution) engine, and each state is a separate
hand-tuned design rather than a variation on one loop.

```dart
const ThinkingOrb(state: OrbState.searching, size: 64)
```

<img src="https://github.com/itsarvinddev/loading_icon_button/blob/master/doc/orbs.webp?raw=true" width="720" alt="All nine thinking-orb states animating side by side at size 64" />

<sub>All nine states animating at `size: 64`, in the order of the table below. Every mounted orb reads
the same clock, which is why they stay in step.</sub>

### The nine states

| `OrbState`   | What it depicts                                              | Default label |
| ------------ | ------------------------------------------------------------ | ------------- |
| `working`    | Particles running on tilted orbits                           | Working       |
| `searching`  | A scan meridian sweeping a dotted globe                      | Searching     |
| `solving`    | Bands scrambling in quarter turns, then clicking back solved | Solving       |
| `listening`  | A waveform rolling through the latitude rings                | Listening     |
| `connecting` | A constellation wiring itself, packets running the edges      | Connecting    |
| `weaving`    | Three strands plaiting around the sphere                     | Weaving       |
| `composing`  | An undulating multi-band sash                                | Composing     |
| `breathing`  | A face-on ring, slowly morphing                              | Thinking      |
| `shaping`    | A dotted outline morphing circle → triangle → square         | Shaping       |

The default labels are the screen-reader descriptions in `kOrbSemanticLabels`:

```dart
kOrbSemanticLabels[OrbState.breathing]; // 'Thinking'
```

### Two size tiers

Each state ships **two** tunings — different dot counts, dot radii and speeds — because a 64px design
scaled down to 20px turns to mush. The tier is picked from `size` alone:

| Tier   | Applies when  | Tuned at |
| ------ | ------------- | -------- |
| inline | `size < 40`   | 20 px    |
| avatar | `size >= 40`  | 64 px    |

<img src="https://github.com/itsarvinddev/loading_icon_button/blob/master/doc/thinking-orbs.png?raw=true" width="560" alt="A three-by-three grid of the nine orb states, each cell showing the 64-pixel avatar tuning beside the same state at the 20-pixel inline tuning" />

<sub>The two tunings compared: in each cell, the 64px avatar design with the same state's 20px inline
design beside it. Left to right, top to bottom: `working`, `searching`, `solving`, `listening`,
`connecting`, `weaving`, `composing`, `breathing`, `shaping`. Single frames of continuous animations —
run the [example gallery](example/) to see them move.</sub>

The threshold is exported as `kOrbTierBreakpoint` (`40`). You never select a tier yourself — just
pick the size you want.

```dart
const Row(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    ThinkingOrb(state: OrbState.connecting, size: 18), // inline tuning
    SizedBox(width: 8),
    Text('Connecting to the agent…'),
  ],
)
```

### Theming an orb

Orbs are monochrome by default and take their ink from the ambient `Theme` brightness.

```dart
const ThinkingOrb(
  state: OrbState.composing,
  size: 32,
  theme: OrbTheme.dark,          // auto (default) | dark | light
  color: Color(0xFF7866FE),      // optional tint; null keeps it monochrome
  speed: 1.5,                    // multiplies the state's own tuned speed
  paused: false,
  semanticLabel: 'Drafting your reply',
)
```

`OrbTheme.auto` follows `Theme.of(context).brightness`. `OrbTheme.dark` means *light ink for a dark
surface*; `OrbTheme.light` means *dark ink for a light surface*.

### Motion, reduced motion and the shared clock

- Every mounted orb reads **the same static clock**, so several on screen stay in step no matter when
  each one mounted.
- Animation stops automatically when the orb's route is not current (via `TickerMode`), and when
  `paused: true`.
- When the platform asks for reduced motion (`MediaQuery.disableAnimationsOf`), the ticker stops and
  a **representative still frame** is painted, so the orb still reads as itself instead of vanishing.

### Orbs inside buttons

Every Material button in the package accepts a `LoadingIndicator` (`ArgonButton` takes a plain
`loader` widget instead — put a `ThinkingOrb` straight into it):

```dart
LoadingButton(
  onPressed: () async => submit(),
  // LoadingButton does not inherit the button's icon theme — see below.
  indicator: const LoadingIndicator.orb(
    state: OrbState.working,
    size: 18,
    color: Colors.white,
  ),
  child: const Text('Ask the agent'),
)

ElevatedAutoLoadingButton.icon(
  onPressed: () async => submit(),
  indicator: const LoadingIndicator.orb(state: OrbState.working),
  loadingLabel: const Text('Sending…'),
  icon: const Icon(Icons.send),
  label: const Text('Send'),
)
```

**Where the defaults come from.** An orb with no `size` or `color` reads the ambient `IconTheme`. In
the `*AutoLoadingButton` and `*LoadingButton` families the indicator is built *inside* the Material
button, so that `IconTheme` is the one the button itself installs: the orb picks up the button's
resolved foreground colour and icon size automatically, in both brightnesses.

`LoadingButton` is the exception. It builds its indicator from its own `State`'s context, which sits
**above** the Material button, so `IconTheme.of(context)` there resolves `ThemeData.iconTheme`
(black87 at 24 logical pixels in a default light theme) rather than the button's foreground. Give a
`LoadingButton` indicator an explicit `color:` and `size:`, as the first snippet does — otherwise a
light-theme button that declares a white foreground will show dark dots at the wrong size.

When an orb is used as a button indicator its own semantic label is suppressed — the button already
announces "Loading", and a second label would double-announce.

### Orbs app-wide

Switch every Material button in a subtree over in one line, with a `LoadingButtonTheme` widget or a
`ThemeData` extension (the extension can also differ between light and dark):

```dart
LoadingButtonTheme(
  data: const LoadingButtonThemeData(
    indicator: LoadingIndicator.orb(state: OrbState.working),
  ),
  child: home,
)
```

See [Theming](#theming) for the full field list and resolution order.

### ⚠️ `pumpAndSettle` and orbs

An orb animates **continuously**. `tester.pumpAndSettle()` will never settle while one is mounted —
it throws after its timeout. Drive the clock explicitly, or mount the orb paused:

```dart
// NOT pumpAndSettle:
await tester.pump(const Duration(milliseconds: 100));

// or freeze it:
await tester.pumpWidget(const MaterialApp(
  home: ThinkingOrb(state: OrbState.working, size: 64, paused: true),
));
await tester.pumpAndSettle(); // fine — the ticker is stopped
```

The same applies to any button showing `LoadingIndicator.orb()` while it is loading.

## The AutoLoadingButton family

Thin wrappers over the stock Material buttons. They enter the loading state for exactly as long as
the async callback runs, then leave it — on **both** the success and the failure path. No success or
error phase.

| Widget                      | Extra constructors                     |
| --------------------------- | -------------------------------------- |
| `ElevatedAutoLoadingButton` | `.icon`                                |
| `FilledAutoLoadingButton`   | `.icon`, `.tonal`, `.tonalIcon`        |
| `OutlinedAutoLoadingButton` | `.icon`                                |
| `TextAutoLoadingButton`     | `.icon`                                |
| `IconAutoLoadingButton`     | `.filled`, `.filledTonal`, `.outlined` |

```dart
ElevatedAutoLoadingButton(
  onPressed: () async => submit(),
  loadingLabel: const Text('Submitting…'),
  child: const Text('Submit'),
)

FilledAutoLoadingButton.tonal(
  onPressed: () async => submit(),
  loadingLabel: const Text('Working…'),
  child: const Text('Tonal'),
)

// IconAutoLoadingButton has no child to label, so wrap it to keep an
// accessible name while the indicator is showing.
Semantics(
  label: 'Search',
  child: IconAutoLoadingButton.filledTonal(
    onPressed: () async => submit(),
    indicator: const LoadingIndicator.orb(state: OrbState.searching, size: 20),
    icon: const Icon(Icons.search),
  ),
)
```

Shared parameters, beyond the ones the underlying Material button already takes:

| Parameter        | Meaning                                                                                                                                                                                                                                                                                                                              |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `onPressed`      | `AsyncCallback?` — the button is busy until this future settles                                                                                                                                                                                                                                                                       |
| `onLongPress`    | `AsyncCallback?` — same treatment                                                                                                                                                                                                                                                                                                     |
| `loadingIcon`    | Replaces the indicator outright                                                                                                                                                                                                                                                                                                      |
| `indicator`      | A `LoadingIndicator`; falls back to the theme, then a spinner                                                                                                                                                                                                                                                                        |
| `loadingLabel`   | Text beside the indicator (not on `IconAutoLoadingButton`, which has no label slot). Omit it and the button shrinks to just the indicator — **and loses its accessible name for the whole loading window**, since the indicator replaces the child. Pass it, or wrap the button in your own `Semantics`.                               |
| `switchDuration` | The `AnimatedSize` transition as the button resizes (`kThemeAnimationDuration`)                                                                                                                                                                                                                                                      |

`IconAutoLoadingButton` additionally takes `selectedIcon` / `selectedLoadingIcon` alongside
`isSelected`, and has no `loadingLabel`, `switchDuration` or `onLongPress`.

### Triggering one from outside

Every widget in this family has a state class extending `AutoLoadingButtonState`, with `doPress()`
and `doLongPress()`. Both return the future of the run, so a caller that awaits gets the error
instead of it going unobserved:

```dart
final key = GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>>();

ElevatedAutoLoadingButton(
  key: key,
  onPressed: () async => submit(),
  child: const Text('Submit'),
);

// elsewhere
try {
  await key.currentState?.doPress();
} catch (error) {
  showError(error);
}
```

Calling `doPress()` while a run is already in flight returns the **existing** future rather than
starting a second run. On the tap path — where the future is discarded — a throwing callback is
routed to `FlutterError.reportError` with package context.

## The XxxLoadingButton family

The same Material buttons, but **you** own the flag. Use these when the loading state already lives
in a bloc, a provider or a notifier.

`ElevatedLoadingButton`, `FilledLoadingButton`, `OutlinedLoadingButton` and `TextLoadingButton`, each
with `.icon` (and `FilledLoadingButton` also with `.tonal` / `.tonalIcon`).

```dart
ElevatedLoadingButton(
  isLoading: _isLoading,
  onPressed: _submit,
  loadingLabel: const Text('Submitting…'),
  child: const Text('Submit'),
)

FilledLoadingButton.tonalIcon(
  isLoading: _isLoading,
  onPressed: _submit,
  indicator: const LoadingIndicator.orb(state: OrbState.working),
  loadingLabel: const Text('Running…'),
  icon: const Icon(Icons.bolt),
  label: const Text('Run'),
)

OutlinedLoadingButton(
  isLoading: _isLoading,
  loadingClickable: true, // stays tappable while loading — e.g. to cancel
  onPressed: _submit,
  loadingLabel: const Text('Cancel'),
  child: const Text('Cancellable'),
)
```

`isLoading`, `onPressed` and `child` (or `icon` + `label`) are required. `onPressed` here is a plain
`VoidCallback?`, not an `AsyncCallback`. Unless `loadingClickable` is true, the button is disabled
while `isLoading`.

Every snippet above passes `loadingLabel`. That is deliberate: the indicator replaces the child, so
without a `loadingLabel` the button has no accessible name while busy.

There is no `IconLoadingButton`; use `IconAutoLoadingButton` for an icon button.

## ArgonButton and ArgonTimerButton

`ArgonButton` animates its width down to a pill and shows a loader inside it. You drive it with the
`startLoading` / `stopLoading` callbacks handed to `onTap`:

```dart
ArgonButton(
  height: 50,
  width: 350,
  borderRadius: 5,
  color: const Color(0xFF7866FE),
  loader: const Padding(
    padding: EdgeInsets.all(10),
    child: ThinkingOrb(state: OrbState.working, size: 28),
  ),
  onTap: (Function startLoading, Function stopLoading, ArgonButtonState btnState) {
    if (btnState == ArgonButtonState.idle) {
      startLoading();
      doNetworkRequest().whenComplete(() => stopLoading());
    }
  },
  child: const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 18)),
)
```

`ArgonButtonState` has two values, `idle` and `busy`. A `null` `onTap` disables the button. Both
`startLoading` and `stopLoading` are safe to call after the button has been disposed — a request
completing after the user navigated away is the normal case.

`ArgonTimerButton` is the countdown variant: `loader` is a `Widget Function(int seconds)` builder, and
`onTap` receives a `startTimer` function that takes the number of seconds.

```dart
ArgonTimerButton(
  height: 50,
  width: 350,
  borderRadius: 5,
  color: const Color(0xFF7866FE),
  initialTimer: 0,
  loader: (int seconds) => Text(
    'Resend in $seconds s',
    style: const TextStyle(color: Colors.white, fontSize: 18),
  ),
  onTap: (Function startTimer, ArgonButtonState? btnState) {
    if (btnState == ArgonButtonState.idle) {
      resend();
      startTimer(30);
    }
  },
  child: const Text('Send code', style: TextStyle(color: Colors.white, fontSize: 18)),
)
```

`startTimer` throws an `ArgumentError` if handed a non-positive duration. Set `initialTimer` to start
the countdown as soon as the button mounts.

## Accessibility

### What `LoadingButton` does

The button semantics below are **`LoadingButton`'s alone**. The `*AutoLoadingButton` and
`*LoadingButton` families are thinner wrappers and publish no semantics of their own — read
[Things to handle yourself](#things-to-handle-yourself) before relying on anything here for those.
(The orb and tooltip items are the exceptions: they apply wherever a `ThinkingOrb` or a `tooltip` is
used.)

- **Real Material buttons underneath.** `LoadingButton` renders an `ElevatedButton`, `FilledButton`,
  `OutlinedButton`, `TextButton` or `IconButton`, so it inherits the button role, keyboard
  activation, focus highlight and minimum tap target from the framework. `focusNode` and `autofocus`
  are passed through.
- **Transient state announcements.** In `loading`, `success` and `error` the child is wrapped in a
  `Semantics` node with `liveRegion: true`, so a screen reader announces the change without the user
  refocusing. The label is `loadingText` / `successText` / `errorText`, falling back to `'Loading'`,
  `'Success'` and `'Error'`.
- **No duplicate semantics.** The idle state adds no label of its own, so your `child` provides the
  button's accessible name. Earlier releases published a second `Semantics` button node here, which
  read the button out twice.
- **Orb labels.** `ThinkingOrb` publishes a per-state label from `kOrbSemanticLabels`. Override it
  with `semanticLabel`, or pass `''` to hide the orb from accessibility tools when a nearby label
  already describes it — which is what `LoadingIndicator.orb()` does inside a button.
- **Reduced motion.** `ThinkingOrb` honours `MediaQuery.disableAnimationsOf` and paints a
  representative still frame instead of animating.
- **Tooltips.** `LoadingButton.tooltip` and `IconAutoLoadingButton.tooltip` add a `Tooltip`, which is
  itself exposed to screen readers.
- **Haptics** are opt-out via `enableHapticFeedback` on the button or the theme.

```dart
LoadingButton(
  onPressed: () async => submit(),
  loadingText: 'Submitting your order',
  successText: 'Order placed',
  errorText: 'Order failed, try again',
  tooltip: 'Place the order',
  child: const Text('Place order'),
)
```

### Things to handle yourself

- **The other two families publish no loading semantics.** The `*AutoLoadingButton` and
  `*LoadingButton` families add no `Semantics` node and no `liveRegion`; nothing above applies to
  them. Worse, because the indicator *replaces* the child, the button's accessible name disappears
  for the whole loading window: a button that reads `label: "Send"` while idle exposes no label at
  all while busy. Passing `loadingLabel` is what keeps a name there — the label sits beside the
  indicator and becomes the button's accessible name while loading. If you need a name that differs
  from the visible label (or none is visible, as on an `IconAutoLoadingButton`), wrap the button in
  your own `Semantics`:

  ```dart
  Semantics(
    label: 'Refresh',
    child: IconAutoLoadingButton(
      onPressed: () async => refresh(),
      icon: const Icon(Icons.refresh),
      tooltip: 'Refresh',
    ),
  )
  ```

- **Localisation.** The fallback labels are English literals. Pass your own localised `loadingText` /
  `successText` / `errorText` and `semanticLabel`.
- **Text scaling.** The default `LoadingButtonSizing.legacy` is a fixed box that does **not** grow
  with the platform text scale, so long labels at large scales will clip. Use
  `LoadingButtonSizing.intrinsic()` if your labels must scale.
- **Contrast.** There is no high-contrast-specific handling. The default
  `LoadingButtonColorStrategy.legacy` paints unconditional white on `Theme.primaryColor`, which is
  not dark-mode safe; switch to `material3` (or supply `LoadingButtonColors.fromScheme`) for
  contrast-safe role pairs in both brightnesses.

## Testing

```dart
testWidgets('button reaches success', (WidgetTester tester) async {
  final LoadingButtonController controller = LoadingButtonController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: LoadingButton(
        controller: controller,
        animationDuration: const Duration(milliseconds: 1),
        onPressed: () async {},
        child: const Text('Submit'),
      ),
    ),
  ));

  await tester.tap(find.text('Submit'));
  await tester.pump();                                 // apply the state change
  await tester.pump(const Duration(milliseconds: 16)); // run out the cross fade

  expect(controller.state, ActionState.success);
});
```

- **Never `pumpAndSettle` around an orb.** It animates forever. Use `tester.pump(duration)`, or mount
  with `paused: true`.
- **Collapse the cross fade.** `animationDuration: Duration(milliseconds: 1)` keeps two children from
  overlapping in the `AnimatedSwitcher`, so your finders match exactly one widget.
- **Assert on the controller, not the pixels.** `controller.state`, `controller.progress` and
  `controller.lastError` are the stable surface.
- **Haptics are fire-and-forget.** The button never awaits the platform channel, so a press resolves
  normally on a test binding. `enableHapticFeedback: false` avoids the calls entirely.
- **Success and error windows** are real timers. Advance past `successDuration` / `errorDuration` to
  observe the return to idle, or set `resetAfterDuration: false`.

## Platform support

Pure Dart and Flutter — no platform channels beyond `HapticFeedback`, no plugins, no native code, no
third-party dependencies. Orbs are drawn with `CustomPainter` (no shaders, no image assets), so they
render identically everywhere.

| Platform | Support |
| -------- | ------- |
| Android  | ✅       |
| iOS      | ✅       |
| Linux    | ✅       |
| macOS    | ✅       |
| Web      | ✅       |
| Windows  | ✅       |

Haptic feedback is a no-op on platforms that do not provide it.

## Deprecations

Everything below still works and still compiles; each has a direct replacement.

| Deprecated                                | Replacement                                      |
| ----------------------------------------- | ------------------------------------------------ |
| `LoadingButton.onError`                   | `onFailure(Object error, StackTrace stack)`      |
| `LoadingButtonConfig`                     | `LoadingButtonThemeData` + `LoadingButtonTheme`  |
| `IconButtonLoading`                       | Compose your own `Row` of an `Icon` and a `Text` |
| `buildChildWithIcon` / `buildChildWithIC` | Same                                             |
| `buildText`                               | `Text(text, style: style)`                       |

```dart
// before
LoadingButton(onPressed: () async => submit(), onError: (dynamic e) => showError(e as Object), child: const Text('Old'));

// after
LoadingButton(onPressed: () async => submit(), onFailure: (Object e, StackTrace s) => report(e, s), child: const Text('New'));
```

Two other 1.1.0 changes worth knowing:

- The `ButtonStateExtension` extension is now `ActionStateExtension`. Extension members resolve by
  member name, so `state.isLoading` and friends keep compiling unchanged; only an explicit extension
  override (`ButtonStateExtension(state).isIdle`) needs updating.
- `ActionState.isInteractive` used to be an exact duplicate of `isIdle`. It now means "a press would
  be accepted" — true for everything except `loading` and `disabled`. Use `isIdle` for the old
  meaning.

See [MIGRATION.md](https://github.com/itsarvinddev/loading_icon_button/blob/master/MIGRATION.md) and
the [changelog](https://pub.dev/packages/loading_icon_button/changelog).

## LLM and AI assistant support

If you write Flutter with Claude, Copilot, Cursor or similar, start here. **This package needs it
more than most:** the README shipped before 1.1.0 still documented the 0.0.x API — `iconData`,
`successIcon`, `failedIcon`, `showBox`, `loaderSize`, `animateOnTap` — which the 1.0.0 rewrite had
already removed, alongside spellings that never existed in any release (`ButtonState.Idle`, a bare
`AutoLoadingButton` class). Either way none of it compiles against 1.1.0, so assistants trained on
that README write code that does not build. The antidote is below.

### Point your assistant at `llms.txt`

[`llms.txt`](https://raw.githubusercontent.com/itsarvinddev/loading_icon_button/master/llms.txt) is a
compact, machine-readable digest of the whole public API: every parameter, type, default, the nine
orb states, the testing caveats, and a list of the hallucinated symbols with their real
replacements. Paste this into your assistant:

```text
Read https://raw.githubusercontent.com/itsarvinddev/loading_icon_button/master/llms.txt and use it as the API reference for loading_icon_button.
```

If your tool cannot fetch URLs, drop the file into the repo (many assistants pick up a root
`llms.txt` automatically) or paste the block below.

### Pasteable context block

Short enough to paste into any chat. These are the facts assistants get wrong most often:

```text
loading_icon_button 1.1.0 — import 'package:loading_icon_button/loading_icon_button.dart';
Facts to respect (the pre-1.1.0 README was wrong; ignore it):
1. The state enum is ActionState {idle, loading, success, error, disabled} — lowerCamelCase.
   There is no ButtonState and no ButtonState.Idle.
2. LoadingButton.onPressed is AsyncCallback? (Future<void> Function()), so it must be
   `() async { ... }`. On ElevatedLoadingButton/FilledLoadingButton/etc. onPressed is a plain
   VoidCallback? instead.
3. There is no AutoLoadingButton class. Use ElevatedAutoLoadingButton, FilledAutoLoadingButton,
   OutlinedAutoLoadingButton, TextAutoLoadingButton or IconAutoLoadingButton.
4. These parameters do not exist: iconData, successIcon, failedIcon, iconColor, showBox,
   loaderSize, animateOnTap, duration, errorColor, successColor. Use successWidget/errorWidget
   (or successText/errorText), indicator:, animationDuration:, colors: and sizing:.
5. loadingText/successText/errorText REPLACE the state's widget; they do not caption it.
   To show a spinner plus a caption, build a Row and pass it as loadingWidget.
6. LoadingButton's default sizing is a fixed 200x50 box and its default colours are not
   dark-mode safe. New code should pass sizing: LoadingButtonSizing.intrinsic() and
   colorStrategy: LoadingButtonColorStrategy.material3.
7. ThinkingOrb animates forever, so tester.pumpAndSettle() never settles while one is mounted.
   Use tester.pump(duration) or mount with paused: true.
```

### Task prompts

Copy the one that matches your job. Each names the exact symbols to use and what to avoid.

**Add a loading submit button to an existing form**

```text
In my Flutter app, replace the submit button on <FILE> with loading_icon_button's LoadingButton
(import 'package:loading_icon_button/loading_icon_button.dart').

Requirements:
- onPressed is an AsyncCallback: `onPressed: () async => ...` calling my existing submit function.
- Pass sizing: const LoadingButtonSizing.intrinsic() so it sizes to its content, and
  colorStrategy: LoadingButtonColorStrategy.material3 so success/error colours come from the
  ColorScheme.
- Use successText: and errorText: for the terminal states, and
  onFailure: (Object error, StackTrace stack) { ... } for error reporting.
- Use enabled: to disable it while the form is invalid, plus tooltip: to explain why.
- child: is the idle label.

Do NOT use: iconData, successIcon, failedIcon, showBox, loaderSize, animateOnTap, duration,
errorColor, successColor, ButtonState, or the deprecated onError — none of those exist or are
current. Do not add a second Semantics node around it; LoadingButton publishes its own live-region
label from loadingText/successText/errorText.
```

**Show determinate upload progress driven from outside the widget**

```text
Using loading_icon_button, wire my existing upload function to a LoadingButton that shows real
progress.

- Create a LoadingButtonController in the State, dispose it in dispose().
- Pass it as LoadingButton(controller: controller, ...) and call controller.setProgress(fraction)
  from the upload function as bytes complete (0.0..1.0; pass null to go back to indeterminate).
- Set progressStyle: LoadingProgressStyle.both so the indicator goes determinate AND the
  background fills.
- Render a percentage label next to the button with
  ValueListenableBuilder<LoadingButtonValue>(valueListenable: controller, ...), reading
  value.isDeterminate and value.progress.
- On failure call controller.error(error, stackTrace); on success controller.success().

Notes: when a controller is attached, controller.progress wins over the progress: argument, so do
not pass both. LoadingButtonValue fields are state, progress, error, stackTrace. Do not invent a
`percent` or `value` parameter on LoadingButton.
```

**Put a thinking orb in a chat/agent UI and switch the whole app over**

```text
Using loading_icon_button, add an animated ThinkingOrb to my chat UI and make every loading button
in the app use an orb instead of a spinner.

- While the agent is streaming, show ThinkingOrb(state: OrbState.working, size: 64) in the message
  list. Use OrbState.searching while it is calling a search tool and OrbState.composing while it is
  drafting. The nine states are working, searching, solving, listening, connecting, weaving,
  composing, breathing, shaping.
- For an inline orb beside text use size: 18 — sizes below kOrbTierBreakpoint (40) get a separate
  tuning designed for small sizes. Do not scale a 64px orb down with Transform.
- Switch the app over by adding a ThemeExtension:
  ThemeData(extensions: const <ThemeExtension<dynamic>>[
    LoadingButtonThemeData(indicator: LoadingIndicator.orb(state: OrbState.working)),
  ])
  That covers LoadingButton and every *AutoLoadingButton / *LoadingButton beneath it.
- Any explicit indicator on a LoadingButton needs its own size: and color:, because LoadingButton
  builds its indicator above the Material button and so does not inherit the button's IconTheme.

Orbs are indeterminate by design: if a button also reports progress, use
LoadingProgressStyle.fill. Do not pass a `duration` or `loaderSize`; the parameters are state,
size, theme (OrbTheme.auto/dark/light), speed, paused, color and semanticLabel.
```

**Migrate code written against the old or hallucinated API**

```text
This file was written against an old/incorrect loading_icon_button API and no longer compiles
against 1.1.0. Fix it without changing behaviour. Apply these replacements:

- ButtonState -> ActionState, and capitalised values -> lowerCamelCase
  (ButtonState.Idle -> ActionState.idle, and likewise loading, success, error, disabled).
- A bare `AutoLoadingButton` -> ElevatedAutoLoadingButton (or the Filled/Outlined/Text/Icon
  variant that matches the surrounding style).
- iconData: Icons.x -> put an Icon in child:, or switch to the `.icon` constructor with
  icon: and label:.
- successIcon:/failedIcon: -> successWidget: Icon(...) / errorWidget: Icon(...).
- errorColor:, successColor: -> colors: LoadingButtonColors(success: ..., error: ...).
- iconColor: -> style: LoadingButtonStyle(foregroundColor: ...), or the standard buttonStyle:.
  LoadingButtonColors has no icon slot; its onLoading/onSuccess/onError are per-state foregrounds.
- showBox: -> remove; control geometry with sizing: (LoadingButtonSizing).
- loaderSize: -> indicator: LoadingIndicator.circular(size: N).
- duration: -> animationDuration:.
- animateOnTap: -> remove; there is no equivalent.
- onError: (dynamic e) -> onFailure: (Object error, StackTrace stack).
- A synchronous onPressed on LoadingButton -> make it `() async { ... }`.
- ButtonStateExtension(state).isIdle -> state.isIdle.

Then confirm it compiles with `flutter analyze`. Do not add any parameter you have not verified
exists; check llms.txt at
https://raw.githubusercontent.com/itsarvinddev/loading_icon_button/master/llms.txt if unsure.
```

**Write widget tests for a screen that uses these buttons**

```text
Write widget tests for <FILE>, which uses loading_icon_button.

Rules for this package:
- NEVER call tester.pumpAndSettle() if a ThinkingOrb or a LoadingIndicator.orb() is mounted — an
  orb animates continuously and pumpAndSettle throws on timeout. Use
  await tester.pump(const Duration(milliseconds: 100)), or mount the orb with paused: true.
- Build the button with animationDuration: const Duration(milliseconds: 1) so the AnimatedSwitcher
  cross fade does not leave two children mounted; otherwise finders match two widgets.
- Assert on a LoadingButtonController (controller.state, controller.progress, controller.lastError)
  rather than on rendered pixels, and addTearDown(controller.dispose).
- successDuration/errorDuration are real Timers: pump past them to observe the return to idle, or
  set resetAfterDuration: false to park the button in its terminal state.
- Pass enableHapticFeedback: false to avoid platform-channel calls.
- ActionState values are idle, loading, success, error, disabled.

Cover: tapping reaches ActionState.success; a throwing callback reaches ActionState.error and calls
onFailure; a double tap runs the callback only once.
```

**Add an accessible icon-only loading button**

```text
Using loading_icon_button, add an icon-only button that shows a loading indicator while an async
refresh runs.

- Use IconAutoLoadingButton (there is no IconLoadingButton). Variants: the default, .filled,
  .filledTonal and .outlined.
- onPressed is an AsyncCallback: `onPressed: () async => refresh()`.
- IconAutoLoadingButton has NO loadingLabel, and its indicator replaces the icon while loading, so
  the button has no accessible name during the whole loading window. Wrap it in
  Semantics(label: 'Refresh', child: ...) and also pass tooltip: 'Refresh'.
- To use an orb instead of a spinner, pass
  indicator: const LoadingIndicator.orb(state: OrbState.working, size: 20).
```

### Common mistakes, and the fix

| Mistake                                                          | Fix                                                                                                  |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Passing a synchronous `onPressed` to `LoadingButton`             | It is an `AsyncCallback`: `onPressed: () async { … }`. The `*LoadingButton` family takes a `VoidCallback?`. |
| Expecting `loadingText` to caption the spinner                   | It replaces it. Build a `Row` and pass it as `loadingWidget`.                                        |
| Writing `ButtonState.Idle`                                       | `ActionState.idle`.                                                                                  |
| Reaching for `AutoLoadingButton` or `IconLoadingButton`          | Neither exists. Use `ElevatedAutoLoadingButton` / `IconAutoLoadingButton`.                            |
| `pumpAndSettle()` in a test with an orb on screen                | `tester.pump(duration)`, or mount the orb with `paused: true`.                                       |
| Wondering why the button is 200×50 and clips long labels         | That is `LoadingButtonSizing.legacy`, the default. Pass `LoadingButtonSizing.intrinsic()`.            |
| Dark-mode text coming out white-on-white                         | That is `LoadingButtonColorStrategy.legacy`, the default. Pass `material3`.                           |
| An orb inside a `LoadingButton` rendering dark and oversized     | `LoadingButton` builds its indicator above the Material button, so set `size:` and `color:` explicitly. |
| Omitting `loadingLabel` on an `*AutoLoadingButton`               | The button loses its accessible name while busy. Pass it, or wrap in `Semantics`.                     |
| Passing both `progress:` and a `controller`                      | The controller wins. Drive it with `controller.setProgress()` only.                                  |

## Attribution

The `ThinkingOrb` engine is a Dart port of **thinking-orbs**, MIT licensed:

- Original concept and implementation: **[thinking-orbs](https://github.com/Jakubantalik/thinking-orbs)**
  by Jakub Antalik.
- Flutter port that this work builds on: **[thinking-orbs](https://github.com/iamEtornam/thinking-orbs)**
  by Bright Sunu.

Our Dart port is verified against upstream's published **golden vectors** — the exact dot positions,
radii and depths each state produces at given times — so the animations match the originals
numerically, not just by eye.

Other credits:

- [Contributors](https://github.com/itsarvinddev/loading_icon_button/graphs/contributors)
- The Argon buttons are inspired by
  [argon_buttons_flutter](https://pub.dev/packages/argon_buttons_flutter)
- `LoadingButton` was originally inspired by
  [rounded_loading_button](https://pub.dev/packages/rounded_loading_button)

## Contributing

Contributions are welcome.

1. Clone the repository
2. `flutter pub get`
3. `flutter test`
4. Make your change, with tests
5. `dart analyze` and `dart format .`
6. Open a pull request

## License and issues

MIT — see [LICENSE](https://github.com/itsarvinddev/loading_icon_button/blob/master/LICENSE).

File issues on the
[GitHub issue tracker](https://github.com/itsarvinddev/loading_icon_button/issues). The package lives
on [pub.dev](https://pub.dev/packages/loading_icon_button) and the source on
[GitHub](https://github.com/itsarvinddev/loading_icon_button).
