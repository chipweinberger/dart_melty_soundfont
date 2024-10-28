import 'dart:math' as math;

import 'midi_file.dart';
import 'synthesizer.dart';
import 'audio_renderer.dart';
import 'list_slice.dart';


/// <summary>
/// An instance of the MIDI file sequencer.
/// </summary>
/// <remarks>
/// Note that this class does not provide thread safety.
/// If you want to control playback and render the waveform in separate threads,
/// you must make sure that the methods are not called at the same time.
/// </remarks>
class MidiFileSequencer implements AudioRenderer {
  final Synthesizer synthesizer;

  double _speed = 1.0;

  MidiFile? _midiFile;
  bool? _loop;

  int _blockWrote = 0;

  Duration _currentTime = Duration.zero;
  int _msgIndex = 0;
  int _loopIndex = 0;

  MessageHook? onSendMessage;

  /// <summary>
  /// Initializes a new instance of the sequencer.
  /// </summary>
  /// <param name="synthesizer">The synthesizer to be used by the sequencer.</param>
  MidiFileSequencer(this.synthesizer);

  /// <summary>
  /// Plays the MIDI file.
  /// </summary>
  /// <param name="midiFile">The MIDI file to be played.</param>
  /// <param name="loop">If <c>true</c>, the MIDI file loops after reaching the end.</param>
  void play(MidiFile midiFile, {required bool loop}) {
    _midiFile = midiFile;
    _loop = loop;

    _blockWrote = synthesizer.blockSize;

    _currentTime = Duration.zero;
    _msgIndex = 0;
    _loopIndex = 0;

    synthesizer.reset();
  }

  /// <summary>
  /// Stops playing.
  /// </summary>
  void stop() {
    _midiFile = null;

    synthesizer.reset();
  }

  /// <inheritdoc/>
  void render(List<double> left, List<double> right) {
    if (left.length != right.length) {
      throw "The output buffers for the left and right must be the same length.";
    }

    var wrote = 0;
    while (wrote < left.length) {
      if (_blockWrote == synthesizer.blockSize) {
        _processEvents();
        _blockWrote = 0;
        _currentTime += MidiFile.getTimeSpanFromSeconds(
            _speed * synthesizer.blockSize / synthesizer.sampleRate);
      }

      var srcRem = synthesizer.blockSize - _blockWrote;
      var dstRem = left.length - wrote;
      var rem = math.min(srcRem, dstRem);

      synthesizer.render(left.slice(wrote, rem), right.slice(wrote, rem));

      _blockWrote += rem;
      wrote += rem;
    }
  }

  void _processEvents() {
    if (_midiFile == null) {
      return;
    }

    while (_msgIndex < _midiFile!.messages.length) {
      var time = _midiFile!.times[_msgIndex];
      var msg = _midiFile!.messages[_msgIndex];
      if (time <= _currentTime) {
        if (msg.type == MidiMessageType.normal) {
          if (onSendMessage == null) {
            synthesizer.processMidiMessage(
                channel: msg.channel,
                command: msg.command,
                data1: msg.data1,
                data2: msg.data2);
          } else {
            onSendMessage!(
                synthesizer, msg.channel, msg.command, msg.data1, msg.data2);
          }
        } else if (_loop == true) {
          if (msg.type == MidiMessageType.loopStart) {
            _loopIndex = _msgIndex;
          } else if (msg.type == MidiMessageType.loopEnd) {
            _currentTime = _midiFile!.times[_loopIndex];
            _msgIndex = _loopIndex;
            synthesizer.noteOffAll();
          }
        }
        _msgIndex++;
      } else {
        break;
      }
    }

    if (_msgIndex == _midiFile!.messages.length && _loop == true) {
      _currentTime = _midiFile!.times[_loopIndex];
      _msgIndex = _loopIndex;
      synthesizer.noteOffAll();
    }
  }

  /// <summary>
  /// Gets the currently playing MIDI file.
  /// </summary>
  MidiFile? get midiFile => _midiFile;

  /// <summary>
  /// Gets the current playback position.
  /// </summary>
  Duration get position => _currentTime;

  /// <summary>
  /// Gets a value that indicates whether the current playback position is at the end of the sequence.
  /// </summary>
  /// <remarks>
  /// If the <see cref="Play(MidiFile, bool)">Play</see> method has not yet been called, this value is true.
  /// This value will never be <c>true</c> when loop playback is enabled.
  /// </remarks>
  bool get endOfSequence {
    if (midiFile == null) {
      return true;
    } else {
      return _msgIndex == midiFile!.messages.length;
    }
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
    if (value >= 0) {
      _speed = value;
    } else {
      throw "The playback speed must be a non-negative value.";
    }
  }
}

/// <summary>
/// Represents the method that is called each time a MIDI message is processed during playback.
/// </summary>
/// <param name="synthesizer">The synthesizer used by the sequencer.</param>
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
