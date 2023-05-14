import '../soundfont_math.dart';
import '../synthesizer.dart';

class Channel {
  final Synthesizer synthesizer;
  final bool isPercussionChannel;

  late int _bankNumber;
  late int _patchNumber;

  late int _modulation;
  late int _volume;
  late int _pan;
  late int _expression;
  late bool _holdPedal;

  late int _reverbSend;
  late int _chorusSend;

  late int _rpn;
  late int _pitchBendRange;
  late int _coarseTune;
  late int _fineTune;

  late double _pitchBend;

  Channel(this.synthesizer, this.isPercussionChannel) {
    this.reset();
  }

  void reset() {
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

    _pitchBend = 0;
  }

  void resetAllControllers() {
    _modulation = 0;
    _expression = 127 << 7;
    _holdPedal = false;

    _rpn = -1;

    _pitchBend = 0;
  }

  void setBank(int value) {
    _bankNumber = value;

    if (isPercussionChannel) {
      _bankNumber += 128;
    }
  }

  void setPatch(int value) {
    _patchNumber = value;
  }

  void setModulationCoarse(int value) {
    _modulation = castToShort((_modulation & 0x7F) | (value << 7));
  }

  void setModulationFine(int value) {
    _modulation = castToShort((_modulation & 0xFF80) | value);
  }

  void setVolumeCoarse(int value) {
    _volume = castToShort((_volume & 0x7F) | (value << 7));
  }

  void setVolumeFine(int value) {
    _volume = castToShort((_volume & 0xFF80) | value);
  }

  void setPanCoarse(int value) {
    _pan = castToShort((_pan & 0x7F) | (value << 7));
  }

  void setPanFine(int value) {
    _pan = castToShort((_pan & 0xFF80) | value);
  }

  void setExpressionCoarse(int value) {
    _expression = castToShort((_expression & 0x7F) | (value << 7));
  }

  void setExpressionFine(int value) {
    _expression = castToShort((_expression & 0xFF80) | value);
  }

  void setHoldPedal(int value) {
    _holdPedal = value >= 64;
  }

  void setReverbSend(int value) {
    _reverbSend = castToByte(value);
  }

  void setChorusSend(int value) {
    _chorusSend = castToByte(value);
  }

  void setRpnCoarse(int value) {
    _rpn = castToShort((_rpn & 0x7F) | (value << 7));
  }

  void setRpnFine(int value) {
    _rpn = castToShort((_rpn & 0xFF80) | value);
  }

  void dataEntryCoarse(int value) {
    switch (_rpn) {
      case 0:
        _pitchBendRange = castToShort((_pitchBendRange & 0x7F) | (value << 7));
        break;
      case 1:
        _fineTune = castToShort((_fineTune & 0x7F) | (value << 7));
        break;
      case 2:
        _coarseTune = castToShort(value - 64);
        break;
      default:
    }
  }

  void dataEntryFine(int value) {
    switch (_rpn) {
      case 0:
        _pitchBendRange = castToShort((_pitchBendRange & 0xFF80) | value);
        break;
      case 1:
        _fineTune = castToShort((_fineTune & 0xFF80) | value);
        break;
      default:
    }
  }

  void setPitchBend(int value1, int value2) {
    _pitchBend = (1.0 / 8192.0) * ((value1 | (value2 << 7)) - 8192);
  }

  int get bankNumber => _bankNumber;
  int get patchNumber => _patchNumber;

  double get modulation => (50.0 / 16383.0) * _modulation;
  double get volume => (1.0 / 16383.0) * _volume;
  double get pan => (100.0 / 16383.0) * _pan - 50.0;
  double get expression => (1.0 / 16383.0) * _expression;
  bool get holdPedal => _holdPedal;

  double get reverbSend => (1.0 / 127.0) * _reverbSend;
  double get chorusSend => (1.0 / 127.0) * _chorusSend;

  double get pitchBendRange =>
      (_pitchBendRange >> 7) + 0.01 * (_pitchBendRange & 0x7F);
  double get tune => _coarseTune + (1.0 / 8192.0) * (_fineTune - 8192);

  double get pitchBend => _pitchBendRange * _pitchBend;
}
