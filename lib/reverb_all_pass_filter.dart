import 'dart:math';
import 'dart:typed_data';

class AllPassFilter {
  final Float32List buffer;

  int _bufferIndex;

  // feedback is public
  double feedback;

  AllPassFilter({required int bufferSize})
      : buffer = Float32List(bufferSize),
        _bufferIndex = 0,
        feedback = 0.0;

  void mute() {
    buffer.fillRange(0, buffer.length, 0.0);
  }

  void process(Float32List block) {
    int blockIndex = 0;
    while (blockIndex < block.length) {
      if (_bufferIndex == buffer.length) {
        _bufferIndex = 0;
      }

      int srcRem = buffer.length - _bufferIndex;
      int dstRem = block.length - blockIndex;
      int rem = min(srcRem, dstRem);

      for (int t = 0; t < rem; t++) {
        int blockPos = blockIndex + t;
        int bufferPos = _bufferIndex + t;

        double input = block[blockPos];

        double bufout = buffer[bufferPos];
        if (bufout.abs() < 1.0E-6) {
          bufout = 0.0;
        }

        block[blockPos] = bufout - input;
        buffer[bufferPos] = input + (bufout * feedback);
      }

      _bufferIndex += rem;
      blockIndex += rem;
    }
  }
}
