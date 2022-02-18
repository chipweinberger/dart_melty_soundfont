

import 'dart:io';
import 'dart:math';

import 'array_int16.dart';
import 'synthesizer.dart';
import 'loop_mode.dart';

class Oscillator
{
    final Synthesizer synthesizer;

    ArrayInt16 _data = ArrayInt16.empty();
    LoopMode _loopMode = LoopMode.noLoop;
    int _end = 0;
    int _startLoop = 0;
    int _endLoop = 0;
    int _rootKey = 0;

    double _tune = 0;
    double _pitchChangeScale = 0;
    double _sampleRateRatio = 0;

    bool _looping = false;

    double _position = 0;

    Oscillator(this.synthesizer);

    void start({required ArrayInt16 data, 
                required LoopMode loopMode, 
                required int sampleRate, 
                required int start, 
                required int end, 
                required int startLoop, 
                required int endLoop, 
                required int rootKey, 
                required int coarseTune, 
                required int fineTune, 
                required int scaleTuning})
    {
      _data = data;
      _loopMode = loopMode;
      _end = end;
      _startLoop = startLoop;
      _endLoop = endLoop;
      _rootKey = rootKey;

      _tune = coarseTune + 0.01 * fineTune;
      _pitchChangeScale = 0.01 * scaleTuning;
      _sampleRateRatio = sampleRate / synthesizer.sampleRate;

      if (loopMode == LoopMode.noLoop)
      {
          _looping = false;
      }
      else
      {
          _looping = true;
      }

      _position = start.toDouble();
    }

    void release()
    {
        if (_loopMode == LoopMode.loopUntilNoteOff)
        {
            _looping = false;
        }
    }

    bool process(List<double> block, double pitch)
    {
        double pitchChange = _pitchChangeScale * (pitch - _rootKey) + _tune;
        double pitchRatio = _sampleRateRatio * pow(2, pitchChange / 12);
        return _fillBlock(block, pitchRatio);
    }

    bool _fillBlock(List<double> block, double pitchRatio)
    {
        if (_looping)
        {
            return _fillBlockContinuous(block, pitchRatio);
        }
        else
        {
            return _fillBlockNoLoop(block, pitchRatio);
        }
    }

    bool _fillBlockNoLoop(List<double> block, double pitchRatio)
    {
        for (var t = 0; t < block.length; t++)
        {
            int index = _position.toInt();

            if (index >= _end)
            {
                if (t > 0)
                {
                  // clear slice
                  block.fillRange(t, block.length - t, 0.0);
                  return true;
                }
                else
                {
                    return false;
                }
            }

            int x1 = _data[index];
            int x2 = _data[index + 1];
            double a = _position - index;

            block[t] = (x1 + a * (x2 - x1)) / 32768;

            _position += pitchRatio;
        }

        return true;
    }

    bool _fillBlockContinuous(List<double> block, double pitchRatio)
    {
        double endLoopPosition = _endLoop.toDouble();

        int loopLength = _endLoop - _startLoop;

        for (var t = 0; t < block.length; t++)
        {
            if (_position >= endLoopPosition)
            {
                _position -= loopLength;
            }

            int index1 = _position.toInt();
            int index2 = index1 + 1;

            if (index2 >= _endLoop)
            {
                index2 -= loopLength;
            }

            int x1 = _data[index1];
            int x2 = _data[index2];
            double a = _position - index1;

            block[t] = (x1 + a * (x2 - x1)) / 32768;

            _position += pitchRatio;
        }

        return true;
    }
}

