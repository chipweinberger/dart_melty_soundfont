enum EnvelopeStage { delay, attack, hold, decay, release }

EnvelopeStage envelopeStageFromInt(int i) {
  switch (i) {
    case 0:
      return EnvelopeStage.delay;
    case 1:
      return EnvelopeStage.attack;
    case 2:
      return EnvelopeStage.hold;
    case 3:
      return EnvelopeStage.decay;
    case 4:
      return EnvelopeStage.release;
  }
  throw "invalid VoiceEnvStage $i";
}

int envelopeStageInt(EnvelopeStage s) {
  switch (s) {
    case EnvelopeStage.delay:
      return 0;
    case EnvelopeStage.attack:
      return 1;
    case EnvelopeStage.hold:
      return 2;
    case EnvelopeStage.decay:
      return 3;
    case EnvelopeStage.release:
      return 4;
  }
}
