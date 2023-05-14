import 'dart:math';

class Chorus {
  late final List<double> _bufferL;
  late final List<double> _bufferR;

  late final List<double> _delayTable;

  late final int _bufferIndex;

  late final int _delayTableIndexL;
  late final int _delayTableIndexR;

  Chorus({
    required int sampleRate,
    required double delay,
    required double depth,
    required double frequency,
  }) {
    _bufferL = List.filled((sampleRate * (delay + depth)).toInt() + 2, 0);
    _bufferR = List.filled((sampleRate * (delay + depth)).toInt() + 2, 0);

    _delayTable = List.filled((sampleRate / frequency).round(), 0);

    for (int t = 0; t < _delayTable.length; t++) {
      final phase = 2 * pi * t / _delayTable.length;
      _delayTable[t] = sampleRate * (delay + depth * sin(phase));
    }

    _bufferIndex = 0;

    _delayTableIndexL = 0;
    _delayTableIndexR = _delayTable.length ~/ 4;
  }

  void process({
    required List<double> inputLeft,
    required List<double> inputRight,
    required List<double> outputLeft,
    required List<double> outputRight,
  }) {
    for (var t = 0; t < outputLeft.length; t++) {
      {
        var position = _bufferIndex - _delayTable[_delayTableIndexL];
        if (position < 0) {
          position += _bufferL.length;
        }

        var index1 = position.toInt();
        var index2 = index1 + 1;

        if (index2 == _bufferL.length) {
          index2 = 0;
        }

        var x1 = _bufferL[index1];
        var x2 = _bufferL[index2];
        var a = position - index1;
        outputLeft[t] = x1 + a * (x2 - x1);

        _delayTableIndexL++;
        if (_delayTableIndexL == _delayTable.length) {
          _delayTableIndexL = 0;
        }
      }

      {
        var position = _bufferIndex - _delayTable[_delayTableIndexR];
        if (position < 0) {
          position += _bufferR.length;
        }

        var index1 = position.toInt();
        var index2 = index1 + 1;

        if (index2 == _bufferR.length) {
          index2 = 0;
        }

        var x1 = _bufferR[index1];
        var x2 = _bufferR[index2];
        var a = position - index1;
        outputRight[t] = x1 + a * (x2 - x1);

        _delayTableIndexR++;
        if (_delayTableIndexR == _delayTable.length) {
          _delayTableIndexR = 0;
        }
      }

      _bufferL[_bufferIndex] = inputLeft[t];
      _bufferR[_bufferIndex] = inputRight[t];
      _bufferIndex++;
      if (_bufferIndex == _bufferL.length) {
        _bufferIndex = 0;
      }
    }
  }

  void mute() {
    _bufferL.fillRange(0, _bufferL.length, 0);
    _bufferR.fillRange(0, _bufferR.length, 0);
  }
}
