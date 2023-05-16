import 'reverb_all_pass_filter.dart';
import 'reverb_comb_filter.dart';

// This reverb implementation is based on Freeverb, a domain reverb
// implementation by Jezar at Dreampoint.

int scaleTuning(int sampleRate, int tuning) {
  return (sampleRate / 44100 * tuning).round().toInt();
}

class Reverb {
  static const double fixedGain = 0.015;
  static const double scaleWet = 3;
  static const double scaleDamp = 0.4;
  static const double scaleRoom = 0.28;
  static const double offsetRoom = 0.7;
  static const double initialRoom = 0.5;
  static const double initialDamp = 0.5;
  static const double initialWet = 1.0 / scaleWet;
  static const double initialWidth = 1;
  static const int stereoSpread = 23;

  static const int cfTuningL1 = 1116;
  static const int cfTuningR1 = 1116 + stereoSpread;
  static const int cfTuningL2 = 1188;
  static const int cfTuningR2 = 1188 + stereoSpread;
  static const int cfTuningL3 = 1277;
  static const int cfTuningR3 = 1277 + stereoSpread;
  static const int cfTuningL4 = 1356;
  static const int cfTuningR4 = 1356 + stereoSpread;
  static const int cfTuningL5 = 1422;
  static const int cfTuningR5 = 1422 + stereoSpread;
  static const int cfTuningL6 = 1491;
  static const int cfTuningR6 = 1491 + stereoSpread;
  static const int cfTuningL7 = 1557;
  static const int cfTuningR7 = 1557 + stereoSpread;
  static const int cfTuningL8 = 1617;
  static const int cfTuningR8 = 1617 + stereoSpread;
  static const int apfTuningL1 = 556;
  static const int apfTuningR1 = 556 + stereoSpread;
  static const int apfTuningL2 = 441;
  static const int apfTuningR2 = 441 + stereoSpread;
  static const int apfTuningL3 = 341;
  static const int apfTuningR3 = 341 + stereoSpread;
  static const int apfTuningL4 = 225;
  static const int apfTuningR4 = 225 + stereoSpread;

  final List<CombFilter> cfsL;
  final List<CombFilter> cfsR;
  final List<AllPassFilter> apfsL;
  final List<AllPassFilter> apfsR;

  double _gain = 0;
  double _roomSize = 0;
  double _roomSize1 = 0;
  double _damp = 0;
  double _damp1 = 0;
  double _wet = 0;
  double _wet1 = 0;
  double _wet2 = 0;
  double _width = 0;

  Reverb(
      {required this.cfsL,
      required this.cfsR,
      required this.apfsL,
      required this.apfsR});

  factory Reverb.withSampleRate(int sampleRate) {
    List<CombFilter> cfsL = [
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningL1)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningL2)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningL3)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningL4)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningL5)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningL6)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningL7)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningL8))
    ];

    List<CombFilter> cfsR = [
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningR1)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningR2)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningR3)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningR4)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningR5)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningR6)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningR7)),
      CombFilter(bufferSize: scaleTuning(sampleRate, cfTuningR8))
    ];

    List<AllPassFilter> apfsL = [
      AllPassFilter(bufferSize: scaleTuning(sampleRate, apfTuningL1)),
      AllPassFilter(bufferSize: scaleTuning(sampleRate, apfTuningL2)),
      AllPassFilter(bufferSize: scaleTuning(sampleRate, apfTuningL3)),
      AllPassFilter(bufferSize: scaleTuning(sampleRate, apfTuningL4))
    ];

    List<AllPassFilter> apfsR = [
      AllPassFilter(bufferSize: scaleTuning(sampleRate, apfTuningR1)),
      AllPassFilter(bufferSize: scaleTuning(sampleRate, apfTuningR2)),
      AllPassFilter(bufferSize: scaleTuning(sampleRate, apfTuningR3)),
      AllPassFilter(bufferSize: scaleTuning(sampleRate, apfTuningR4))
    ];

    for (AllPassFilter apf in apfsL) {
      apf.feedback = 0.5;
    }

    for (AllPassFilter apf in apfsR) {
      apf.feedback = 0.5;
    }

    Reverb r = Reverb(cfsL: cfsL, cfsR: cfsR, apfsL: apfsL, apfsR: apfsR);

    r.setWet(initialWet);
    r.setRoomSize(initialRoom);
    r.setDamp(initialDamp);
    r.setWidth(initialWidth);

    return r;
  }

  void process(
      List<double> input, List<double> outputLeft, List<double> outputRight) {
    outputLeft.fillRange(0, outputLeft.length, 0.0);
    outputRight.fillRange(0, outputRight.length, 0.0);

    for (CombFilter cf in cfsL) {
      cf.process(input, outputLeft);
    }

    for (AllPassFilter apf in apfsL) {
      apf.process(outputLeft);
    }

    for (CombFilter cf in cfsR) {
      cf.process(input, outputRight);
    }

    for (AllPassFilter apf in apfsR) {
      apf.process(outputRight);
    }

    // With the default settings, we can skip this part.
    if (1.0 - _wet1 > 1.0E-3 || _wet2 > 1.0E-3) {
      for (int t = 0; t < input.length; t++) {
        double left = outputLeft[t];
        double right = outputRight[t];
        outputLeft[t] = left * _wet1 + right * _wet2;
        outputRight[t] = right * _wet1 + left * _wet2;
      }
    }
  }

  void mute() {
    for (CombFilter cf in cfsL) {
      cf.mute();
    }

    for (CombFilter cf in cfsR) {
      cf.mute();
    }

    for (AllPassFilter apf in apfsL) {
      apf.mute();
    }

    for (AllPassFilter apf in apfsR) {
      apf.mute();
    }
  }

  void _update() {
    _wet1 = _wet * (_width / 2.0 + 0.5);
    _wet2 = _wet * ((1.0 - _width) / 2.0);

    _roomSize1 = _roomSize;
    _damp1 = _damp;
    _gain = fixedGain;

    for (CombFilter cf in cfsL) {
      cf.feedback = _roomSize1;
      cf.setDamp(_damp1);
    }

    for (CombFilter cf in cfsR) {
      cf.feedback = _roomSize1;
      cf.setDamp(_damp1);
    }
  }

  double inputGain() => _gain;

  double getRoomSize() {
    return (_roomSize - offsetRoom) / scaleRoom;
  }

  void setRoomSize(double value) {
    _roomSize = (value * scaleRoom) + offsetRoom;
    _update();
  }

  double getDamp() {
    return _damp / scaleDamp;
  }

  void setDamp(double value) {
    _damp = value * scaleDamp;
    _update();
  }

  double getWet() {
    return _wet / scaleWet;
  }

  void setWet(double value) {
    _wet = value * scaleWet;
    _update();
  }

  double getWidth() {
    return _width;
  }

  void setWidth(double value) {
    _width = value;
    _update();
  }
}
