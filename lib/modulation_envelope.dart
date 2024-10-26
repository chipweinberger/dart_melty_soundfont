
import 'soundfont_math.dart';
import 'synthesizer.dart';
import 'envelope_stage.dart';

import 'dart:math';


class ModulationEnvelope
{
    final Synthesizer synthesizer;

    double _attackSlope = 0.0;
    double _decaySlope = 0.0;
    double _releaseSlope = 0.0;

    double _attackStartTime = 0.0;
    double _holdStartTime = 0.0;
    double _decayStartTime = 0.0;

    double _decayEndTime = 0.0;
    double _sustainLevel = 0.0;

    double _releaseEndTime = 0.0;
    double _releaseLevel = 0.0;

    int _processedSampleCount = 0;
    EnvelopeStage _stage = EnvelopeStage.delay;
    double _value = 0;

    ModulationEnvelope(this.synthesizer);

    void start({required double delay, 
                required double attack, 
                required double hold, 
                required double decay, 
                required double sustain, 
                required double release})
    {
      _attackSlope = 1.0 / attack;
      _decaySlope = 1.0 / decay;
      _releaseSlope = 1.0 / release;
      _attackStartTime = delay;
      _holdStartTime =   delay + attack;
      _decayStartTime =  delay + attack + hold;
      _decayEndTime =    delay + attack + hold + decay;
      _releaseEndTime = release;
      _sustainLevel = sustain.clamp(0.0, 1.0);
      _releaseLevel = 0;
      _processedSampleCount = 0;
      _stage = EnvelopeStage.delay;
      _value = 0;

      _process(0);
    }

    void release()
    {
        _stage = EnvelopeStage.release;
        _releaseEndTime += _processedSampleCount / synthesizer.sampleRate;
        _releaseLevel = _value;
    }

    bool process()
    {
        return _process(synthesizer.blockSize);
    }

    bool _process(int sampleCount)
    {
        _processedSampleCount += sampleCount;

        double currentTime = _processedSampleCount / synthesizer.sampleRate;

        while (envelopeStageInt(_stage) <= envelopeStageInt(EnvelopeStage.hold))
        {
            double endTime;

            switch (_stage)
            {
                case EnvelopeStage.delay:
                    endTime = _attackStartTime;
                    break;

                case EnvelopeStage.attack:
                    endTime = _holdStartTime;
                    break;

                case EnvelopeStage.hold:
                    endTime = _decayStartTime;
                    break;

                default:
                    throw "Invalid envelope stage.";
            }

            if (currentTime < endTime)
            {
                break;
            }
            else
            {
              int stageInt = envelopeStageInt(_stage);
              _stage = envelopeStageFromInt(stageInt + 1);
            }
        }

        switch (_stage)
        {
            case EnvelopeStage.delay:
                _value = 0;
                return true;

            case EnvelopeStage.attack:
                _value = _attackSlope * (currentTime - _attackStartTime);
                return true;

            case EnvelopeStage.hold:
                _value = 1;
                return true;

            case EnvelopeStage.decay:
                _value = max(_decaySlope * (_decayEndTime - currentTime), _sustainLevel);
                return _value > SoundFontMath.nonAudible;

            case EnvelopeStage.release:
                _value = max(_releaseLevel * _releaseSlope * (_releaseEndTime - currentTime), 0.0);
                return _value > SoundFontMath.nonAudible;

            default:
                throw "Invalid envelope stage.";
        }
    }

    double value() => _value;
}

