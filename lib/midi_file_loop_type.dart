/// <summary>
/// Specifies the non-standard loop extension for MIDI files.
/// </summary>
enum MidiFileLoopType
{
    /// <summary>
    /// No loop extension is used.
    /// </summary>
    none,

    /// <summary>
    /// The RPG Maker style loop.
    /// CC #111 will be the loop start point.
    /// </summary>
    rpgMaker,

    /// <summary>
    /// The Incredible Machine style loop.
    /// CC #110 and #111 will be the start and end points of the loop.
    /// </summary>
    incredibleMachine,

    /// <summary>
    /// The Final Fantasy style loop.
    /// CC #116 and #117 will be the start and end points of the loop.
    /// </summary>
    finalFantasy
}