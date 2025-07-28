import 'dart:math';
import 'dart:typed_data';

class Chorus {
  final Float32List _bufferL;
  final Float32List _bufferR;

  final Float32List _delayTable;

  int _bufferIndexL;
  int _bufferIndexR;

  int _delayTableIndexL;
  int _delayTableIndexR;

  Chorus(
      {required Float32List bufferL,
      required Float32List bufferR,
      required Float32List delayTable,
      required int bufferIndexL,
      required int bufferIndexR,
      required int delayTableIndexL,
      required int delayTableIndexR})
      : _bufferL = bufferL,
        _bufferR = bufferR,
        _delayTable = delayTable,
        _bufferIndexL = bufferIndexL,
        _bufferIndexR = bufferIndexR,
        _delayTableIndexL = delayTableIndexL,
        _delayTableIndexR = delayTableIndexR;

  factory Chorus.create(
      {required int sampleRate, required double delay, required double depth, required double frequency}) {
    Float32List delayTable = Float32List((sampleRate / frequency).round());

    for (var t = 0; t < delayTable.length; t++) {
      var phase = 2 * pi * t / delayTable.length;
      delayTable[t] = sampleRate * (delay + depth * sin(phase));
    }

    int sampleCount = ((sampleRate * (delay + depth)) + 2).toInt();

    return Chorus(
        bufferL: Float32List(sampleCount),
        bufferR: Float32List(sampleCount),
        delayTable: delayTable,
        bufferIndexL: 0,
        bufferIndexR: 0,
        delayTableIndexL: 0,
        delayTableIndexR: delayTable.length ~/ 4);
  }

  void process(
      {required Float32List inputLeft,
      required Float32List inputRight,
      required Float32List outputLeft,
      required Float32List outputRight}) {
    for (int t = 0; t < outputLeft.length; t++) {
      double position = _bufferIndexL - _delayTable[_delayTableIndexL];
      if (position < 0.0) {
        position += _bufferL.length;
      }

      int index1 = position.toInt();
      int index2 = index1 + 1;

      if (index2 == _bufferL.length) {
        index2 = 0;
      }

      double x1 = _bufferL[index1];
      double x2 = _bufferL[index2];
      double a = position - index1;
      outputLeft[t] = x1 + a * (x2 - x1);

      _bufferL[_bufferIndexL] = inputLeft[t];
      _bufferIndexL++;
      if (_bufferIndexL == _bufferL.length) {
        _bufferIndexL = 0;
      }

      _delayTableIndexL++;
      if (_delayTableIndexL == _delayTable.length) {
        _delayTableIndexL = 0;
      }
    }

    for (int t = 0; t < outputRight.length; t++) {
      double position = _bufferIndexR - _delayTable[_delayTableIndexR];
      if (position < 0.0) {
        position += _bufferR.length;
      }

      int index1 = position.toInt();
      int index2 = index1 + 1;

      if (index2 == _bufferR.length) {
        index2 = 0;
      }

      double x1 = _bufferR[index1];
      double x2 = _bufferR[index2];
      double a = position - index1;
      outputRight[t] = x1 + a * (x2 - x1);

      _bufferR[_bufferIndexR] = inputRight[t];
      _bufferIndexR++;
      if (_bufferIndexR == _bufferR.length) {
        _bufferIndexR = 0;
      }

      _delayTableIndexR++;
      if (_delayTableIndexR == _delayTable.length) {
        _delayTableIndexR = 0;
      }
    }
  }

  void mute() {
    _bufferL.fillRange(0, _bufferL.length, 0.0);
    _bufferR.fillRange(0, _bufferR.length, 0.0);
  }
}
