/// <summary>
/// Specifies how the synthesizer loops the sample.
/// </summary>
enum LoopMode {
  /// <summary>
  /// The sample will be played without loop.
  /// </summary>
  NoLoop(0),

  /// <summary>
  /// The sample will continuously loop.
  /// </summary>
  Continuous(1),

  /// <summary>
  /// The sample will loop until the note stops.
  /// </summary>
  LoopUntilNoteOff(3);

  const LoopMode(this.value);
  final int value;
}

LoopMode? loopModeFromInt(int value) {
  for (final item in LoopMode.values) {
    if (item.value == value) return item;
  }
  return null;
}
