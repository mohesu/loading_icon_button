// Mode key to geometry builder.
//
// Kept separate from the presets so the mapping is one obvious table rather
// than a switch buried in the painter.
import 'orb_core.dart';
import 'orb_presets.dart';
import 'modes/orb_mode_braid.dart';
import 'modes/orb_mode_lattice.dart';
import 'modes/orb_mode_morph.dart';
import 'modes/orb_mode_orbits.dart';
import 'modes/orb_mode_ribbon.dart';
import 'modes/orb_mode_web.dart';

/// The portable surface: pure geometry, no canvas and no widgets.
const Map<OrbMode, OrbModeFrame> kOrbModeFrames = <OrbMode, OrbModeFrame>{
  OrbMode.orbits: frameOrbits,
  OrbMode.globe: frameGlobe,
  OrbMode.rubik: frameRubik,
  OrbMode.wave: frameWave,
  OrbMode.web: frameWeb,
  OrbMode.braid: frameBraid,
  OrbMode.ribbon: frameRibbon,
  // `ring` shares ribbon's geometry — the `faceOn` profile flag switches it.
  OrbMode.ring: frameRibbon,
  OrbMode.morph: frameMorph,
};

/// The frame time, in post-speed units, shown when animations are disabled.
///
/// Most modes read well at any instant, but `morph` spends part of its cycle
/// mid-transition between two shapes; it gets a time inside a hold so the
/// static frame is a formed circle rather than a half-morphed blob.
const Map<OrbMode, double> kOrbStaticFrameTime = <OrbMode, double>{
  OrbMode.morph: 0.7,
};

/// Default static frame time for modes with no entry in [kOrbStaticFrameTime].
const double kOrbDefaultStaticFrameTime = 1.7;
