
import 'dart:core';
import 'dart:math';

int castToByte(int v) {
  int m = v & 0xFF;
  if (m >= 128){
    // handle two's compliment
    m = -128 + (m - 128);
  }
  return m;
}

int castToShort(int v) {
  int m = v & 0xFFFF;
  if (m >= 32768){
    // handle two's compliment
    m = -32768 + (m - 32768);
  }
  return m;
}

class SoundFontMath
{
    static double halfPi = pi / 2;

    static double nonAudible = 1.0E-3;

    static double logNonAudible = log(1.0E-3);

    static double log10(num x) {
      return log(x) / ln10;
    }

    static double timecentsToSeconds(double x)
    {
        return pow(2.0, (1.0 / 1200.0) * x).toDouble();
    }

    static double centsToHertz(double x)
    {
        return 8.176 * pow(2.0, (1.0 / 1200.0) * x);
    }

    static double centsToMultiplyingFactor(double x)
    {
        return pow(2.0, (1.0 / 1200.0) * x).toDouble();
    }

    static double decibelsToLinear(double x)
    {
        return pow(10.0, 0.05 * x).toDouble();
    }

    static double linearToDecibels(double x)
    {
        return 20.0 * log10(x);
    }

    static double keyNumberToMultiplyingFactor(int cents, int key)
    {
        return timecentsToSeconds(cents * (60.0 - key));
    }

    static double expCutoff(double x)
    {
        if (x < logNonAudible)
        {
            return 0.0;
        }
        else
        {
            return exp(x);
        }
    }
}

