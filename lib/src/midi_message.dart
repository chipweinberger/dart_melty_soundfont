import 'soundfont_math.dart';
import 'midi_file_loop_type.dart';

/// @internal
class Message {
  final int channel; // byte
  final int command; // byte
  final int data1; // byte
  final int data2; // byte

  Message(this.channel, this.command, this.data1, this.data2);

  static Message commonSingle(int status, int data1) {
    final channel = castToByte(status & 0x0F);
    final command = castToByte(status & 0xF0);
    final data2 = 0;
    return Message(channel, command, data1, data2);
  }

  static Message common(
    int status,
    int data1,
    int data2,
    MidiFileLoopType loopType,
  ) {
    final channel = castToByte(status & 0x0F);
    final command = castToByte(status & 0xF0);

    if (command == 0xB0) {
      switch (loopType) {
        case MidiFileLoopType.RpgMaker:
          if (data1 == 111) return loopStart();
          break;
        case MidiFileLoopType.IncredibleMachine:
          if (data1 == 110) return loopStart();
          if (data1 == 111) return loopEnd();
          break;
        case MidiFileLoopType.FinalFantasy:
          if (data1 == 116) return loopStart();
          if (data1 == 117) return loopEnd();
          break;
        default:
      }
    }

    return Message(channel, command, data1, data2);
  }

  static Message tempChange(int tempo) {
    final command = castToByte(tempo >> 16);
    final data1 = castToByte(tempo >> 8);
    final data2 = castToByte(tempo);
    return Message(MessageType.TempoChange.value, command, data1, data2);
  }

  static Message loopStart() {
    return Message(MessageType.LoopStart.value, 0, 0, 0);
  }

  static Message loopEnd() {
    return Message(MessageType.LoopEnd.value, 0, 0, 0);
  }

  static Message endOfTrack() {
    return Message(MessageType.EndOfTrack.value, 0, 0, 0);
  }

  @override
  String toString() {
    switch (getMessageTypeFromInt(channel)) {
      case MessageType.TempoChange:
        return 'Tempo: ${tempo}';
      case MessageType.LoopStart:
        return 'LoopStart';
      case MessageType.LoopEnd:
        return 'LoopEnd';
      case MessageType.EndOfTrack:
        return 'EndOfTrack';
      default:
        return 'CH$channel: ${command.toRadixString(16)}, ${data1.toRadixString(16)}, ${data2.toRadixString(16)}';
    }
  }

  MessageType get type {
    final type = getMessageTypeFromInt(channel);
    return type ?? MessageType.Normal;
  }

  double get tempo => 60000000.0 / ((command << 16) | (data1 << 8) | data2);
}

/// @internal
enum MessageType {
  Normal(0),
  TempoChange(252),
  LoopStart(253),
  LoopEnd(254),
  EndOfTrack(255);

  const MessageType(this.value);
  final int value;
}

MessageType? getMessageTypeFromInt(int status) {
  for (final type in MessageType.values) {
    if (type.value == status) {
      return type;
    }
  }
  return null;
}
