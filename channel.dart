
import 'soundfont_math.dart';
import 'synthesizer.dart';

class Channel
{
    final Synthesizer synthesizer;
    final bool isPercussionChannel;

    final List<double> blockLeft;
    final List<double> blockRight;

    int _bankNumber;
    int _patchNumber;

    int _modulation; // short
    int _volume;     // short
    int _pan;        // short
    int _expression; // short
    bool _holdPedal;

    int _reverbSend; // byte
    int _chorusSend; // byte

    int _rpn;            // short 
    int _pitchBendRange; // short 
    int _coarseTune;     // short 
    int _fineTune;       // short 

    double _pitchBend;

    Channel({required this.synthesizer,
             required this.isPercussionChannel,
             required this.blockLeft,
             required this.blockRight,
             required int bankNumber,
             required int patchNumber,
             required int modulation,
             required int volume,
             required int pan,
             required int expression,
             required bool holdPedal,
             required int reverbSend,
             required int chorusSend,
             required int rpn,
             required int pitchBendRange,
             required int coarseTune,
             required int fineTune,
             required double pitchBend}) : 
             _bankNumber = bankNumber,
             _patchNumber = patchNumber,
             _modulation = modulation,
             _volume = volume,
             _pan = pan,
             _expression = expression,
             _holdPedal = holdPedal,
             _reverbSend = reverbSend,
             _chorusSend = chorusSend,
             _rpn = rpn,
             _pitchBendRange = pitchBendRange,
             _coarseTune = coarseTune,
             _fineTune = fineTune,
             _pitchBend = pitchBend;

    factory Channel.create(Synthesizer synthesizer, bool isPercussionChannel)
    {
      Channel c = Channel(
              synthesizer: synthesizer,
              isPercussionChannel: isPercussionChannel,
              blockLeft : List<double>.filled(synthesizer.blockSize, 0.0),
              blockRight : List<double>.filled(synthesizer.blockSize, 0.0),
              bankNumber : 0,
              patchNumber : 0,
              modulation : 0,
              volume : 0,
              pan : 0,
              expression : 0,
              holdPedal : false,
              reverbSend : 0,
              chorusSend : 0,
              rpn: 0,
              pitchBendRange: 0,
              coarseTune: 0,
              fineTune: 0,
              pitchBend: 0.0
      );

      c.reset();

      return c;
    }

    void reset()
    {
        _bankNumber = isPercussionChannel ? 128 : 0;
        _patchNumber = 0;

        _modulation = 0;
        _volume = 100 << 7;
        _pan = 64 << 7;
        _expression = 127 << 7;
        _holdPedal = false;

        _reverbSend = 40;
        _chorusSend = 0;

        _rpn = -1;
        _pitchBendRange = 2 << 7;
        _coarseTune = 0;
        _fineTune = 8192;

        _pitchBend = 0.0;
    }

    void resetAllControllers()
    {
        _modulation = 0;
        _expression = 127 << 7;
        _holdPedal = false;

        _rpn = -1;

        _pitchBend = 0.0;
    }

    void setBank(int value)
    {
        _bankNumber = value;

        if (isPercussionChannel)
        {
            _bankNumber += 128;
        }
    }

    void setPatch(int value)
    {
        _patchNumber = value;
    }

    void setModulationCoarse(int value)
    {
        _modulation = castToShort((_modulation & 0x7F) | (value << 7));
    }

    void setModulationFine(int value)
    {
        _modulation = castToShort((_modulation & 0xFF80) | value);
    }

    void setVolumeCoarse(int value)
    {
        _volume = castToShort((_volume & 0x7F) | (value << 7));
    }

    void setVolumeFine(int value)
    {
        _volume = castToShort((_volume & 0xFF80) | value);
    }

    void setPanCoarse(int value)
    {
        _pan = castToShort((_pan & 0x7F) | (value << 7));
    }

    void setPanFine(int value)
    {
        _pan = castToShort((_pan & 0xFF80) | value);
    }

    void setExpressionCoarse(int value)
    {
        _expression = castToShort((_expression & 0x7F) | (value << 7));
    }

    void setExpressionFine(int value)
    {
        _expression = castToShort((_expression & 0xFF80) | value);
    }

    void setHoldPedal(int value)
    {
        _holdPedal = value >= 64;
    }

    void setReverbSend(int value)
    {
        _reverbSend = castToByte(value);
    }

    void setChorusSend(int value)
    {
        _chorusSend = castToByte(value);
    }

    void setRpnCoarse(int value)
    {
        _rpn = castToShort((_rpn & 0x7F) | (value << 7));
    }

    void setRpnFine(int value)
    {
        _rpn = castToShort((_rpn & 0xFF80) | value);
    }

    void dataEntryCoarse(int value)
    {
        switch (_rpn)
        {
            case 0:
                _pitchBendRange = castToShort((_pitchBendRange & 0x7F) | (value << 7));
                break;

            case 1:
                _fineTune = castToShort((_fineTune & 0x7F) | (value << 7));
                break;

            case 2:
                _coarseTune = castToShort(value - 64);
                break;
        }
    }

    void dataEntryFine(int value)
    {
        switch (_rpn)
        {
            case 0:
                _pitchBendRange = castToShort((_pitchBendRange & 0xFF80) | value);
                break;

            case 1:
                _fineTune = castToShort((_fineTune & 0xFF80) | value);
                break;
        }
    }

    void setPitchBend(int value1, int value2)
    {
        _pitchBend = (1.0 / 8192.0) * ((value1 | (value2 << 7)) - 8192);
    }

    int bankNumber() => _bankNumber;
    int patchNumber() => _patchNumber;

    double modulation() => (50.0 / 16383.0) * _modulation;
    double volume() => (1.0 / 16383.0) * _volume;
    double pan() => (100.0 / 16383.0) * _pan - 50.0;
    double expression() => (1.0 / 16383.0) * _expression;
    bool holdPedal() => _holdPedal;

    double reverbSend() => (1.0 / 127.0) * _reverbSend;
    double chorusSend() => (1.0 / 127.0) * _chorusSend;

    double pitchBendRange() => (_pitchBendRange >> 7) + 0.01 * (_pitchBendRange & 0x7F);
    double tune() => _coarseTune + (1.0 / 8192.0) * (_fineTune - 8192);

    double pitchBend() => pitchBendRange() * _pitchBend;
}

