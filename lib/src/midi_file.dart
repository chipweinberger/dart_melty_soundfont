// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'binary_reader.dart';
import 'binary_reader_ex.dart';
import 'midi_file_loop_type.dart';
import 'midi_message.dart';

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
    return Duration(
        microseconds: (Duration.millisecondsPerSecond *
                Duration.microsecondsPerMillisecond *
                value)
            .toInt());
  }

  static int _checkedAdd(int a, int b) {
    var sum = a + b;
    if (a > 0 && b > 0 && sum < 0) {
      throw "int OverflowException(positive: true)";
    }
    if (a < 0 && b < 0 && sum > 0) {
      throw "OverflowException(positive: false)";
    }
    return sum;
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
      final delta = reader.readMidiVariableLength();
      final first = reader.readUInt8();

      try {
        tick = _checkedAdd(tick, delta);
      } catch (e) {
        throw 'Long MIDI file is not supported.';
      }

      if ((first & 128) == 0) {
        final command = lastStatus & 0xF0;
        if (command == 0xC0 || command == 0xD0) {
          messages.add(Message.commonSingle(lastStatus, first));
          ticks.add(tick);
        } else {
          final data2 = reader.readUInt8();
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
          switch (reader.readUInt8()) {
            case 0x2F: // End of track
              reader.readUInt8();
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
            final data1 = reader.readUInt8();
            messages.add(Message.commonSingle(first, data1));
            ticks.add(tick);
          } else {
            final data1 = reader.readUInt8();
            final data2 = reader.readUInt8();
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
      var minTick = 0x7fffffffffffffff;
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
    final size = reader.readMidiVariableLength();
    if (size != 3) {
      throw 'Failed to read the tempo value.';
    }

    final b1 = reader.readUInt8();
    final b2 = reader.readUInt8();
    final b3 = reader.readUInt8();
    return (b1 << 16) | (b2 << 8) | b3;
  }

  static void discardData(BinaryReader reader) {
    final size = reader.readMidiVariableLength();
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
