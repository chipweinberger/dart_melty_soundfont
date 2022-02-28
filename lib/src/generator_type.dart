




enum GeneratorType
{
  startAddressOffset,
  endAddressOffset,
  startLoopAddressOffset,
  endLoopAddressOffset,
  startAddressCoarseOffset,
  modulationLfoToPitch,
  vibratoLfoToPitch,
  modulationEnvelopeToPitch,
  initialFilterCutoffFrequency,
  initialFilterQ,
  modulationLfoToFilterCutoffFrequency,
  modulationEnvelopeToFilterCutoffFrequency,
  endAddressCoarseOffset,
  modulationLfoToVolume,
  unused1,
  chorusEffectsSend,
  reverbEffectsSend,
  pan,
  unused2,
  unused3,
  unused4,
  delayModulationLfo,
  frequencyModulationLfo,
  delayVibratoLfo,
  frequencyVibratoLfo,
  delayModulationEnvelope,
  attackModulationEnvelope,
  holdModulationEnvelope,
  decayModulationEnvelope,
  sustainModulationEnvelope,
  releaseModulationEnvelope,
  keyNumberToModulationEnvelopeHold,
  keyNumberToModulationEnvelopeDecay,
  delayVolumeEnvelope,
  attackVolumeEnvelope,
  holdVolumeEnvelope,
  decayVolumeEnvelope,
  sustainVolumeEnvelope,
  releaseVolumeEnvelope,
  keyNumberToVolumeEnvelopeHold,
  keyNumberToVolumeEnvelopeDecay,
  instrument,
  reserved1,
  keyRange,
  velocityRange,
  startLoopAddressCoarseOffset,
  keyNumber,
  velocity,
  initialAttenuation,
  reserved2,
  endLoopAddressCoarseOffset,
  coarseTune,
  fineTune,
  sampleID,
  sampleModes,
  reserved3,
  scaleTuning,
  exclusiveClass,
  overridingRootKey,
  unused5,
  unusedEnd
}

GeneratorType generatorTypeFromInt(int v) {
  switch (v){
    case 0:  return GeneratorType.startAddressOffset;
    case 1:  return GeneratorType.endAddressOffset;
    case 2:  return GeneratorType.startLoopAddressOffset;
    case 3:  return GeneratorType.endLoopAddressOffset;
    case 4:  return GeneratorType.startAddressCoarseOffset;
    case 5:  return GeneratorType.modulationLfoToPitch;
    case 6:  return GeneratorType.vibratoLfoToPitch;
    case 7:  return GeneratorType.modulationEnvelopeToPitch;
    case 8:  return GeneratorType.initialFilterCutoffFrequency;
    case 9:  return GeneratorType.initialFilterQ;
    case 10: return GeneratorType.modulationLfoToFilterCutoffFrequency;
    case 11: return GeneratorType.modulationEnvelopeToFilterCutoffFrequency;
    case 12: return GeneratorType.endAddressCoarseOffset;
    case 13: return GeneratorType.modulationLfoToVolume;
    case 14: return GeneratorType.unused1;
    case 15: return GeneratorType.chorusEffectsSend;
    case 16: return GeneratorType.reverbEffectsSend;
    case 17: return GeneratorType.pan;
    case 18: return GeneratorType.unused2;
    case 19: return GeneratorType.unused3;
    case 20: return GeneratorType.unused4;
    case 21: return GeneratorType.delayModulationLfo;
    case 22: return GeneratorType.frequencyModulationLfo;
    case 23: return GeneratorType.delayVibratoLfo;
    case 24: return GeneratorType.frequencyVibratoLfo;
    case 25: return GeneratorType.delayModulationEnvelope;
    case 26: return GeneratorType.attackModulationEnvelope;
    case 27: return GeneratorType.holdModulationEnvelope;
    case 28: return GeneratorType.decayModulationEnvelope;
    case 29: return GeneratorType.sustainModulationEnvelope;
    case 30: return GeneratorType.releaseModulationEnvelope;
    case 31: return GeneratorType.keyNumberToModulationEnvelopeHold;
    case 32: return GeneratorType.keyNumberToModulationEnvelopeDecay;
    case 33: return GeneratorType.delayVolumeEnvelope;
    case 34: return GeneratorType.attackVolumeEnvelope;
    case 35: return GeneratorType.holdVolumeEnvelope;
    case 36: return GeneratorType.decayVolumeEnvelope;
    case 37: return GeneratorType.sustainVolumeEnvelope;
    case 38: return GeneratorType.releaseVolumeEnvelope;
    case 39: return GeneratorType.keyNumberToVolumeEnvelopeHold;
    case 40: return GeneratorType.keyNumberToVolumeEnvelopeDecay;
    case 41: return GeneratorType.instrument;
    case 42: return GeneratorType.reserved1;
    case 43: return GeneratorType.keyRange;
    case 44: return GeneratorType.velocityRange;
    case 45: return GeneratorType.startLoopAddressCoarseOffset;
    case 46: return GeneratorType.keyNumber;
    case 47: return GeneratorType.velocity;
    case 48: return GeneratorType.initialAttenuation;
    case 49: return GeneratorType.reserved2;
    case 50: return GeneratorType.endLoopAddressCoarseOffset;
    case 51: return GeneratorType.coarseTune;
    case 52: return GeneratorType.fineTune;
    case 53: return GeneratorType.sampleID;
    case 54: return GeneratorType.sampleModes;
    case 55: return GeneratorType.reserved3;
    case 56: return GeneratorType.scaleTuning;
    case 57: return GeneratorType.exclusiveClass;
    case 58: return GeneratorType.overridingRootKey;
    case 59: return GeneratorType.unused5;
    case 60: return GeneratorType.unusedEnd;
  }
  throw "unknown generator";
}

int generatorTypeToInt(GeneratorType t) {
  switch (t){
    case GeneratorType.startAddressOffset: return 0;
    case GeneratorType.endAddressOffset: return 1;
    case GeneratorType.startLoopAddressOffset: return 2;
    case GeneratorType.endLoopAddressOffset: return 3;
    case GeneratorType.startAddressCoarseOffset: return 4;
    case GeneratorType.modulationLfoToPitch: return 5;
    case GeneratorType.vibratoLfoToPitch: return 6;
    case GeneratorType.modulationEnvelopeToPitch: return 7;
    case GeneratorType.initialFilterCutoffFrequency: return 8;
    case GeneratorType.initialFilterQ: return 9;
    case GeneratorType.modulationLfoToFilterCutoffFrequency: return 10;
    case GeneratorType.modulationEnvelopeToFilterCutoffFrequency: return 11;
    case GeneratorType.endAddressCoarseOffset: return 12;
    case GeneratorType.modulationLfoToVolume: return 13;
    case GeneratorType.unused1: return 14;
    case GeneratorType.chorusEffectsSend: return 15;
    case GeneratorType.reverbEffectsSend: return 16;
    case GeneratorType.pan: return 17;
    case GeneratorType.unused2: return 18;
    case GeneratorType.unused3: return 19;
    case GeneratorType.unused4: return 20;
    case GeneratorType.delayModulationLfo: return 21;
    case GeneratorType.frequencyModulationLfo: return 22;
    case GeneratorType.delayVibratoLfo: return 23;
    case GeneratorType.frequencyVibratoLfo: return 24;
    case GeneratorType.delayModulationEnvelope: return 25;
    case GeneratorType.attackModulationEnvelope: return 26;
    case GeneratorType.holdModulationEnvelope: return 27;
    case GeneratorType.decayModulationEnvelope: return 28;
    case GeneratorType.sustainModulationEnvelope: return 29;
    case GeneratorType.releaseModulationEnvelope: return 30;
    case GeneratorType.keyNumberToModulationEnvelopeHold: return 31;
    case GeneratorType.keyNumberToModulationEnvelopeDecay: return 32;
    case GeneratorType.delayVolumeEnvelope: return 33;
    case GeneratorType.attackVolumeEnvelope: return 34;
    case GeneratorType.holdVolumeEnvelope: return 35;
    case GeneratorType.decayVolumeEnvelope: return 36;
    case GeneratorType.sustainVolumeEnvelope: return 37;
    case GeneratorType.releaseVolumeEnvelope: return 38;
    case GeneratorType.keyNumberToVolumeEnvelopeHold: return 39;
    case GeneratorType.keyNumberToVolumeEnvelopeDecay: return 40;
    case GeneratorType.instrument: return 41;
    case GeneratorType.reserved1: return 42;
    case GeneratorType.keyRange: return 43;
    case GeneratorType.velocityRange: return 44;
    case GeneratorType.startLoopAddressCoarseOffset: return 45;
    case GeneratorType.keyNumber: return 46;
    case GeneratorType.velocity: return 47;
    case GeneratorType.initialAttenuation: return 48;
    case GeneratorType.reserved2: return 49;
    case GeneratorType.endLoopAddressCoarseOffset: return 50;
    case GeneratorType.coarseTune: return 51;
    case GeneratorType.fineTune: return 52;
    case GeneratorType.sampleID: return 53;
    case GeneratorType.sampleModes: return 54;
    case GeneratorType.reserved3: return 55;
    case GeneratorType.scaleTuning: return 56;
    case GeneratorType.exclusiveClass: return 57;
    case GeneratorType.overridingRootKey: return 58;
    case GeneratorType.unused5: return 59;
    case GeneratorType.unusedEnd: return 60;
  }
}

