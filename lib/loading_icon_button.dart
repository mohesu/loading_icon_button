/// Loading buttons for Flutter, plus a family of animated "thinking orb"
/// indicators for AI and agent interfaces.
///
/// The package ships four button families:
///
/// * [LoadingButton] — a single widget with a built-in idle/loading/success/
///   error state machine, drivable by hand or through a
///   [LoadingButtonController].
/// * `XxxAutoLoadingButton` ([ElevatedAutoLoadingButton] and friends) — thin
///   wrappers over the Material buttons that enter the loading state for as
///   long as an async callback runs.
/// * `XxxLoadingButton` ([ElevatedLoadingButton] and friends) — the same
///   widgets with the loading state driven by a plain `isLoading` flag.
/// * [ArgonButton] and [ArgonTimerButton] — a button that collapses into its
///   loader, and a countdown variant.
///
/// Any of them can show a [ThinkingOrb] instead of a spinner via
/// [LoadingIndicator.orb].
library;

import 'dart:async' show Completer, Timer, unawaited;
import 'dart:math' show min;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show AsyncCallback;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import 'src/orbs/orb_presets.dart';
import 'src/orbs/thinking_orb.dart';

export 'src/orbs/orb_presets.dart' show OrbState, kOrbTierBreakpoint;
export 'src/orbs/thinking_orb.dart'
    show ThinkingOrb, OrbTheme, kOrbSemanticLabels;

part 'src/_common_components.dart';
part 'src/argon_button.dart';
part 'src/enum.dart';
part 'src/icon_button.dart';
part 'src/loading_button.dart';
part 'src/loading_button_builder.dart';
part 'src/material/elevated_loading_button.dart';
part 'src/material/filled_loading_button.dart';
part 'src/material/icon_loading_button.dart';
part 'src/material/outlined_loading_button.dart';
part 'src/material/text_loading_button.dart';
part 'src/models/loading_button_colors.dart';
part 'src/models/loading_button_config.dart';
part 'src/models/loading_button_controller.dart';
part 'src/models/loading_button_indicator.dart';
part 'src/models/loading_button_sizing.dart';
part 'src/models/loading_button_style.dart';
part 'src/models/loading_button_theme.dart';
