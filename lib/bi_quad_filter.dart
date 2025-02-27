import 'dart:math';
import 'synthesizer.dart';

class BiQuadFilter {
  final double resonancePeakOffset = 1.0 - (1.0 / sqrt(2.0));

  final Synthesizer synthesizer;

  bool _active = false;

  double _a0 = 0.0;
  double _a1 = 0.0;
  double _a2 = 0.0;
  double _a3 = 0.0;
  double _a4 = 0.0;

  double _x1 = 0.0;
  double _x2 = 0.0;

  double _y1 = 0.0;
  double _y2 = 0.0;

  BiQuadFilter(this.synthesizer);

  void _setCoefficients(
      double a0, double a1, double a2, double b0, double b1, double b2) {
    _a0 = b0 / a0;
    _a1 = b1 / a0;
    _a2 = b2 / a0;
    _a3 = a1 / a0;
    _a4 = a2 / a0;
  }

  void clearBuffer() {
    _x1 = 0;
    _x2 = 0;
    _y1 = 0;
    _y2 = 0;
  }

  void setLowPassFilter(double cutoffFrequency, double resonance) {
    if (cutoffFrequency < 0.499 * synthesizer.sampleRate) {
      _active = true;

      // This equation gives the Q value which makes the desired resonance peak.
      // The error of the resultant peak height is less than 3%.
      var q = resonance - resonancePeakOffset / (1 + 6 * (resonance - 1));

      var w = 2 * pi * cutoffFrequency / synthesizer.sampleRate;
      var cosw = cos(w);
      var alpha = sin(w) / (2 * q);

      var b0 = (1 - cosw) / 2;
      var b1 = 1 - cosw;
      var b2 = (1 - cosw) / 2;
      var a0 = 1 + alpha;
      var a1 = -2 * cosw;
      var a2 = 1 - alpha;

      _setCoefficients(a0, a1, a2, b0, b1, b2);
    } else {
      _active = false;
    }
  }

  void process(List<double> block) {
    if (_active) {
      for (var t = 0; t < block.length; t++) {
        var input = block[t];
        var output = (_a0 * input) +
            (_a1 * _x1) +
            (_a2 * _x2) -
            (_a3 * _y1) -
            (_a4 * _y2);

        _x2 = _x1;
        _x1 = input;
        _y2 = _y1;
        _y1 = output;

        block[t] = output;
      }
    } else {
      _x2 = block[block.length - 2];
      _x1 = block[block.length - 1];
      _y2 = _x2;
      _y1 = _x1;
    }
  }
}
