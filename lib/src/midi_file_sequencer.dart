import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'synthesizer.dart';
import 'i_audio_renderer.dart';
import 'midi_file.dart';
import 'midi_message.dart';
import 'utils/span.dart';

/// <summary>
/// An instance of the MIDI file sequencer.
/// </summary>
/// <remarks>
/// Note that this class does not provide thread safety.
/// If you want to do playback control and render the waveform in separate threads,
/// you must ensure that the methods will not be called simultaneously.
/// </remarks>
class MidiFileSequencer extends IAudioRenderer {
  final Synthesizer synthesizer;
  late double _speed;

  MidiFile? _midiFile;
  bool _loop = false;

  int _blockWrote = 0;

  Duration _currentTime = Duration.zero;
  int _msgIndex = 0;
  int _loopIndex = 0;

  /// <summary>
  /// Gets or sets the method to alter MIDI messages during playback.
  /// If null, MIDI messages will be sent to the synthesizer without any change.
  /// </summary>
  final _messageController = StreamController<Message>();

  late ByteData _blockLeft;
  late ByteData _blockRight;

  MidiFileSequencer(this.synthesizer) {
    _blockLeft = ByteData(Float32List.bytesPerElement * synthesizer.blockSize);
    _blockRight = ByteData(Float32List.bytesPerElement * synthesizer.blockSize);
    speed = 1;
  }

  Stream<Message>? get onMidiMessage {
    return _messageController.stream;
  }

  /// <summary>
  /// Plays the MIDI file.
  /// </summary>
  /// <param name="midiFile">The MIDI file to be played.</param>
  /// <param name="loop">If <c>true</c>, the MIDI file loops after reaching the end.</param>
  void play(MidiFile midiFile, bool loop) {
    _midiFile = midiFile;
    _loop = loop;

    _blockWrote = synthesizer.blockSize;

    _currentTime = Duration.zero;
    _msgIndex = 0;
    _loopIndex = 0;

    synthesizer.reset();
  }

  /// <summary>
  /// Stop playing.
  /// </summary>
  void stop() {
    _midiFile = null;
    synthesizer.reset();
  }

  /// <inheritdoc/>
  void render(Span<double> left, Span<double> right) {
    if (left.length != right.length) {
      throw 'The output buffers for the left and right must be the same length.';
    }

    var wrote = 0;
    while (wrote < left.length) {
      if (_blockWrote == synthesizer.blockSize) {
        processEvents();
        _blockWrote = 0;
        _currentTime = MidiFile.getTimeSpanFromSeconds(
            speed * synthesizer.blockSize / synthesizer.sampleRate);
      }

      final srcRem = synthesizer.blockSize - _blockWrote;
      final dstRem = left.length - wrote;
      final rem = min(srcRem, dstRem);

      var blockLeft = Float32List.view(_blockLeft.buffer, 0, rem).toSpan();
      var blockRight = Float32List.view(_blockRight.buffer, 0, rem).toSpan();
      synthesizer.render(blockLeft, blockRight);
      // synthesizer.render(left.slice(wrote, rem), right.slice(wrote, rem));

      for (int i = 0; i < rem; i++) {
        left[wrote + i] = blockLeft[i];
        right[wrote + i] = blockRight[i];
      }

      _blockWrote += rem;
      wrote += rem;
    }
  }

  void processEvents() {
    if (_midiFile == null) return;

    while (_msgIndex < _midiFile!.messages.length) {
      final time = _midiFile!.times[_msgIndex];
      final msg = _midiFile!.messages[_msgIndex];
      if (time <= _currentTime) {
        if (msg.type == MessageType.Normal) {
          _messageController.add(msg);
          synthesizer.processMidiMessage(
            channel: msg.channel,
            command: msg.command,
            data1: msg.data1,
            data2: msg.data2,
          );
        } else if (_loop) {
          if (msg.type == MessageType.LoopStart) {
            _loopIndex = _msgIndex;
          } else if (msg.type == MessageType.LoopEnd) {
            _currentTime = _midiFile!.times[_loopIndex];
            _msgIndex = _loopIndex;
            synthesizer.noteOffAll(immediate: false);
          }
        }
        _msgIndex++;
      } else {
        break;
      }
    }

    if (_msgIndex == _midiFile!.messages.length && _loop) {
      _currentTime = _midiFile!.times[_loopIndex];
      _msgIndex = _loopIndex;
      synthesizer.noteOffAll(immediate: false);
    }
  }

  /// <summary>
  /// Gets the current playback position.
  /// </summary>
  Duration get position => _currentTime;

  /// <summary>
  /// Gets a value that indicates whether the current playback position is at the end of the sequence.
  /// </summary>
  /// <remarks>
  /// If the <see cref="Play(MidiFile, bool)">Play</see> method has not yet been called, this value is true.
  /// This value will never be <c>true</c> if loop playback is enabled.
  /// </remarks>
  bool get endOfSequence {
    if (_midiFile == null) return true;
    return _msgIndex == _midiFile!.messages.length;
  }

  /// <summary>
  /// Gets or sets the playback speed.
  /// </summary>
  /// <remarks>
  /// The default value is 1.
  /// The tempo will be multiplied by this value.
  /// </remarks>
  double get speed => _speed;
  set speed(double value) {
    if (value > 0) {
      _speed = value;
    } else {
      throw 'The playback speed must be a positive value.';
    }
  }
}
