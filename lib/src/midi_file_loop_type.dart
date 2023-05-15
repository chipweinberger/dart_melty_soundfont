enum MidiFileLoopType {
  /// <summary>
  /// No special loop extension.
  /// </summary>
  None(0),

  /// <summary>
  /// The RPG Maker style loop.
  /// CC #111 will be the loop start point.
  /// </summary>
  RpgMaker(1),

  /// <summary>
  /// The Incredible Machine style loop.
  /// CC #110 and #111 will be the loop start point and end point, respectively.
  /// </summary>
  IncredibleMachine(2),

  /// <summary>
  /// The Final Fantasy style loop.
  /// CC #116 and #117 will be the loop start point and end point, respectively.
  /// </summary>
  FinalFantasy(3);

  const MidiFileLoopType(this.value);
  final int value;
}
