import 'soundfont_math.dart';
import 'loop_mode.dart';
import 'generator_type.dart';
import 'preset_region.dart';
import 'instrument_region.dart';

class RegionPair {
  final PresetRegion preset;
  final InstrumentRegion instrument;

  RegionPair({required this.preset, required this.instrument});

  int getGen(GeneratorType type) {
    return instrument.getGen(type) + preset.getGen(type);
  }

  int sampleStart() => instrument.sampleStart();

  int sampleEnd() => instrument.sampleEnd();

  int sampleStartLoop() => instrument.sampleStartLoop();

  int sampleEndLoop() => instrument.sampleEndLoop();

  int startAddressOffset() => instrument.startAddressOffset();

  int endAddressOffset() => instrument.endAddressOffset();

  int startLoopAddressOffset() => instrument.startLoopAddressOffset();

  int endLoopAddressOffset() => instrument.endLoopAddressOffset();

  int modulationLfoToPitch() => getGen(GeneratorType.modulationLfoToPitch);

  int vibratoLfoToPitch() => getGen(GeneratorType.vibratoLfoToPitch);

  int modulationEnvelopeToPitch() => getGen(GeneratorType.modulationEnvelopeToPitch);

  double initialFilterCutoffFrequency() =>
      SoundFontMath.centsToHertz(getGen(GeneratorType.initialFilterCutoffFrequency).toDouble());

  double initialFilterQ() => 0.1 * getGen(GeneratorType.initialFilterQ);

  int modulationLfoToFilterCutoffFrequency() => getGen(GeneratorType.modulationLfoToFilterCutoffFrequency);

  int modulationEnvelopeToFilterCutoffFrequency() => getGen(GeneratorType.modulationEnvelopeToFilterCutoffFrequency);

  double modulationLfoToVolume() => 0.1 * getGen(GeneratorType.modulationLfoToVolume);

  double chorusEffectsSend() => 0.1 * getGen(GeneratorType.chorusEffectsSend);

  double reverbEffectsSend() => 0.1 * getGen(GeneratorType.reverbEffectsSend);

  double pan() => 0.1 * getGen(GeneratorType.pan);

  double delayModulationLfo() => SoundFontMath.timecentsToSeconds(getGen(GeneratorType.delayModulationLfo).toDouble());

  double frequencyModulationLfo() =>
      SoundFontMath.centsToHertz(getGen(GeneratorType.frequencyModulationLfo).toDouble());

  double delayVibratoLfo() => SoundFontMath.timecentsToSeconds(getGen(GeneratorType.delayVibratoLfo).toDouble());

  double frequencyVibratoLfo() => SoundFontMath.centsToHertz(getGen(GeneratorType.frequencyVibratoLfo).toDouble());

  double delayModulationEnvelope() =>
      SoundFontMath.timecentsToSeconds(getGen(GeneratorType.delayModulationEnvelope).toDouble());

  double attackModulationEnvelope() =>
      SoundFontMath.timecentsToSeconds(getGen(GeneratorType.attackModulationEnvelope).toDouble());

  double holdModulationEnvelope() =>
      SoundFontMath.timecentsToSeconds(getGen(GeneratorType.holdModulationEnvelope).toDouble());

  double decayModulationEnvelope() =>
      SoundFontMath.timecentsToSeconds(getGen(GeneratorType.decayModulationEnvelope).toDouble());

  double sustainModulationEnvelope() => 0.1 * getGen(GeneratorType.sustainModulationEnvelope);

  double releaseModulationEnvelope() =>
      SoundFontMath.timecentsToSeconds(getGen(GeneratorType.releaseModulationEnvelope).toDouble());

  int keyNumberToModulationEnvelopeHold() => getGen(GeneratorType.keyNumberToModulationEnvelopeHold);

  int keyNumberToModulationEnvelopeDecay() => getGen(GeneratorType.keyNumberToModulationEnvelopeDecay);

  double delayVolumeEnvelope() =>
      SoundFontMath.timecentsToSeconds(getGen(GeneratorType.delayVolumeEnvelope).toDouble());

  double attackVolumeEnvelope() =>
      SoundFontMath.timecentsToSeconds(getGen(GeneratorType.attackVolumeEnvelope).toDouble());

  double holdVolumeEnvelope() => SoundFontMath.timecentsToSeconds(getGen(GeneratorType.holdVolumeEnvelope).toDouble());

  double decayVolumeEnvelope() =>
      SoundFontMath.timecentsToSeconds(getGen(GeneratorType.decayVolumeEnvelope).toDouble());

  double sustainVolumeEnvelope() => 0.1 * getGen(GeneratorType.sustainVolumeEnvelope);

  double releaseVolumeEnvelope() =>
      SoundFontMath.timecentsToSeconds(getGen(GeneratorType.releaseVolumeEnvelope).toDouble());

  int keyNumberToVolumeEnvelopeHold() => getGen(GeneratorType.keyNumberToVolumeEnvelopeHold);

  int keyNumberToVolumeEnvelopeDecay() => getGen(GeneratorType.keyNumberToVolumeEnvelopeDecay);

  double initialAttenuation() => 0.1 * getGen(GeneratorType.initialAttenuation);

  int coarseTune() => getGen(GeneratorType.coarseTune);

  int fineTune() => getGen(GeneratorType.fineTune) + instrument.sample.pitchCorrection;

  LoopMode sampleModes() => instrument.sampleModes();

  int scaleTuning() => getGen(GeneratorType.scaleTuning);

  int exclusiveClass() => instrument.exclusiveClass();

  int rootKey() => instrument.rootKey();

  // int KeyRangeStart => getGen(GeneratorParameterType.KeyRange) & 0xFF;
  // int KeyRangeEnd => (getGen(GeneratorParameterType.KeyRange) >> 8) & 0xFF;
  // int VelocityRangeStart => getGen(GeneratorParameterType.VelocityRange) & 0xFF;
  // int VelocityRangeEnd => (getGen(GeneratorParameterType.VelocityRange) >> 8) & 0xFF;
}
