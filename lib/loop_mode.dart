/// Specifies how the synthesizer loops the sample.
enum LoopMode {
  /// The sample will be played without loop.
  noLoop,

  /// The sample will continuously loop.
  continuous,

  /// The sample will loop until the note stops.
  loopUntilNoteOff
}

LoopMode loopModeFromInt(int i) {
  switch (i) {
    case 0:
      return LoopMode.noLoop;
    case 1:
      return LoopMode.continuous;
    case 3:
      return LoopMode.loopUntilNoteOff;
  }
  throw 'invalid loop mode';
}

int loopModeToInt(LoopMode v) {
  switch (v) {
    case LoopMode.noLoop:
      return 0;
    case LoopMode.continuous:
      return 1;
    case LoopMode.loopUntilNoteOff:
      return 3;
  }
}
