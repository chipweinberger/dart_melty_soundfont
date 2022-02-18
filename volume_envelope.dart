
import 'soundfont_math.dart';
import 'synthesizer.dart';
import 'envelope_stage.dart';

import 'dart:math';

class VolumeEnvelope
{
    final Synthesizer synthesizer;

    double _attackSlope = 0.0;
    double _decaySlope = 0.0;
    double _releaseSlope = 0.0;

    double _attackStartTime = 0.0;
    double _holdStartTime = 0.0;
    double _decayStartTime = 0.0;
    double _releaseStartTime = 0.0;

    double _sustainLevel = 0.0;
    double _releaseLevel = 0.0;

    int _processedSampleCount = 0;
    EnvelopeStage _stage = EnvelopeStage.delay;
    double _value = 0;

    double _priority = 0.0;

    VolumeEnvelope(this.synthesizer);

    void start({required double delay, 
                required double attack, 
                required double hold, 
                required double decay, 
                required double sustain, 
                required double release})
    {
        _attackSlope = 1 / attack;
        _decaySlope = -9.226 / decay;
        _releaseSlope = -9.226 / release;
        _attackStartTime = delay;
        _holdStartTime = delay + attack;
        _decayStartTime = delay + attack + hold;
        _releaseStartTime = 0;
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
        _releaseStartTime = _processedSampleCount / synthesizer.sampleRate;
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
                _priority = 4.0 + _value;
                return true;

            case EnvelopeStage.attack:
                _value = _attackSlope * (currentTime - _attackStartTime);
                _priority = 3.0 + _value;
                return true;

            case EnvelopeStage.hold:
                _value = 1;
                _priority = 2.0 + _value;
                return true;

            case EnvelopeStage.decay:

                double t = currentTime - _decayStartTime;
                double cutoff = SoundFontMath.expCutoff(_decaySlope * t);

                _value = max(cutoff, _sustainLevel);
                _priority = 1.0 + _value;

                return _value > SoundFontMath.nonAudible;

            case EnvelopeStage.release:

                double t = currentTime - _releaseStartTime;
                double cutoff = SoundFontMath.expCutoff(_releaseSlope * t);

                _value = _releaseLevel * cutoff;
                _priority = _value;

                return _value > SoundFontMath.nonAudible;

            default:
                throw "Invalid envelope stage.";
        }
    }

    double value() => _value;
    double priority() => _priority;
}

