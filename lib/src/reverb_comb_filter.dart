import 'dart:math';

class CombFilter {
  final List<double> buffer;

  int _bufferIndex;
  double _filterStore;

  double feedback;
  double _damp1;
  double _damp2;

  CombFilter({required int bufferSize})
      : buffer = List<double>.filled(bufferSize, 0.0),
        _bufferIndex = 0,
        _filterStore = 0.0,
        feedback = 0.0,
        _damp1 = 0.0,
        _damp2 = 0.0;

  void mute() {
    buffer.fillRange(0, buffer.length, 0);
    _filterStore = 0.0;
  }

  double getDamp() => _damp1;

  void setDamp(double v) {
    _damp1 = v;
    _damp2 = 1.0 - v;
  }

  void process(List<double> inputBlock, List<double> outputBlock) {
    int blockIndex = 0;
    while (blockIndex < outputBlock.length) {
      if (_bufferIndex == buffer.length) {
        _bufferIndex = 0;
      }

      int srcRem = buffer.length - _bufferIndex;
      int dstRem = outputBlock.length - blockIndex;
      int rem = min(srcRem, dstRem);

      for (int t = 0; t < rem; t++) {
        int blockPos = blockIndex + t;
        int bufferPos = _bufferIndex + t;

        double input = inputBlock[blockPos];

        // The following ifs are to avoid performance problem due to denormalized number.
        // The original implementation uses unsafe cast to detect denormalized number.
        // I tried to reproduce the original implementation using Unsafe.As,
        // but the simple Math.Abs version was faster according to some benchmarks.

        double output = buffer[bufferPos];
        if (output.abs() < 1.0E-6) {
          output = 0.0;
        }

        _filterStore = (output * _damp2) + (_filterStore * _damp1);

        if (_filterStore.abs() < 1.0E-6) {
          _filterStore = 0.0;
        }

        buffer[bufferPos] = input + (_filterStore * feedback);
        outputBlock[blockPos] += output;
      }

      _bufferIndex += rem;

      blockIndex += rem;
    }
  }
}
