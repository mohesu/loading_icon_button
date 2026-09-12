# loading_icon_button

[![pub package](https://img.shields.io/pub/v/loading_icon_button.svg)](https://pub.dev/packages/loading_icon_button)
[![GitHub Stars](https://img.shields.io/github/stars/itsarvinddev/loading_icon_button.svg?style=social&label=Star)](https://github.com/itsarvinddev/loading_icon_button)
[![GitHub Issues](https://img.shields.io/github/issues/itsarvinddev/loading_icon_button.svg)](https://github.com/itsarvinddev/loading_icon_button/issues)
[![GitHub License](https://img.shields.io/github/license/itsarvinddev/loading_icon_button.svg)](https://github.com/itsarvinddev/loading_icon_button/blob/master/LICENSE)
[![X](https://img.shields.io/badge/X-Follow-blue)](https://x.com/itsarvinddev)

Loading buttons for Flutter — plus **ThinkingOrb**, a family of nine hand-tuned animated
orbs for AI and agent interfaces that any button in the package can wear instead of a
spinner.

<img src="https://github.com/itsarvinddev/loading_icon_button/blob/master/generated-image.png?raw=true" width="370" height="600" />

## Features

- **Thinking orbs.** Nine animated [`OrbState`](#thinking-orbs) designs — working,
  searching, solving, listening, connecting, weaving, composing, breathing, shaping —
  drawn with a single `CustomPainter`. No shaders, no blurs, no image assets.
- **Drop an orb into any button** with `LoadingIndicator.orb()`, or switch a whole app
  over in one line with `LoadingButtonTheme`.
- **Four button families**: `LoadingButton` (its own state machine),
  `XxxAutoLoadingButton` (loading for as long as an async callback runs),
  `XxxLoadingButton` (driven by a plain `isLoading` flag), and
  `ArgonButton` / `ArgonTimerButton` (collapse-into-the-loader, and a countdown).
- **Drive it from anywhere** with `LoadingButtonController` — start, report progress,
  succeed, fail, reset, disable, cool down.
- **Determinate progress**, shown on the indicator, as a background fill, or both.
- **Themed defaults** via a `ThemeExtension` or an `InheritedWidget`, resolved per
  subtree and per brightness.
- **Debounce and cooldown** built in, plus a synchronous press latch so a fast double
  tap can never start your callback twice.
- **Pure Dart**, zero plugin dependencies: Android, iOS, Linux, macOS, web and Windows.

## Installation

```yaml
dependencies:
  loading_icon_button: ^1.1.0
```

```bash
flutter pub get
```

Requires Dart `>=3.4.0` and Flutter `>=3.22.0`.

```dart
import 'package:loading_icon_button/loading_icon_button.dart';
```

## Quick start

```dart
LoadingButton(
  onPressed: () async => submit(),
  onSuccess: () => debugPrint('done'),
  onFailure: (Object error, StackTrace stack) => report(error, stack),
  child: const Text('Submit'),
)
```

The button runs `onPressed`, shows a loading indicator until the returned future
settles, flashes success or error, then returns to idle.

## Thinking orbs

`ThinkingOrb` is a Dart port of the [thinking-orbs](#attribution) engine: filled circles
over a rotated, z-sorted 3D point field, redrawn every frame by one `CustomPainter`.
Each state is a separate hand-tuned design rather than a variation on one loop.

```dart
const ThinkingOrb(state: OrbState.searching, size: 64)
```

<img src="https://github.com/itsarvinddev/loading_icon_button/blob/master/doc/thinking-orbs.png?raw=true" width="560" alt="The nine thinking-orb states, each shown at the 64px avatar tuning with the 20px inline tuning beside it" />

<sub>Left to right, top to bottom: `working`, `searching`, `solving`, `listening`, `connecting`,
`weaving`, `composing`, `breathing`, `shaping`. The small orb in each cell is the same state at the
inline tuning. Single frames of continuous animations — run the
[example gallery](example/) to see them move.</sub>

### The nine states

| `OrbState`    | What it depicts                                            | Default label |
| ------------- | ---------------------------------------------------------- | ------------- |
| `working`     | Particles running on tilted orbits                         | Working       |
| `searching`   | A scan meridian sweeping a dotted globe                    | Searching     |
| `solving`     | Bands scrambling in quarter turns, then clicking back solved | Solving     |
| `listening`   | A waveform rolling through the latitude rings              | Listening     |
| `connecting`  | A constellation wiring itself, packets running the edges   | Connecting    |
| `weaving`     | Three strands plaiting around the sphere                   | Weaving       |
| `composing`   | An undulating multi-band sash                              | Composing     |
| `breathing`   | A face-on ring, slowly morphing                            | Thinking      |
| `shaping`     | A dotted outline morphing circle → triangle → square       | Shaping       |

The default labels are the screen-reader descriptions in `kOrbSemanticLabels`:

```dart
kOrbSemanticLabels[OrbState.breathing]; // 'Thinking'
```

### Two size tiers

Each state ships **two** tunings — different dot counts, dot radii and speeds — because
a 64px design scaled down to 20px turns to mush. The tier is picked from `size` alone:

| Tier     | Applies when            | Tuned at |
| -------- | ----------------------- | -------- |
| inline   | `size < 40`             | 20 px    |
| avatar   | `size >= 40`            | 64 px    |

The threshold is exported as `kOrbTierBreakpoint` (`40`). You never select a tier
yourself — just pick the size you want.

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

`OrbTheme.auto` follows `Theme.of(context).brightness`. `OrbTheme.dark` means *light ink
for a dark surface*; `OrbTheme.light` means *dark ink for a light surface*.

### Motion, reduced motion and the shared clock

- Every mounted orb reads **the same static clock**, so several on screen stay in step
  no matter when each one mounted.
- Animation stops automatically when the orb's route is not current (via `TickerMode`),
  and when `paused: true`.
- When the platform asks for reduced motion (`MediaQuery.disableAnimationsOf`), the
  ticker stops and a **representative still frame** is painted, so the orb still reads
  as itself instead of vanishing.

### Orbs inside buttons

Any button in the package accepts a `LoadingIndicator`:

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
```

```dart
ElevatedAutoLoadingButton.icon(
  onPressed: () async => submit(),
  indicator: const LoadingIndicator.orb(state: OrbState.working),
  loadingLabel: const Text('Sending…'),
  icon: const Icon(Icons.send),
  label: const Text('Send'),
)
```

**Where the defaults come from.** An orb with no `size` or `color` reads the ambient
`IconTheme`. In the `*AutoLoadingButton` and `*LoadingButton` families the indicator is
built *inside* the Material button, so that `IconTheme` is the one the button itself
installs: the orb picks up the button's resolved foreground colour and icon size
automatically, in both brightnesses.

`LoadingButton` is the exception. It builds its indicator from its own `State`'s
context, which sits **above** the Material button, so `IconTheme.of(context)` there
resolves `ThemeData.iconTheme` (black87 at 24 logical pixels in a default light theme)
rather than the button's foreground. Give a `LoadingButton` indicator an explicit
`color:` and `size:`, as the first snippet does — otherwise a light-theme button that
declares a white foreground will show dark dots at the wrong size.

When an orb is used as a button indicator its own semantic label is suppressed — the
button already announces "Loading", and a second label would double-announce.

### Orbs app-wide

Wrap a subtree:

```dart
LoadingButtonTheme(
  data: const LoadingButtonThemeData(
    indicator: LoadingIndicator.orb(state: OrbState.working),
  ),
  child: home,
)
```

…or install it on your `ThemeData`, which also lets it differ between light and dark:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const <ThemeExtension<dynamic>>[
      LoadingButtonThemeData(
        indicator: LoadingIndicator.orb(state: OrbState.weaving),
        colorStrategy: LoadingButtonColorStrategy.material3,
      ),
    ],
  ),
  home: const HomePage(),
)
```

### ⚠️ `pumpAndSettle` and orbs

An orb animates **continuously**. `tester.pumpAndSettle()` will never settle while one
is mounted — it throws after its timeout. Drive the clock explicitly, or mount the orb
paused:

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

## Which button?

| Family                                                   | Who owns the loading state             | Reach for it when                                     |
| -------------------------------------------------------- | -------------------------------------- | ----------------------------------------------------- |
| [`LoadingButton`](#loadingbutton)                        | The widget, plus success/error phases  | You want the full idle → loading → success/error cycle |
| [`XxxAutoLoadingButton`](#the-autoloadingbutton-family)  | The widget, for as long as the future runs | You want a stock Material button that spins while busy |
| [`XxxLoadingButton`](#the-xxxloadingbutton-family)      | **You**, via an `isLoading` flag       | The state already lives in your bloc/provider/notifier |
| [`ArgonButton` / `ArgonTimerButton`](#argonbutton-and-argontimerbutton) | You, via callbacks    | You want the collapse-into-a-pill look, or a countdown |

## LoadingButton

### The state machine

`ActionState` has five values:

```
idle ──press──▶ loading ──┬─▶ success ──┐
                          └─▶ error   ──┴─▶ idle   (after successDuration / errorDuration)

disabled  ◀── enabled: false, controller.setEnabled(false), or an active cooldown
```

```dart
LoadingButton(
  onPressed: () async => submit(),
  successText: 'Saved',
  errorText: 'Could not save',
  successDuration: const Duration(seconds: 2),
  errorDuration: const Duration(seconds: 3),
  resetAfterDuration: true,
  onStateChanged: (ActionState state) {
    if (state.isError) debugPrint('failed');
    if (state.isInteractive) debugPrint('pressable');
  },
  child: const Text('Save'),
)
```

Rules worth knowing:

- A press is accepted **only** from `idle`, and a synchronous latch closes before the
  first `await`, so a double tap cannot run `onPressed` twice.
- If `onPressed` throws, the button goes to `error` and calls `onFailure(error, stack)`.
  If neither `onFailure` nor the deprecated `onError` is set, the error is forwarded to
  `FlutterError.reportError` rather than swallowed.
- `resetAfterDuration: false` parks the button in its terminal state; drive it back with
  a controller.
- `onStateChanged` fires on every transition except the initial `idle`.

`ActionState` carries convenience predicates: `isIdle`, `isLoading`, `isSuccess`,
`isError`, `isDisabled`, and `isInteractive` (true for every state except `loading` and
`disabled`). Note that `LoadingButton` itself is stricter than `isInteractive`: it only
accepts a press from `idle`, and is rendered disabled while it rests in `success` or
`error`. If you want "is this button tappable right now", use `isIdle`.

### LoadingButtonController

`LoadingButtonController` is a `ValueNotifier<LoadingButtonValue>`, so the same object
drives the button and renders the rest of your UI. No `GlobalKey` required.

```dart
class _UploadState extends State<Upload> {
  final LoadingButtonController _controller = LoadingButtonController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    for (int i = 0; i <= 10; i++) {
      _controller.setProgress(i / 10);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        LoadingButton(
          controller: _controller,
          onPressed: _upload,
          progressStyle: LoadingProgressStyle.both,
          child: const Text('Upload'),
        ),
        ValueListenableBuilder<LoadingButtonValue>(
          valueListenable: _controller,
          builder: (BuildContext context, LoadingButtonValue value, _) {
            return Text(
              value.isDeterminate
                  ? '${(value.progress! * 100).round()}%'
                  : value.state.name,
            );
          },
        ),
        TextButton(
          onPressed: () => _controller.press(),
          child: const Text('Press it from here'),
        ),
      ],
    );
  }
}
```

| Command                                | Effect                                                               |
| -------------------------------------- | -------------------------------------------------------------------- |
| `start({progress})`                    | Move to `loading`, optionally determinate                             |
| `setProgress(double?)`                 | Report `0.0..1.0`; `null` restores the indeterminate indicator        |
| `success()`                            | Move to `success`                                                     |
| `error([error, stackTrace])`           | Move to `error`, recording both                                       |
| `reset()`                              | Back to `idle`, clearing progress and the last error                  |
| `setEnabled(bool)`                     | Toggle `disabled` (a no-op mid-run)                                   |
| `setActionState(state, {progress})`    | Escape hatch for states the named commands don't cover                |
| `press()`                              | Run every attached button's `onPressed`, honouring each press latch   |
| `startCooldown(Duration)`              | Hold `disabled` for a window, then return to `idle`                   |

Readable state: `state`, `progress`, `lastError`, `lastStackTrace`, `isCoolingDown`,
`cooldownRemaining`, `isAttached`, `attachmentCount`.

`LoadingButtonValue` bundles `state`, `progress`, `error` and `stackTrace` into one
immutable value, so a listener can never observe an `error` paired with stale progress.

One controller may drive several buttons at once; they all mirror the same value.
Dispose it like any `ChangeNotifier`.

### Sizing

**The default is still the legacy geometry**: a fixed **200 × 50** box, silently widened
to **240 × 50** when the window is wider than 600 logical pixels. That is what every
release before 1.1.0 did, and it stays the default so upgrading moves nothing.

It is almost never what you want. Opt into content sizing:

```dart
LoadingButton(
  onPressed: () async => submit(),
  sizing: const LoadingButtonSizing.intrinsic(),
  child: const Text('Sizes to its content'),
)
```

| Sizing                                              | Behaviour                                              |
| --------------------------------------------------- | ------------------------------------------------------ |
| `LoadingButtonSizing.legacy` *(default)*             | Fixed 200×50; 240×50 above a 600px-wide window          |
| `LoadingButtonSizing.intrinsic({constraints})`       | Sizes to content like a normal `ElevatedButton`, animating between states |
| `LoadingButtonSizing.expand({height})`               | Fills the parent's width                                |
| `LoadingButtonSizing.fixed({width, height})`         | Exactly this size; a null dimension is left to content  |

```dart
LoadingButton(
  onPressed: () async => submit(),
  sizing: const LoadingButtonSizing.intrinsic(
    constraints: BoxConstraints(minWidth: 120, maxWidth: 320),
  ),
  child: const Text('Bounded'),
)
```

The explicit `width` / `height` parameters still win over whatever `sizing` computes.

Flip your whole app over at once:

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

> 2.0.0 will make `intrinsic` the default and remove `legacy`.

### Theming

`LoadingButtonThemeData` supplies defaults for every loading button beneath it:

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

Install it either as a `ThemeExtension` on your `ThemeData` (resolved per brightness,
and lerped across theme animations) or with a `LoadingButtonTheme` widget around a
subtree.

Resolution order, highest first:

1. The widget's own arguments
2. The ambient `LoadingButtonThemeData`
3. The deprecated `LoadingButtonConfig` singleton
4. Package defaults

That ambient `LoadingButtonThemeData` is the nearest `LoadingButtonTheme` widget if
there is one, and otherwise the `ThemeData` extension. The two are **not** merged — a
`LoadingButtonTheme` widget replaces the extension wholesale for its subtree, so put
every field you still want into it.

Read it back with `LoadingButtonThemeData.of(context)`, or
`LoadingButtonTheme.maybeOf(context)` for just the widget-level one.

> `LoadingButtonConfig` — the process-wide singleton from earlier releases — is
> deprecated but still honoured. It cannot vary by subtree or by brightness, its
> `reset()` cannot reach already-built widgets, and its default widgets hardcode white.
> Move those values into a `LoadingButtonThemeData`.

### Colours

Two strategies:

| `LoadingButtonColorStrategy` | Behaviour                                                                                  |
| ---------------------------- | ------------------------------------------------------------------------------------------ |
| `legacy` *(default)*         | `Theme.of(context).primaryColor` background, unconditional white foreground, hardcoded green/red. Not dark-mode safe, and it paints a filled background onto text and outlined buttons. |
| `material3`                  | Colours come from the ambient `ColorScheme`; container/on-container role pairs guarantee contrast in both brightnesses, and the idle state is left to your own `ButtonStyle`. |

```dart
LoadingButton(
  onPressed: () async => submit(),
  colorStrategy: LoadingButtonColorStrategy.material3,
  child: const Text('Scheme colours'),
)
```

`LoadingButtonColors` overrides individual states. A `null` field means "leave this
state to the button's own `ButtonStyle`".

```dart
LoadingButtonColors.fromScheme(Theme.of(context).colorScheme)  // M3 role pairs
LoadingButtonColors.traffic(Theme.of(context).brightness)      // tone-mapped green/red
LoadingButtonColors.legacy                                     // exactly the old colours
```

```dart
LoadingButton(
  onPressed: () async => submit(),
  colors: const LoadingButtonColors(
    loading: Color(0xFF303F9F),
    onLoading: Colors.white,
    success: Color(0xFF1B5E20),
    onSuccess: Colors.white,
    error: Color(0xFFB3261E),
    onError: Colors.white,
  ),
  child: const Text('Hand-picked'),
)
```

> 2.0.0 will default to `material3`.

For geometry, elevation, padding and text style there are two layers: pass a standard
Material `buttonStyle`, which is applied first, and let the package-specific `style`
(`LoadingButtonStyle`) and the state colours layer on top.

```dart
LoadingButton(
  type: ButtonType.filled,
  onPressed: () async => submit(),
  buttonStyle: FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  ),
  style: const LoadingButtonStyle(
    borderRadius: 24,
    elevation: 2,
    textStyle: TextStyle(fontWeight: FontWeight.w600),
  ),
  child: const Text('Styled'),
)
```

### Determinate progress

Pass `progress` in `0.0..1.0` (or `null` for indeterminate) and choose how it is shown:

| `LoadingProgressStyle` | Rendering                                            |
| ---------------------- | ---------------------------------------------------- |
| `indicator` *(default)* | The loading indicator becomes determinate           |
| `fill`                 | The background fills left to right, clipped to the button's shape |
| `both`                 | Both at once                                         |

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

When a `controller` is attached, `controller.progress` wins over the `progress`
argument. Orbs are indeterminate by design, so with `LoadingIndicator.orb()` prefer
`LoadingProgressStyle.fill`.

### Debounce and cooldown

```dart
LoadingButton(
  onPressed: () async => resend(),
  debounce: const Duration(milliseconds: 500),
  cooldown: const Duration(seconds: 30),
  child: const Text('Resend code'),
)
```

- `debounce` ignores a tap arriving within that window of the previously **accepted**
  tap.
- `cooldown` holds the button `disabled` for that long after a run finishes and its
  success/error window has elapsed, then returns it to `idle`. `controller.isCoolingDown`
  and `controller.cooldownRemaining` let you render a countdown. Cooldown rides on the
  reset timer, so it does nothing when `resetAfterDuration: false`; drive the wait with
  `controller.startCooldown(duration)` instead.

### Enabling, tooltips and focus

```dart
LoadingButton(
  enabled: _formValid,
  tooltip: _formValid ? null : 'Fill in every field first',
  focusNode: _focusNode,
  autofocus: true,
  onPressed: () async => submit(),
  child: const Text('Continue'),
)
```

`enabled: false` puts the button in `ActionState.disabled`, which is also reachable via
`controller.setEnabled(false)`.

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

On `LoadingButton`, the widget shown while loading is resolved in this order:

`loadingWidget` → `loadingText` → `indicator` → the theme's indicator → the package
default (a `CircularProgressIndicator`).

Note the second entry: **`loadingText` replaces the indicator rather than labelling
it.** A `LoadingButton` given a `loadingText` shows that text alone — no spinner, no
orb — so setting both `loadingText` and `indicator` renders only the text. The same
shape applies to `successWidget`/`successText` and `errorWidget`/`errorText`. To show
an indicator *and* a caption, build the pair yourself and pass it as `loadingWidget`:

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

### Custom transitions

```dart
LoadingButton(
  onPressed: () async => submit(),
  transitionBuilder: (Widget child, Animation<double> animation) =>
      ScaleTransition(scale: animation, child: child),
  child: const Text('Scales between states'),
)
```

The default is a cross fade over `animationDuration`.

### Reaching the state directly

A `LoadingButtonController` is usually the better tool, but `LoadingButtonState` is
public:

```dart
final GlobalKey<LoadingButtonState> key = GlobalKey<LoadingButtonState>();

LoadingButton(
  key: key,
  onPressed: () async => submit(),
  child: const Text('Submit'),
);

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
    .loadingText('Submitting…')
    .successText('Submitted')
    .errorText('Try again')
    .onFailure((Object error, StackTrace stack) => report(error, stack))
    .build()
```

Factories: `.elevated()`, `.filled()`, `.outlined()`, `.text()`, `.icon()`.

A builder is **mutable and single-use**. Create one builder, configure it, build once.
Two consequences of the mutability:

- A setter called *after* `build()` does not affect the widget that was already built —
  `build()` snapshots the configuration, so late changes are silently lost.
- If you called `.key(…)`, building twice returns two different widgets carrying that
  same key, which is an error if both are mounted at once. With no `.key(…)` call both
  widgets get a null key and mounting both is legal.

### LoadingButton properties

| Property               | Type                                                    | Default            |
| ---------------------- | ------------------------------------------------------- | ------------------ |
| `child`                | `Widget?`                                               | `null`             |
| `onPressed`            | `AsyncCallback?`                                        | `null`             |
| `type`                 | `ButtonType`                                            | `elevated`         |
| `loadingWidget`        | `Widget?`                                               | `null`             |
| `successWidget`        | `Widget?`                                               | `null`             |
| `errorWidget`          | `Widget?`                                               | `null`             |
| `loadingText`          | `String?` — **replaces** the indicator, see †            | `null`             |
| `successText`          | `String?` — **replaces** `successWidget`'s slot, see †   | `null`             |
| `errorText`            | `String?` — **replaces** `errorWidget`'s slot, see †     | `null`             |
| `indicator`            | `LoadingIndicator?`                                     | theme, then circular |
| `progress`             | `double?`                                               | `null`             |
| `progressStyle`        | `LoadingProgressStyle?`                                 | `indicator`        |
| `controller`           | `LoadingButtonController?`                              | `null`             |
| `sizing`               | `LoadingButtonSizing?`                                  | `legacy`           |
| `width` / `height`     | `double?`                                               | `null`             |
| `style`                | `LoadingButtonStyle?`                                   | `null`             |
| `buttonStyle`          | `ButtonStyle?`                                          | `null`             |
| `colors`               | `LoadingButtonColors?`                                  | from the strategy  |
| `colorStrategy`        | `LoadingButtonColorStrategy?`                           | `legacy`           |
| `animationDuration`    | `Duration?`                                             | `300ms`            |
| `successDuration`      | `Duration?`                                             | `2s`               |
| `errorDuration`        | `Duration?`                                             | `2s`               |
| `resetAfterDuration`   | `bool`                                                  | `true`             |
| `enabled`              | `bool`                                                  | `true`             |
| `debounce`             | `Duration?`                                             | none               |
| `cooldown`             | `Duration?`                                             | none               |
| `enableHapticFeedback` | `bool?`                                                 | `true`             |
| `focusNode`            | `FocusNode?`                                            | `null`             |
| `autofocus`            | `bool`                                                  | `false`            |
| `tooltip`              | `String?`                                               | `null`             |
| `transitionBuilder`    | `Widget Function(Widget, Animation<double>)?`           | cross fade         |
| `onSuccess`            | `VoidCallback?`                                         | `null`             |
| `onFailure`            | `void Function(Object, StackTrace)?`                    | `null`             |
| `onStateChanged`       | `void Function(ActionState)?`                           | `null`             |
| `onError`              | `Function(dynamic)?` — **deprecated**, use `onFailure`  | `null`             |

† `loadingText` / `successText` / `errorText` are not captions added beside the
indicator or icon — each one **replaces** the widget for that state. Setting
`loadingText` means the loading state shows only that text, even if you also passed an
`indicator`. They double as the state's accessible label. To show both, build the pair
yourself and pass it as `loadingWidget` / `successWidget` / `errorWidget`.

`ButtonType` is `elevated`, `filled`, `outlined`, `text` or `icon`.

## The AutoLoadingButton family

Thin wrappers over the stock Material buttons. They enter the loading state for exactly
as long as the async callback runs, then leave it — on **both** the success and the
failure path.

| Widget                      | Extra constructors                          |
| --------------------------- | ------------------------------------------- |
| `ElevatedAutoLoadingButton` | `.icon`                                     |
| `FilledAutoLoadingButton`   | `.icon`, `.tonal`, `.tonalIcon`             |
| `OutlinedAutoLoadingButton` | `.icon`                                     |
| `TextAutoLoadingButton`     | `.icon`                                     |
| `IconAutoLoadingButton`     | `.filled`, `.filledTonal`, `.outlined`      |

```dart
ElevatedAutoLoadingButton(
  onPressed: () async => submit(),
  loadingLabel: const Text('Submitting…'),
  child: const Text('Submit'),
)
```

```dart
FilledAutoLoadingButton.tonal(
  onPressed: () async => submit(),
  loadingLabel: const Text('Working…'),
  child: const Text('Tonal'),
)

OutlinedAutoLoadingButton(
  onPressed: () async => submit(),
  loadingLabel: const Text('Working…'),
  child: const Text('Outlined'),
)

// IconAutoLoadingButton has no child to label, so wrap it to keep an
// accessible name while the indicator is showing.
Semantics(
  label: 'Refresh',
  child: IconAutoLoadingButton(
    onPressed: () async => submit(),
    icon: const Icon(Icons.refresh),
    tooltip: 'Refresh',
  ),
)

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

| Parameter        | Meaning                                                                  |
| ---------------- | ------------------------------------------------------------------------ |
| `onPressed`      | `AsyncCallback?` — the button is busy until this future settles           |
| `onLongPress`    | `AsyncCallback?` — same treatment                                         |
| `loadingIcon`    | Replaces the indicator outright                                           |
| `indicator`      | A `LoadingIndicator`; falls back to the theme, then a spinner             |
| `loadingLabel`   | Text beside the indicator (not on `IconAutoLoadingButton`, which has no label slot). Omit it and the button shrinks to just the indicator — **and loses its accessible name for the whole loading window**, since the indicator replaces the child. Pass it, or wrap the button in your own `Semantics`. |
| `switchDuration` | The `AnimatedSize` transition as the button resizes (`kThemeAnimationDuration`) |

`IconAutoLoadingButton` additionally takes `selectedIcon` / `selectedLoadingIcon`
alongside `isSelected`.

### Triggering one from outside

Every widget in this family has a state class extending `AutoLoadingButtonState`, with
`doPress()` and `doLongPress()`. Both return the future of the run, so a caller that
awaits gets the error instead of it going unobserved:

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

Calling `doPress()` while a run is already in flight returns the **existing** future
rather than starting a second run. On the tap path — where the future is discarded — a
throwing callback is routed to `FlutterError.reportError` with package context.

## The XxxLoadingButton family

The same Material buttons, but **you** own the flag. Use these when the loading state
already lives in a bloc, a provider or a notifier.

`ElevatedLoadingButton`, `FilledLoadingButton`, `OutlinedLoadingButton` and
`TextLoadingButton`, each with `.icon` (and `FilledLoadingButton` also with `.tonal` /
`.tonalIcon`).

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

TextLoadingButton.icon(
  isLoading: _isLoading,
  onPressed: _submit,
  loadingLabel: const Text('Retrying…'),
  icon: const Icon(Icons.refresh),
  label: const Text('Retry'),
)
```

Every snippet here passes `loadingLabel`. That is deliberate: the indicator replaces
the child, so without a `loadingLabel` the button has no accessible name while busy.

`isLoading`, `onPressed` and `child` (or `icon` + `label`) are required. `onPressed`
here is a plain `VoidCallback?`, not an `AsyncCallback`. Unless `loadingClickable` is
true, the button is disabled while `isLoading`.

There is no `IconLoadingButton`; use `IconAutoLoadingButton` for an icon button.

## ArgonButton and ArgonTimerButton

`ArgonButton` animates its width down to a pill and shows a loader inside it. You drive
it with the `startLoading` / `stopLoading` callbacks handed to `onTap`:

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
  child: const Text(
    'Continue',
    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
  ),
)
```

`ArgonButtonState` has two values, `idle` and `busy`. A `null` `onTap` disables the
button. Both `startLoading` and `stopLoading` are safe to call after the button has been
disposed — a request completing after the user navigated away is the normal case.

`ArgonTimerButton` is the countdown variant: `loader` is a `Function(int seconds)`
builder, and `onTap` receives a `startTimer` function that takes the number of seconds.

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

`startTimer` throws an `ArgumentError` if handed a non-positive duration. Set
`initialTimer` to start the countdown as soon as the button mounts.

## Accessibility

### What `LoadingButton` does

The button semantics below are **`LoadingButton`'s alone**. The
`*AutoLoadingButton` and `*LoadingButton` families are thinner wrappers and publish no
semantics of their own — read
[Things to handle yourself](#things-to-handle-yourself) before relying on anything here
for those. (The orb and tooltip items are the exceptions: they apply wherever a
`ThinkingOrb` or a `tooltip` is used.)

- **Real Material buttons underneath.** `LoadingButton` renders an `ElevatedButton`,
  `FilledButton`, `OutlinedButton`, `TextButton` or `IconButton`, so it inherits the
  button role, keyboard activation, focus highlight and minimum tap target from the
  framework. `focusNode` and `autofocus` are passed through.
- **Transient state announcements.** In `loading`, `success` and `error` the child is
  wrapped in a `Semantics` node with `liveRegion: true`, so a screen reader announces
  the change without the user refocusing. The label is `loadingText` / `successText` /
  `errorText`, falling back to `'Loading'`, `'Success'` and `'Error'`.
- **No duplicate semantics.** The idle state adds no label of its own, so your `child`
  provides the button's accessible name. Earlier releases published a second `Semantics`
  button node here, which read the button out twice.
- **Orb labels.** `ThinkingOrb` publishes a per-state label from `kOrbSemanticLabels`.
  Override it with `semanticLabel`, or pass `''` to hide the orb from accessibility
  tools when a nearby label already describes it — which is what
  `LoadingIndicator.orb()` does inside a button.
- **Reduced motion.** `ThinkingOrb` honours `MediaQuery.disableAnimationsOf` and paints
  a representative still frame instead of animating.
- **Tooltips.** `LoadingButton.tooltip` and `IconAutoLoadingButton.tooltip` add a
  `Tooltip`, which is itself exposed to screen readers.
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

- **The other two families publish no loading semantics.** The
  `*AutoLoadingButton` and `*LoadingButton` families add no `Semantics` node and no
  `liveRegion`; nothing above applies to them. Worse, because the indicator *replaces*
  the child, the button's accessible name disappears for the whole loading window: a
  button that reads `label: "Send"` while idle exposes no label at all while busy.
  Passing `loadingLabel` is what keeps a name there — the label sits beside the
  indicator and becomes the button's accessible name while loading. If you need a name
  that differs from the visible label (or none is visible, as on an
  `IconAutoLoadingButton`), wrap the button in your own `Semantics`:

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

- **Localisation.** The fallback labels are English literals. Pass your own localised
  `loadingText` / `successText` / `errorText` and `semanticLabel`.
- **Text scaling.** The default `LoadingButtonSizing.legacy` is a fixed box that does
  **not** grow with the platform text scale, so long labels at large scales will clip.
  Use `LoadingButtonSizing.intrinsic()` if your labels must scale.
- **Contrast.** There is no high-contrast-specific handling. The default
  `LoadingButtonColorStrategy.legacy` paints unconditional white on
  `Theme.primaryColor`, which is not dark-mode safe; switch to `material3` (or supply
  `LoadingButtonColors.fromScheme`) for contrast-safe role pairs in both brightnesses.

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
  await tester.pump();                                // apply the state change
  await tester.pump(const Duration(milliseconds: 16)); // run out the cross fade

  expect(controller.state, ActionState.success);
});
```

- **Never `pumpAndSettle` around an orb.** It animates forever. Use
  `tester.pump(duration)`, or mount with `paused: true`.
- **Collapse the cross fade.** `animationDuration: Duration(milliseconds: 1)` keeps two
  children from overlapping in the `AnimatedSwitcher`, so your finders match exactly one
  widget.
- **Assert on the controller, not the pixels.** `controller.state`,
  `controller.progress` and `controller.lastError` are the stable surface.
- **Haptics are fire-and-forget.** The button never awaits the platform channel, so a
  press resolves normally on a test binding.
- **`enableHapticFeedback: false`** avoids noisy platform-channel calls entirely.
- **Success and error windows** are real timers. Advance past `successDuration` /
  `errorDuration` to observe the return to idle, or set `resetAfterDuration: false`.

## Platform support

Pure Dart and Flutter — no platform channels beyond `HapticFeedback`, no plugins, no
native code. Orbs are drawn with `CustomPainter` (no shaders, no image assets), so they
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

| Deprecated                                     | Replacement                                             |
| ---------------------------------------------- | ------------------------------------------------------- |
| `LoadingButton.onError`                        | `onFailure(Object error, StackTrace stack)`             |
| `LoadingButtonConfig`                          | `LoadingButtonThemeData` + `LoadingButtonTheme`         |
| `IconButtonLoading`                            | Compose your own `Row` of an `Icon` and a `Text`        |
| `buildChildWithIcon` / `buildChildWithIC`      | Same                                                    |
| `buildText`                                    | `Text(text, style: style)`                              |

```dart
// before
LoadingButton(
  onPressed: () async => submit(),
  onError: (dynamic error) => showError(error as Object),
  child: const Text('Old'),
)

// after
LoadingButton(
  onPressed: () async => submit(),
  onFailure: (Object error, StackTrace stack) => report(error, stack),
  child: const Text('New'),
)
```

Renamed in 1.1.0: the `ButtonStateExtension` extension is now `ActionStateExtension`.
Extension members resolve by member name, so `state.isLoading` and friends keep
compiling unchanged; only an explicit extension override
(`ButtonStateExtension(state).isIdle`) needs updating.

Also changed in 1.1.0: `ActionState.isInteractive` used to be an exact duplicate of
`isIdle`. It now means "a press would be accepted" — true for everything except
`loading` and `disabled`. Use `isIdle` for the old meaning.

See [MIGRATION.md](https://github.com/itsarvinddev/loading_icon_button/blob/master/MIGRATION.md)
and the [changelog](https://pub.dev/packages/loading_icon_button/changelog).

## Attribution

The `ThinkingOrb` engine is a Dart port of **thinking-orbs**, MIT licensed:

- Original concept and implementation: **[thinking-orbs](https://github.com/Jakubantalik/thinking-orbs)**
  by Jakub Antalik.
- Flutter port that this work builds on: **[thinking-orbs](https://github.com/iamEtornam/thinking-orbs)**
  by Bright Sunu.

Our Dart port is verified against upstream's published **golden vectors** — the exact
dot positions, radii and depths each state produces at given times — so the animations
match the originals numerically, not just by eye.

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

## Issues and feedback

File issues on the
[GitHub issue tracker](https://github.com/itsarvinddev/loading_icon_button/issues).

## License

MIT — see [LICENSE](https://github.com/itsarvinddev/loading_icon_button/blob/master/LICENSE).

**Package:** [loading_icon_button](https://pub.dev/packages/loading_icon_button)
**Repository:** [GitHub](https://github.com/itsarvinddev/loading_icon_button)
**Issues:** [Report issues](https://github.com/itsarvinddev/loading_icon_button/issues)
