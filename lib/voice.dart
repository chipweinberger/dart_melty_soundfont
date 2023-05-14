import 'modulation_envelope.dart';
import 'volume_envelope.dart';
import 'lfo.dart';
import 'oscillator.dart';
import 'bi_quad_filter.dart';
import 'synthesizer.dart';
import 'region_pair.dart';
import 'soundfont_math.dart';
import 'region_ex.dart';
import 'dart:math';
import 'channel.dart';

enum VoiceState { playing, releaseRequested, released }

class Voice {
  final Synthesizer synthesizer;

  final VolumeEnvelope _volEnv;
  final ModulationEnvelope _modEnv;

  final Lfo _vibLfo;
  final Lfo _modLfo;

  final Oscillator _oscillator;
  final BiQuadFilter _filter;

  final List<double> _block;

  // A sudden change in the mix gain will cause pop noise.
  // To avoid this, we save the mix gain of the previous block,
  // and smooth out the gain if the gap between the current and previous gain is too large.
  // The actual smoothing process is done in the WriteBlock method of the Synthesizer class.

  double _previousMixGainLeft = 0;
  double _previousMixGainRight = 0;
  double _currentMixGainLeft = 0;
  double _currentMixGainRight = 0;

  double _previousReverbSend = 0;
  double _previousChorusSend = 0;
  double _currentReverbSend = 0;
  double _currentChorusSend = 0;

  int _exclusiveClass = 0;
  int _channel = 0;
  int _key = 0;
  int _velocity = 0;

  double _noteGain = 0;

  double _cutoff = 0;
  double _resonance = 0;

  double _vibLfoToPitch = 0;
  double _modLfoToPitch = 0;
  double _modEnvToPitch = 0;

  int _modLfoToCutoff = 0;
  int _modEnvToCutoff = 0;
  bool _dynamicCutoff = false;

  double _modLfoToVolume = 0;
  bool _dynamicVolume = false;

  double _instrumentPan = 0;
  double _instrumentReverb = 0;
  double _instrumentChorus = 0;

  // Some instruments require fast cutoff change, which can cause pop noise.
  // This is used to smooth out the cutoff frequency.
  double _smoothedCutoff = 0;

  VoiceState _voiceState = VoiceState.playing;
  int _voiceLength = 0;

  Voice(this.synthesizer)
      : _volEnv = VolumeEnvelope(synthesizer),
        _modEnv = ModulationEnvelope(synthesizer),
        _vibLfo = Lfo(synthesizer),
        _modLfo = Lfo(synthesizer),
        _oscillator = Oscillator(synthesizer),
        _filter = BiQuadFilter(synthesizer),
        _block = List<double>.filled(synthesizer.blockSize, 0.0);

  void start(RegionPair region, int channel, int key, int velocity) {
    _exclusiveClass = region.exclusiveClass();
    _channel = channel;
    _key = key;
    _velocity = velocity;

    if (velocity > 0) {
      // According to the Polyphone's implementation, the initial attenuation should be reduced to 40%.
      // I'm not sure why, but this indeed improves the loudness variability.
      var sampleAttenuation = 0.4 * region.initialAttenuation();
      var filterAttenuation = 0.5 * region.initialFilterQ();

      var decibels = 2 * SoundFontMath.linearToDecibels(velocity / 127.0) -
          sampleAttenuation -
          filterAttenuation;

      _noteGain = SoundFontMath.decibelsToLinear(decibels);
    } else {
      _noteGain = 0;
    }

    _cutoff = region.initialFilterCutoffFrequency();
    _resonance = SoundFontMath.decibelsToLinear(region.initialFilterQ());

    _vibLfoToPitch = 0.01 * region.vibratoLfoToPitch();
    _modLfoToPitch = 0.01 * region.modulationLfoToPitch();
    _modEnvToPitch = 0.01 * region.modulationEnvelopeToPitch();

    _modLfoToCutoff = region.modulationLfoToFilterCutoffFrequency();
    _modEnvToCutoff = region.modulationEnvelopeToFilterCutoffFrequency();

    _dynamicCutoff = _modLfoToCutoff != 0 || _modEnvToCutoff != 0;

    _modLfoToVolume = region.modulationLfoToVolume();
    _dynamicVolume = _modLfoToVolume > 0.05;

    _instrumentPan = region.pan().clamp(-50.0, 50.0);
    _instrumentReverb = 0.01 * region.reverbEffectsSend();
    _instrumentChorus = 0.01 * region.chorusEffectsSend();

    _volEnv.start2(region, key, velocity);
    _modEnv.start2(region, key, velocity);
    _vibLfo.startVibrato2(region, key, velocity);
    _modLfo.startModulation2(region, key, velocity);

    _oscillator.start2(synthesizer.soundFont.waveData, region);

    _filter.clearBuffer();
    _filter.setLowPassFilter(_cutoff, _resonance);

    _smoothedCutoff = _cutoff;

    _voiceState = VoiceState.playing;
    _voiceLength = 0;
  }

  void end() {
    if (_voiceState == VoiceState.playing) {
      _voiceState = VoiceState.releaseRequested;
    }
  }

  void kill() {
    _noteGain = 0.0;
  }

  bool process() {
    if (_noteGain < SoundFontMath.nonAudible) {
      return false;
    }

    Channel channelInfo = synthesizer.channels[_channel];

    _releaseIfNecessary(channelInfo);

    if (!_volEnv.process()) {
      return false;
    }

    _modEnv.process();
    _vibLfo.process();
    _modLfo.process();

    var vibPitchChange =
        (0.01 * channelInfo.modulation() + _vibLfoToPitch) * _vibLfo.value();
    var modPitchChange =
        _modLfoToPitch * _modLfo.value() + _modEnvToPitch * _modEnv.value();
    var channelPitchChange = channelInfo.tune() + channelInfo.pitchBend();

    var pitch = _key + vibPitchChange + modPitchChange + channelPitchChange;

    if (!_oscillator.process(_block, pitch)) {
      return false;
    }

    if (_dynamicCutoff) {
      var cents =
          _modLfoToCutoff * _modLfo.value() + _modEnvToCutoff * _modEnv.value();
      var factor = SoundFontMath.centsToMultiplyingFactor(cents);
      var newCutoff = factor * _cutoff;

      // The cutoff change is limited within x0.5 and x2 to reduce pop noise.
      var lowerLimit = 0.5 * _smoothedCutoff;
      var upperLimit = 2.0 * _smoothedCutoff;

      if (newCutoff < lowerLimit) {
        _smoothedCutoff = lowerLimit;
      } else if (newCutoff > upperLimit) {
        _smoothedCutoff = upperLimit;
      } else {
        _smoothedCutoff = newCutoff;
      }

      _filter.setLowPassFilter(_smoothedCutoff, _resonance);
    }

    _filter.process(_block);

    _previousMixGainLeft = _currentMixGainLeft;
    _previousMixGainRight = _currentMixGainRight;
    _previousReverbSend = _currentReverbSend;
    _previousChorusSend = _currentChorusSend;

    // According to the GM spec, the following value should be squared.
    var ve = channelInfo.volume() * channelInfo.expression();
    var channelGain = ve * ve;

    double mixGain = _noteGain * channelGain * _volEnv.value();

    if (_dynamicVolume) {
      var decibels = _modLfoToVolume * _modLfo.value();
      mixGain *= SoundFontMath.decibelsToLinear(decibels);
    }

    double angle = (pi / 200.0) * (channelInfo.pan() + _instrumentPan + 50.0);

    if (angle <= 0.0) {
      _currentMixGainLeft = mixGain;
      _currentMixGainRight = 0.0;
    } else if (angle >= SoundFontMath.halfPi) {
      _currentMixGainLeft = 0.0;
      _currentMixGainRight = mixGain;
    } else {
      _currentMixGainLeft = mixGain * cos(angle);
      _currentMixGainRight = mixGain * sin(angle);
    }

    _currentReverbSend =
        (channelInfo.reverbSend() + _instrumentReverb).clamp(0, 1);
    _currentChorusSend =
        (channelInfo.chorusSend() + _instrumentChorus).clamp(0, 1);

    if (_voiceLength == 0) {
      _previousMixGainLeft = _currentMixGainLeft;
      _previousMixGainRight = _currentMixGainRight;
      _previousReverbSend = _currentReverbSend;
      _previousChorusSend = _currentChorusSend;
    }

    _voiceLength += synthesizer.blockSize;

    return true;
  }

  void _releaseIfNecessary(Channel channelInfo) {
    if (_voiceLength < synthesizer.minimumVoiceDuration) {
      return;
    }

    if (_voiceState == VoiceState.releaseRequested &&
        !channelInfo.holdPedal()) {
      _volEnv.release();
      _modEnv.release();
      _oscillator.release();

      _voiceState = VoiceState.released;
    }
  }

  double priority() {
    if (_noteGain < SoundFontMath.nonAudible) {
      return 0.0;
    } else {
      return _volEnv.priority();
    }
  }

  List<double> block() => _block;

  double previousMixGainLeft() => _previousMixGainLeft;
  double previousMixGainRight() => _previousMixGainRight;
  double currentMixGainLeft() => _currentMixGainLeft;
  double currentMixGainRight() => _currentMixGainRight;

  double previousReverbSend() => _previousReverbSend;
  double previousChorusSend() => _previousChorusSend;
  double currentReverbSend() => _currentReverbSend;
  double currentChorusSend() => _currentChorusSend;

  int exclusiveClass() => _exclusiveClass;
  int channel() => _channel;
  int key() => _key;
  int velocity() => _velocity;
}
