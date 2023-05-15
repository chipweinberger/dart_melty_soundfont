import 'dart:math';

import '../synthesizer.dart';
import 'i_audio_renderer.dart';
import 'midi_file.dart';
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
  MessageHook? onSendMessage;

  MidiFileSequencer(this.synthesizer) {
    speed = 1;
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

      synthesizer.render(left.slice(wrote, rem), right.slice(wrote, rem));

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
          if (onSendMessage == null) {
            synthesizer.processMidiMessage(
              channel: msg.channel,
              command: msg.command,
              data1: msg.data1,
              data2: msg.data2,
            );
          } else {
            onSendMessage!(
              synthesizer,
              msg.channel,
              msg.command,
              msg.data1,
              msg.data2,
            );
          }
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

/// <summary>
/// Represents the method that is called each time a MIDI message is processed during playback.
/// </summary>
/// <param name="synthesizer">The synthesizer handled by the sequencer.</param>
/// <param name="channel">The channel to which the message will be sent.</param>
/// <param name="command">The type of the message.</param>
/// <param name="data1">The first data part of the message.</param>
/// <param name="data2">The second data part of the message.</param>
typedef MessageHook = void Function(
  Synthesizer synthesizer,
  int channel,
  int command,
  int data1,
  int data2,
);
