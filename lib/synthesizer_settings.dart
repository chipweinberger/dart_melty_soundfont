/// Specifies a set of parameters for synthesis.
class SynthesizerSettings {
  final int sampleRate;
  final int blockSize;
  final int maximumPolyphony;
  final bool enableReverbAndChorus;

  SynthesizerSettings(
      {int sampleRate = 44100,
      int blockSize = 64,
      int maximumPolyphony = 64,
      this.enableReverbAndChorus = true})
      : sampleRate = checkSampleRate(sampleRate),
        blockSize = checkBlockSize(blockSize),
        maximumPolyphony = checkMaximumPolyphony(maximumPolyphony);

  static int checkSampleRate(int value) {
    if (!(16000 <= value && value <= 192000)) {
      throw "The sample rate must be between 16000 and 192000.";
    }

    return value;
  }

  static int checkBlockSize(int value) {
    if (!(8 <= value && value <= 1024)) {
      throw "The block size must be between 8 and 1024.";
    }

    return value;
  }

  static int checkMaximumPolyphony(int value) {
    if (!(8 <= value && value <= 256)) {
      throw "The maximum number of polyphony must be between 8 and 256.";
    }

    return value;
  }
}
