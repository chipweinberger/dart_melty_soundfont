import 'dart:math';
import 'dart:typed_data';

import 'instrument_region.dart';
import 'lfo.dart';
import 'modulation_envelope.dart';
import 'oscillator.dart';
import 'preset_region.dart';
import 'region_pair.dart';
import 'soundfont_math.dart';
import 'volume_envelope.dart';

extension OscillatorRegionEx on Oscillator {
  void start1(Int16List data, InstrumentRegion region) {
    var regionPair = RegionPair(
      preset: PresetRegion.defaultPresetRegion(),
      instrument: region,
    );
    start2(data, regionPair);
  }

  void start2(Int16List data, RegionPair region) {
    start(
      data: data,
      loopMode: region.sampleModes(),
      sampleRate: region.instrument.sample.sampleRate,
      start: region.sampleStart(),
      end: region.sampleEnd(),
      startLoop: region.sampleStartLoop(),
      endLoop: region.sampleEndLoop(),
      rootKey: region.rootKey(),
      coarseTune: region.coarseTune(),
      fineTune: region.fineTune(),
      scaleTuning: region.scaleTuning(),
    );
  }
}

extension VolumeEnvelopeRegionEx on VolumeEnvelope {
  void start1(InstrumentRegion region, int key, int velocity) {
    var regionPair = RegionPair(
      preset: PresetRegion.defaultPresetRegion(),
      instrument: region,
    );
    start2(regionPair, key, velocity);
  }

  void start2(RegionPair region, int key, int velocity) {
    // If the release time is shorter than 10 ms, it will be clamped to 10 ms to avoid pop noise.

    var hold = region.holdVolumeEnvelope() *
        SoundFontMath.keyNumberToMultiplyingFactor(
          region.keyNumberToVolumeEnvelopeHold(),
          key,
        );

    var decay = region.decayVolumeEnvelope() *
        SoundFontMath.keyNumberToMultiplyingFactor(
          region.keyNumberToVolumeEnvelopeDecay(),
          key,
        );

    start(
      delay: region.delayVolumeEnvelope(),
      attack: region.attackVolumeEnvelope(),
      hold: hold,
      decay: decay,
      sustain: SoundFontMath.decibelsToLinear(-region.sustainVolumeEnvelope()),
      release: max(region.releaseVolumeEnvelope(), 0.01),
    );
  }
}

extension ModulationEnvelopeRegionEx on ModulationEnvelope {
  void start1(InstrumentRegion region, int key, int velocity) {
    var regionPair = RegionPair(
      preset: PresetRegion.defaultPresetRegion(),
      instrument: region,
    );
    start2(regionPair, key, velocity);
  }

  void start2(RegionPair region, int key, int velocity) {
    // According to the implementation of TinySoundFont,
    // the attack time should be adjusted by the velocity.
    var hold = region.holdModulationEnvelope() *
        SoundFontMath.keyNumberToMultiplyingFactor(
          region.keyNumberToModulationEnvelopeHold(),
          key,
        );

    var decay = region.decayModulationEnvelope() *
        SoundFontMath.keyNumberToMultiplyingFactor(
          region.keyNumberToModulationEnvelopeDecay(),
          key,
        );

    start(
      delay: region.delayModulationEnvelope(),
      attack: region.attackModulationEnvelope() * ((145.0 - velocity) / 144.0),
      hold: hold,
      decay: decay,
      sustain: 1.0 - region.sustainModulationEnvelope() / 100.0,
      release: region.releaseModulationEnvelope(),
    );
  }
}

extension LfoRegionEx on Lfo {
  void startVibrato1(InstrumentRegion region, int key, int velocity) {
    var regionPair = RegionPair(
      preset: PresetRegion.defaultPresetRegion(),
      instrument: region,
    );
    startVibrato2(regionPair, key, velocity);
  }

  void startVibrato2(RegionPair region, int key, int velocity) {
    start(region.delayVibratoLfo(), region.frequencyVibratoLfo());
  }

  void startModulation1(InstrumentRegion region, int key, int velocity) {
    var regionPair = RegionPair(
      preset: PresetRegion.defaultPresetRegion(),
      instrument: region,
    );
    startModulation2(regionPair, key, velocity);
  }

  void startModulation2(RegionPair region, int key, int velocity) {
    start(region.delayModulationLfo(), region.frequencyModulationLfo());
  }
}
