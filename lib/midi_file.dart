import 'dart:typed_data';

import 'binary_reader.dart';
import 'midi_file_loop_type.dart';

/// <summary>
/// Represents a standard MIDI file.
/// </summary>
class MidiFile {
  late List<MidiMessage> _messages;
  late List<Duration> _times;

  /// Loads a MIDI file from the file path.
  factory MidiFile.fromFile(String path, {int? loopPoint, MidiFileLoopType? loopType}) {
    BinaryReader reader = BinaryReader.fromFile(path);

    return MidiFile.fromBinaryReader(reader, loopPoint: loopPoint, loopType: loopType);
  }

  /// Loads a MIDI file from the byte data
  factory MidiFile.fromByteData(ByteData bytes, {int? loopPoint, MidiFileLoopType? loopType}) {
    BinaryReader reader = BinaryReader.fromByteData(bytes);

    return MidiFile.fromBinaryReader(reader, loopPoint: loopPoint, loopType: loopType);
  }

  MidiFile.fromBinaryReader(BinaryReader reader, {int? loopPoint, MidiFileLoopType? loopType}) {
    if (loopPoint != null && loopPoint < 0) {
      throw "The loop point must be a non-negative value.";
    }

    _load(reader, loopPoint ?? 0, loopType ?? MidiFileLoopType.none);
  }

  static Duration getTimeSpanFromSeconds(double value) {
    return Duration(
        microseconds: (value * Duration.microsecondsPerSecond).round());
  }

  void _load(BinaryReader reader, int loopPoint, MidiFileLoopType loopType) {
    final chunkType = reader.readFourCC();
    if (chunkType != "MThd") {
      throw "The chunk type must be 'MThd', but was '$chunkType'.";
    }

    final size = reader.readInt32BigEndian();
    if (size != 6) {
      throw "The MThd chunk has invalid data.";
    }

    final format = reader.readInt16BigEndian();
    if (!(format == 0 || format == 1)) {
      throw "The format {format} is not supported.";
    }

    final trackCount = reader.readInt16BigEndian();
    final resolution = reader.readInt16BigEndian();

    final messageLists = List<List<MidiMessage>>.filled(trackCount, [], growable: false);
    final tickLists = List<List<int>>.filled(trackCount, [], growable: false);

    for (int i = 0; i < trackCount; i++) {
      final tracks = _readTrack(reader, loopType);
      messageLists[i] = tracks.messages;
      tickLists[i] = tracks.ticks;
    }

    if (loopPoint != 0) {
      final tickList = tickLists[0];
      final messageList = messageLists[0];
      if (loopPoint <= tickList.last) {
        for (int i = 0; i < tickList.length; i++) {
          if (tickList[i] >= loopPoint) {
            tickList.insert(i, loopPoint);
            messageList.insert(i, MidiMessage.loopStart());
            break;
          }
        }
      } else {
        tickList.add(loopPoint);
        messageList.add(MidiMessage.loopStart());
      }
    }

    final mergedTracks = _mergeTracks(messageLists, tickLists, resolution);
    _messages = mergedTracks.messages;
    _times = mergedTracks.times;
  }

  static _MidiMessagesAndTicks _readTrack(
      BinaryReader reader, MidiFileLoopType loopType) {
    final chunkType = reader.readFourCC();
    if (chunkType != "MTrk") {
      throw "The chunk type must be 'MTrk', but was '$chunkType'.";
    }

    int end = reader.readInt32BigEndian();
    end += reader.pos;

    final messages = <MidiMessage>[];
    final ticks = <int>[];

    int tick = 0;
    int lastStatus = 0;

    while (true) {
      final delta = reader.readMidiVariablelength();
      final first = reader.readUInt8();

      try {
        tick = tick + delta;
      } catch (OverflowException) {
        throw "Long MIDI file is not supported.";
      }

      if ((first & 128) == 0) {
        final command = lastStatus & 0xF0;
        if (command == 0xC0 || command == 0xD0) {
          messages.add(MidiMessage.common(lastStatus, first));
          ticks.add(tick);
        } else {
          final data2 = reader.readUInt8();
          messages.add(MidiMessage.common(lastStatus, first, data2, loopType));
          ticks.add(tick);
        }

        continue;
      }

      switch (first) {
        case 0xF0: // System Exclusive
          _discardData(reader);
          break;

        case 0xF7: // System Exclusive
          _discardData(reader);
          break;

        case 0xFF: // Meta Event
          switch (reader.readUInt8()) {
            case 0x2F: // End of Track
              reader.readUInt8();
              messages.add(MidiMessage.endOfTrack());
              ticks.add(tick);

              // Some MIDI files may have events inserted after the EOT.
              // Such events should be ignored.
              if (reader.pos < end) {
                reader.pos = end;
              }

              return _MidiMessagesAndTicks(messages, ticks);

            case 0x51: // Tempo
              messages.add(MidiMessage.tempoChange(_readTempo(reader)));
              ticks.add(tick);
              break;

            default:
              _discardData(reader);
              break;
          }
          break;

        default:
          final command = first & 0xF0;
          if (command == 0xC0 || command == 0xD0) {
            final data1 = reader.readUInt8();
            messages.add(MidiMessage.common(first, data1));
            ticks.add(tick);
          } else {
            final data1 = reader.readUInt8();
            final data2 = reader.readUInt8();
            messages.add(MidiMessage.common(first, data1, data2, loopType));
            ticks.add(tick);
          }
          break;
      }

      lastStatus = first;
    }
  }

  static _MidiMessagesAndTimes _mergeTracks(
      List<List<MidiMessage>> messageLists,
      List<List<int>> tickLists,
      int resolution) {
    final mergedMessages = <MidiMessage>[];
    final mergedTimes = <Duration>[];

    final indices = List<int>.filled(messageLists.length, 0, growable: false);

    int currentTick = 0;
    Duration currentTime = Duration.zero;

    double tempo = 120.0;

    while (true) {
      int minTick = 0x7fffffffffffffff; // int max value
      int minIndex = -1;
      for (int ch = 0; ch < tickLists.length; ch++) {
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
      if (message.type == MidiMessageType.tempoChange) {
        tempo = message.tempo;
      } else {
        mergedMessages.add(message);
        mergedTimes.add(currentTime);
      }

      indices[minIndex]++;
    }

    return _MidiMessagesAndTimes(mergedMessages, mergedTimes);
  }

  static int _readTempo(BinaryReader reader) {
    final size = reader.readMidiVariablelength();
    if (size != 3) {
      throw "Failed to read the tempo value.";
    }

    final b1 = reader.readUInt8();
    final b2 = reader.readUInt8();
    final b3 = reader.readUInt8();
    return (b1 << 16) | (b2 << 8) | b3;
  }

  static void _discardData(BinaryReader reader) {
    final size = reader.readMidiVariablelength();
    reader.pos += size;
  }

  /// <summary>
  /// The length of the MIDI file.
  /// </summary>
  Duration get length => _times.last;

  List<MidiMessage> get messages => _messages;

  List<Duration> get times => _times;
}

class MidiMessage {
  final int channel;
  final int command;
  final int data1;
  final int data2;

  MidiMessage._(this.channel, this.command, this.data1, this.data2);

  factory MidiMessage.common(int status, int data1,
      [int data2 = 0, MidiFileLoopType loopType = MidiFileLoopType.none]) {
    final channel = status & 0x0F;
    final command = status & 0xF0;

    if (command == 0xB0) {
      switch (loopType) {
        case MidiFileLoopType.rpgMaker:
          if (data1 == 111) {
            return MidiMessage.loopStart();
          }
          break;

        case MidiFileLoopType.incredibleMachine:
          if (data1 == 110) {
            return MidiMessage.loopStart();
          }
          if (data1 == 111) {
            return MidiMessage.loopEnd();
          }
          break;

        case MidiFileLoopType.finalFantasy:
          if (data1 == 116) {
            return MidiMessage.loopStart();
          }
          if (data1 == 117) {
            return MidiMessage.loopEnd();
          }
          break;

        default:
      }
    }

    return MidiMessage._(channel, command, data1, data2);
  }

  factory MidiMessage.tempoChange(int tempo) {
    final command = tempo >> 16;
    final data1 = tempo >> 8;
    final data2 = tempo;
    return MidiMessage._(
        MidiMessageType.tempoChange.value, command, data1, data2);
  }

  factory MidiMessage.loopStart() {
    return MidiMessage._(MidiMessageType.loopStart.value, 0, 0, 0);
  }

  factory MidiMessage.loopEnd() {
    return MidiMessage._(MidiMessageType.loopEnd.value, 0, 0, 0);
  }

  factory MidiMessage.endOfTrack() {
    return MidiMessage._(MidiMessageType.endOfTrack.value, 0, 0, 0);
  }

  @override
  String toString() {
    switch (type) {
      case MidiMessageType.tempoChange:
        return "Tempo: $tempo";
      case MidiMessageType.loopStart:
        return "LoopStart";
      case MidiMessageType.loopEnd:
        return "LoopEnd";
      case MidiMessageType.endOfTrack:
        return "EndOfTrack";
      default:
        return "CH$channel: ${_toHexString(command)}, ${_toHexString(data1)}, ${_toHexString(data2)}";
    }
  }

  String _toHexString(int value) {
    return value.toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  MidiMessageType get type {
    // Using normal if-else as MessageType is not an enum
    if (channel == MidiMessageType.tempoChange.value) {
      return MidiMessageType.tempoChange;
    } else if (channel == MidiMessageType.loopStart.value) {
      return MidiMessageType.loopStart;
    } else if (channel == MidiMessageType.loopEnd) {
      return MidiMessageType.loopEnd;
    } else if (channel == MidiMessageType.endOfTrack) {
      return MidiMessageType.endOfTrack;
    } else {
      return MidiMessageType.normal;
    }
  }

  double get tempo => 60000000.0 / ((command << 16) | (data1 << 8) | data2);
}

class MidiMessageType {
  static const normal = MidiMessageType(0);
  static const tempoChange = MidiMessageType(252);
  static const loopStart = MidiMessageType(253);
  static const loopEnd = MidiMessageType(254);
  static const endOfTrack = MidiMessageType(255);

  final int value;

  const MidiMessageType(this.value);
}

// As Dart 2.x does not have tuples (records) yet, using classes as an alternative

class _MidiMessagesAndTicks {
  final List<MidiMessage> messages;
  final List<int> ticks;

  _MidiMessagesAndTicks(this.messages, this.ticks);
}

class _MidiMessagesAndTimes {
  final List<MidiMessage> messages;
  final List<Duration> times;

  _MidiMessagesAndTimes(this.messages, this.times);
}