// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:dart_melty_soundfont/src/utils/short.dart';

import '../soundfont_math.dart';
import 'binary_reader.dart';
import 'binary_reader_ex.dart';
import 'midi_file_loop_type.dart';

/// <summary>
/// Represents a standard MIDI file.
/// </summary>
class MidiFile {
  late final List<Message> messages;
  late final List<Duration> times;

  MidiFile({
    required BinaryReader reader,
    int loopPoint = 0,
    MidiFileLoopType loopType = MidiFileLoopType.None,
  }) {
    if (loopPoint < 0) {
      throw 'The loop point must be a non-negative value.';
    }

    load(reader, loopPoint, loopType);
  }

  void load(BinaryReader reader, int loopPoint, MidiFileLoopType loopType) {
    final chunkType = reader.readFourCC();
    if (chunkType != 'MThd') {
      throw 'The chunk type must be "MThd", but was "$chunkType".';
    }

    final size = reader.readInt32BigEndian();
    if (size != 6) {
      throw 'The MThd chunk has invalid data.';
    }

    final format = reader.readInt16BigEndian();
    if (!(format == 0 || format == 1)) {
      throw 'The format ${format} is not supported.';
    }

    final trackCount = reader.readInt16BigEndian();
    final resolution = reader.readInt16BigEndian();

    final messageLists = <List<Message>>[];
    final tickLists = <List<int>>[];

    for (var i = 0; i < trackCount; i++) {
      final result = readTrack(reader, loopType);
      messageLists.add(result.messages);
      tickLists.add(result.ticks);
    }

    if (loopPoint != 0) {
      final tickList = tickLists[0];
      final messageList = messageLists[0];
      if (loopPoint <= tickList.last) {
        for (var i = 0; i < tickList.length; i++) {
          if (tickList[i] >= loopPoint) {
            tickList.insert(i, loopPoint);
            messageList.insert(i, Message.loopStart());
            break;
          }
        }
      } else {
        tickList.add(loopPoint);
        messageList.add(Message.loopStart());
      }
    }

    final result = mergeTracks(messageLists, tickLists, resolution);
    messages = result.messages;
    times = result.times;
  }

  // Some .NET implementations round TimeSpan to the nearest millisecond,
  // and the timing of MIDI messages will be wrong.
  // This method makes TimeSpan without rounding.
  static Duration getTimeSpanFromSeconds(double value) {
    final ticksPerSecond = 10000000;
    // A time period expressed in 100-nanosecond units.
    final ticks = (value * ticksPerSecond).toInt();
    final microseconds = ticks ~/ 10;
    final duration = Duration(microseconds: microseconds);
    print('$value -> ${microseconds} -> ${duration.inSeconds}');
    return duration;
  }

  static ReadTrackResult readTrack(
    BinaryReader reader,
    MidiFileLoopType loopType,
  ) {
    final chunkType = reader.readFourCC();
    if (chunkType != 'MTrk') {
      throw 'The chunk type must be "MTrk", but was "$chunkType".';
    }

    var end = reader.readInt32BigEndian();
    end += reader.pos;

    final messages = <Message>[];
    final ticks = <int>[];

    int tick = 0;
    var lastStatus = 0; // byte

    while (true) {
      final delta = reader.readIntVariableLength();
      final first = reader.readByte();

      try {
        tick = tick + delta; // TODO: checked
      } catch (e) {
        throw 'Long MIDI file is not supported.';
      }

      if ((first & 128) == 0) {
        final command = lastStatus & 0xF0;
        if (command == 0xC0 || command == 0xD0) {
          messages.add(Message.commonSingle(lastStatus, first));
          ticks.add(tick);
        } else {
          final data2 = reader.readByte();
          messages.add(Message.common(lastStatus, first, data2, loopType));
          ticks.add(tick);
        }

        continue;
      }

      switch (first) {
        case 0xF0: // System Exclusive
          discardData(reader);
          break;
        case 0xF7: // System Exclusive
          discardData(reader);
          break;
        case 0xFF: // Meta event
          switch (reader.readByte()) {
            case 0x2F: // End of track
              reader.readByte();
              messages.add(Message.endOfTrack());
              ticks.add(tick);

              // Some MIDI files may have events inserted after the EOT.
              // Such events should be ignored.
              if (reader.pos < end) {
                reader.pos = end;
              }

              return ReadTrackResult(messages, ticks);
            case 0x51: // Tempo
              messages.add(Message.tempChange(readTempo(reader)));
              ticks.add(tick);
              break;
            default:
              discardData(reader);
              break;
          }
          break;
        default:
          final command = first & 0xF0;
          if (command == 0xC0 || command == 0xD0) {
            final data1 = reader.readByte();
            messages.add(Message.commonSingle(first, data1));
            ticks.add(tick);
          } else {
            final data1 = reader.readByte();
            final data2 = reader.readByte();
            messages.add(Message.common(first, data1, data2, loopType));
            ticks.add(tick);
          }
          break;
      }

      lastStatus = first;
    }
  }

  static MergeTracksResult mergeTracks(
    List<List<Message>> messageLists,
    List<List<int>> tickLists,
    int resolution,
  ) {
    final mergedMessages = <Message>[];
    final mergedTimes = <Duration>[];

    final indices = List<int>.filled(messageLists.length, 0);

    var currentTick = 0;
    var currentTime = Duration.zero;

    var tempo = 120.0;

    while (true) {
      // ignore: unused_local_variable
      var minTick = INT_MAX_VALUE;
      var minIndex = -1;
      for (var ch = 0; ch < tickLists.length; ch++) {
        if (indices[ch] < tickLists[ch].length) {
          final tick = tickLists[ch][indices[ch]];
          if (tick < minTick) {
            minTick = tick;
            minIndex = ch;
          }
        }
      }

      if (minIndex == -1) {
        break;
      }

      final nextTick = tickLists[minIndex][indices[minIndex]];
      final deltaTick = nextTick - currentTick;
      final deltaTime =
          getTimeSpanFromSeconds(60.0 / (resolution * tempo) * deltaTick);

      currentTick += deltaTick;
      currentTime += deltaTime;

      final message = messageLists[minIndex][indices[minIndex]];
      if (message.type == MessageType.TempoChange) {
        tempo = message.tempo;
      } else {
        mergedMessages.add(message);
        mergedTimes.add(currentTime);
      }

      indices[minIndex]++;
    }

    return MergeTracksResult(mergedMessages, mergedTimes);
  }

  static int readTempo(BinaryReader reader) {
    final size = reader.readIntVariableLength();
    if (size != 3) {
      throw 'Failed to read the tempo value.';
    }

    final b1 = reader.readByte();
    final b2 = reader.readByte();
    final b3 = reader.readByte();
    return (b1 << 16) | (b2 << 8) | b3;
  }

  static void discardData(BinaryReader reader) {
    final size = reader.readIntVariableLength();
    reader.pos += size;
  }

  /// <summary>
  /// The length of the MIDI file.
  /// </summary>
  Duration get length => times.last;
}

class ReadTrackResult {
  final List<Message> messages;
  final List<int> ticks;

  const ReadTrackResult(
    this.messages,
    this.ticks,
  );

  @override
  String toString() {
    return 'ReadTrackResult{messages: ${messages.length}, ticks: ${ticks.length}}';
  }
}

class MergeTracksResult {
  final List<Message> messages;
  final List<Duration> times;

  const MergeTracksResult(
    this.messages,
    this.times,
  );

  @override
  String toString() {
    return 'MergeTracksResult{messages: ${messages.length}, times: ${times.length}}';
  }
}

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
