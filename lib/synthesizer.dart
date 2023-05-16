﻿import 'dart:math';
import 'dart:typed_data';

import 'dart_melty_soundfont.dart';
import 'src/channel.dart';
import 'src/chorus.dart';
import 'src/instrument_region.dart';
import 'preset.dart';
import 'preset_region.dart';
import 'region_pair.dart';
import 'reverb.dart';
import 'soundfont.dart';
import 'soundfont_math.dart';
import 'src/array_math.dart';
import 'src/i_audio_renderer.dart';
import 'src/utils/span.dart';
import 'synthesizer_settings.dart';
import 'voice.dart';
import 'voice_collection.dart';

/// An instance of the SoundFont synthesizer.
/// Note: that this class does not provide thread safety.
/// If you want to send notes and render the waveform in separate threads,
/// you must ensure that the methods will not be called simultaneously.
class Synthesizer extends IAudioRenderer {
  // Public:

  static const int channelCount = 16;
  static const int percussionChannel = 9;

  final SoundFont soundFont;
  final int sampleRate;
  final int blockSize;
  final int maximumPolyphony;

  final int minimumVoiceDuration;

  // 'Channel's take this Synthesizer in their constructor,
  // so must be 'late' initialized to avoid circular dependency
  late List<Channel> channels;

  double masterVolume;

  // Private:

  // 'VoiceCollection's take this Synthesizer in their constructor,
  // so must be 'late' initialized to avoid circular dependency
  late VoiceCollection _voices;

  final Map<int, Preset> _presetLookup;

  final List<double> _blockLeft;
  final List<double> _blockRight;

  final double _inverseBlockSize;

  final bool _enableReverbAndChorus;

  final Reverb? _reverb;
  final List<double>? _reverbInput;
  final List<double>? _reverbOutputLeft;
  final List<double>? _reverbOutputRight;

  final Chorus? _chorus;
  final List<double>? _chorusInputLeft;
  final List<double>? _chorusInputRight;
  final List<double>? _chorusOutputLeft;
  final List<double>? _chorusOutputRight;

  int _blockRead;

  Synthesizer({
    required this.soundFont,
    required this.sampleRate,
    required this.blockSize,
    required this.maximumPolyphony,
    required this.minimumVoiceDuration,
    required this.masterVolume,
    required Map<int, Preset> presetLookup,
    required List<double> blockLeft,
    required List<double> blockRight,
    required double inverseBlockSize,
    required int blockRead,
    required bool enableReverbAndChorus,
    required Reverb? reverb,
    required List<double>? reverbInput,
    required List<double>? reverbOutputLeft,
    required List<double>? reverbOutputRight,
    required Chorus? chorus,
    required List<double>? chorusInputLeft,
    required List<double>? chorusInputRight,
    required List<double>? chorusOutputLeft,
    required List<double>? chorusOutputRight,
  })  : _presetLookup = presetLookup,
        _blockLeft = blockLeft,
        _blockRight = blockRight,
        _inverseBlockSize = inverseBlockSize,
        _blockRead = blockRead,
        _enableReverbAndChorus = enableReverbAndChorus,
        _reverb = reverb,
        _reverbInput = reverbInput,
        _reverbOutputLeft = reverbOutputLeft,
        _reverbOutputRight = reverbOutputRight,
        _chorus = chorus,
        _chorusInputLeft = chorusInputLeft,
        _chorusInputRight = chorusInputRight,
        _chorusOutputLeft = chorusOutputLeft,
        _chorusOutputRight = chorusOutputRight;

  factory Synthesizer.withSampleRate(SoundFont soundFont, int sampleRate) {
    return Synthesizer.load(
      soundFont,
      SynthesizerSettings(sampleRate: sampleRate),
    );
  }

  factory Synthesizer.loadByteData(ByteData data,
      [SynthesizerSettings? settings]) {
    SoundFont sf = SoundFont.fromByteData(data);

    return Synthesizer.load(sf, settings ?? SynthesizerSettings());
  }

  factory Synthesizer.load(SoundFont soundFont, SynthesizerSettings settings) {
    Map<int, Preset> presetLookup = {};

    for (Preset preset in soundFont.presets) {
      int presetId = (preset.bankNumber << 16) | preset.patchNumber;

      presetLookup[presetId] = preset;
    }

    bool rc = settings.enableReverbAndChorus;

    Chorus? chorus = rc == false
        ? null
        : Chorus(
            sampleRate: settings.sampleRate,
            delay: 0.002,
            depth: 0.0019,
            frequency: 0.4,
          );

    Synthesizer synth = Synthesizer(
      soundFont: soundFont,
      sampleRate: settings.sampleRate,
      blockSize: settings.blockSize,
      maximumPolyphony: settings.maximumPolyphony,
      enableReverbAndChorus: settings.enableReverbAndChorus,
      minimumVoiceDuration: settings.sampleRate ~/ 500,
      presetLookup: presetLookup,
      blockLeft: List<double>.filled(settings.blockSize, 0),
      blockRight: List<double>.filled(settings.blockSize, 0),
      inverseBlockSize: 1.0 / settings.blockSize,
      blockRead: settings.blockSize,
      reverb: !rc ? null : Reverb.withSampleRate(settings.sampleRate),
      reverbInput: !rc ? null : List<double>.filled(settings.blockSize, 0),
      reverbOutputLeft: !rc ? null : List<double>.filled(settings.blockSize, 0),
      reverbOutputRight:
          !rc ? null : List<double>.filled(settings.blockSize, 0),
      chorus: chorus,
      chorusInputLeft: !rc ? null : List<double>.filled(settings.blockSize, 0),
      chorusInputRight: !rc ? null : List<double>.filled(settings.blockSize, 0),
      chorusOutputLeft: !rc ? null : List<double>.filled(settings.blockSize, 0),
      chorusOutputRight:
          !rc ? null : List<double>.filled(settings.blockSize, 0),
      masterVolume: 0.5,
    );

    // Channels & Voices must be set *after* the synth is constructed,
    // since they take the synthesizer ref in their constructor

    List<Channel> channels = [];

    for (int i = 0; i < channelCount; i++) {
      channels.add(Channel(synth, i == percussionChannel));
    }

    synth.channels = channels;
    synth._voices = VoiceCollection.create(synth, settings.maximumPolyphony);

    return synth;
  }

  void processMidiMessage(
      {required int channel,
      required int command,
      required int data1,
      required int data2}) {
    if (!(0 <= channel && channel < channels.length)) {
      return;
    }

    var channelInfo = channels[channel];

    switch (command) {
      case 0x80: // Note Off
        noteOff(channel: channel, key: data1);
        break;

      case 0x90: // Note On
        noteOn(channel: channel, key: data1, velocity: data2);
        break;

      case 0xB0: // Controller
        switch (data1) {
          case 0x00: // Bank Selection
            channelInfo.setBank(data2);
            break;

          case 0x01: // Modulation Coarse
            channelInfo.setModulationCoarse(data2);
            break;

          case 0x21: // Modulation Fine
            channelInfo.setModulationFine(data2);
            break;

          case 0x06: // Data Entry Coarse
            channelInfo.dataEntryCoarse(data2);
            break;

          case 0x26: // Data Entry Fine
            channelInfo.dataEntryFine(data2);
            break;

          case 0x07: // Channel Volume Coarse
            channelInfo.setVolumeCoarse(data2);
            break;

          case 0x27: // Channel Volume Fine
            channelInfo.setVolumeFine(data2);
            break;

          case 0x0A: // Pan Coarse
            channelInfo.setPanCoarse(data2);
            break;

          case 0x2A: // Pan Fine
            channelInfo.setPanFine(data2);
            break;

          case 0x0B: // Expression Coarse
            channelInfo.setExpressionCoarse(data2);
            break;

          case 0x2B: // Expression Fine
            channelInfo.setExpressionFine(data2);
            break;

          case 0x40: // Hold Pedal
            channelInfo.setHoldPedal(data2);
            break;

          case 0x5B: // Reverb Send
            channelInfo.setReverbSend(data2);
            break;

          case 0x5D: // Chorus Send
            channelInfo.setChorusSend(data2);
            break;

          case 0x65: // RPN Coarse
            channelInfo.setRpnCoarse(data2);
            break;

          case 0x64: // RPN Fine
            channelInfo.setRpnFine(data2);
            break;

          case 0x78: // All Sound Off
            noteOffAll(channel: channel, immediate: true);
            break;

          case 0x79: // Reset All Controllers
            resetAllControllers(channel: channel);
            break;

          case 0x7B: // All Note Off
            noteOffAll(channel: channel, immediate: false);
            break;
        }
        break;

      case 0xC0: // Program Change
        channelInfo.setPatch(data1);
        break;

      case 0xE0: // Pitch Bend
        channelInfo.setPitchBend(data1, data2);
        break;
    }
  }

  void noteOff({required int channel, required int key}) {
    if (!(0 <= channel && channel < channels.length)) {
      return;
    }

    for (Voice voice in _voices) {
      if (voice.channel() == channel && voice.key() == key) {
        voice.end();
      }
    }
  }

  void noteOn({required int channel, required int key, required int velocity}) {
    if (velocity == 0) {
      noteOff(channel: channel, key: key);
      return;
    }

    if (!(0 <= channel && channel < channels.length)) {
      return;
    }

    var channelInfo = channels[channel];

    var presetId = (channelInfo.bankNumber << 16) | channelInfo.patchNumber;

    Preset? preset = _presetLookup[presetId];

    if (preset == null) {
      return;
    }

    for (PresetRegion presetRegion in preset.regions) {
      if (presetRegion.contains(key, velocity)) {
        for (InstrumentRegion instrumentRegion
            in presetRegion.instrument.regions) {
          if (instrumentRegion.contains(key, velocity)) {
            var regionPair =
                RegionPair(preset: presetRegion, instrument: instrumentRegion);

            var voice = _voices.requestNew(instrumentRegion, channel);

            if (voice != null) {
              voice.start(regionPair, channel, key, velocity);
            }
          }
        }
      }
    }
  }

  /// Stops all the notes.
  /// immediate: stop immediately without the release sound.
  void noteOffAll({int? channel, bool immediate = false}) {
    if (immediate) {
      for (Voice voice in _voices) {
        if (channel == null || voice.channel() == channel) {
          voice.kill();
        }
      }
    } else {
      for (Voice voice in _voices) {
        if (channel == null || voice.channel() == channel) {
          voice.end();
        }
      }
    }
  }

  void resetAllControllers({int? channel}) {
    for (int i = 0; i < channels.length; i++) {
      if (channel == null || channel == i) {
        channels[i].resetAllControllers();
      }
    }
  }

  /// <summary>
  /// Resets the synthesizer.
  /// </summary>
  void reset() {
    _voices.clear();

    for (Channel ch in channels) {
      ch.reset();
    }

    if (_enableReverbAndChorus) {
      _reverb!.mute();
      _chorus!.mute();
    }

    _blockRead = blockSize;
  }

  /// <inheritdoc/>
  void render(Span<double> left, Span<double> right) {
    if (left.length != right.length) {
      throw "The output buffers must be the same length.";
    }

    var wrote = 0;

    while (wrote < left.length) {
      if (_blockRead == blockSize) {
        _renderBlock();
        _blockRead = 0;
      }

      // remainder
      var srcRemainder = blockSize - _blockRead;
      var dstRemainder = left.length - wrote;
      var remainder = min(srcRemainder, dstRemainder);

      for (int i = 0; i < remainder; i++) {
        left[wrote + i] = _blockLeft[_blockRead + i];
        right[wrote + i] = _blockRight[_blockRead + i];
      }

      _blockRead += remainder;
      wrote += remainder;
    }
  }

  void _renderBlock() {
    _voices.process();

    _blockLeft.fillRange(0, _blockLeft.length, 0);
    _blockRight.fillRange(0, _blockRight.length, 0);

    for (Voice voice in _voices) {
      var previousGainLeft = masterVolume * voice.previousMixGainLeft();
      var currentGainLeft = masterVolume * voice.currentMixGainLeft();

      _writeBlock(previousGainLeft, currentGainLeft, voice.block(), _blockLeft);

      var previousGainRight = masterVolume * voice.previousMixGainRight();
      var currentGainRight = masterVolume * voice.currentMixGainRight();

      _writeBlock(
          previousGainRight, currentGainRight, voice.block(), _blockRight);
    }

    if (_enableReverbAndChorus) {
      _chorusInputLeft!.fillRange(0, _chorusInputLeft!.length, 0);
      _chorusInputRight!.fillRange(0, _chorusInputRight!.length, 0);

      for (Voice voice in _voices) {
        var previousGainLeft =
            voice.previousChorusSend() * voice.previousMixGainLeft();
        var currentGainLeft =
            voice.currentChorusSend() * voice.currentMixGainLeft();

        _writeBlock(previousGainLeft, currentGainLeft, voice.block(),
            _chorusInputLeft!);

        var previousGainRight =
            voice.previousChorusSend() * voice.previousMixGainRight();
        var currentGainRight =
            voice.currentChorusSend() * voice.currentMixGainRight();

        _writeBlock(previousGainRight, currentGainRight, voice.block(),
            _chorusInputRight!);
      }

      _chorus!.process(
        inputLeft: _chorusInputLeft!,
        inputRight: _chorusInputRight!,
        outputLeft: _chorusOutputLeft!,
        outputRight: _chorusOutputRight!,
      );

      multiplyAdd(
        masterVolume,
        _chorusOutputLeft!,
        _blockLeft,
      );
      multiplyAdd(
        masterVolume,
        _chorusOutputRight!,
        _blockRight,
      );

      _reverbInput!.fillRange(0, _reverbInput!.length, 0);

      for (Voice voice in _voices) {
        var previousMixGain =
            voice.previousMixGainLeft() + voice.previousMixGainRight();
        var currentMixGain =
            voice.currentMixGainLeft() + voice.currentMixGainRight();

        var previousGain =
            _reverb!.inputGain() * voice.previousReverbSend() * previousMixGain;
        var currentGain =
            _reverb!.inputGain() * voice.currentReverbSend() * currentMixGain;

        _writeBlock(previousGain, currentGain, voice.block(), _reverbInput!);
      }

      _reverb!.process(_reverbInput!, _reverbOutputLeft!, _reverbOutputRight!);

      multiplyAdd(
        masterVolume,
        _reverbOutputLeft!,
        _blockLeft,
      );
      multiplyAdd(
        masterVolume,
        _reverbOutputRight!,
        _blockRight,
      );
    }
  }

  void _writeBlock(double previousGain, double currentGain, List<double> source,
      List<double> destination) {
    if (max(previousGain, currentGain) < SoundFontMath.nonAudible) {
      return;
    }

    if ((currentGain - previousGain).abs() < 1.0E-3) {
      multiplyAdd(
        currentGain,
        source,
        destination,
      );
    } else {
      var step = _inverseBlockSize * (currentGain - previousGain);

      multiplyAddStep(
        previousGain,
        step,
        source,
        destination,
      );
    }
  }

  int activeVoiceCount() => _voices.activeVoiceCount();
}

extension SynthesizerEx on Synthesizer {
  Uint8List pcm(int seconds) {
    final buf16 = ArrayInt16.zeros(numShorts: 44100 * seconds);
    renderMonoInt16(buf16);
    return buf16.bytes.buffer.asUint8List();
  }
}
