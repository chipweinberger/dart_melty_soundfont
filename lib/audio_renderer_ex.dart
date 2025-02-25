import 'dart:typed_data';

import 'audio_renderer.dart';

/// Provides utility methods to convert the format of samples.
extension AudioRenderEx on AudioRenderer {
  /// Renders the waveform as a stereo interleaved signal.
  void renderInterleaved(
    Float32List destination, {
    int offset = 0,
    int? length,
  }) {
    if (destination.length % 2 != 0) {
      throw 'The length of the destination buffer must be even.';
    }

    int sampleCount = length ?? (destination.length ~/ 2 - offset);

    final left = Float32List(sampleCount);
    final right = Float32List(sampleCount);

    render(left, right);

    for (var t = 0; t < sampleCount; t++) {
      destination[offset + t * 2] = left[t];
      destination[offset + t * 2 + 1] = right[t];
    }
  }

  /// Renders the waveform as a monaural signal.
  void renderMono(Float32List destination, {int offset = 0}) {
    int sampleCount = destination.length - offset;

    final left = Float32List(sampleCount);
    final right = Float32List(sampleCount);

    render(left, right);

    for (var t = 0; t < sampleCount; t++) {
      destination[offset + t] = (left[t] + right[t]) / 2;
    }
  }

  /// Renders the waveform as a stereo interleaved signal with 16-bit quantization.
  void renderInterleavedInt16(
    Int16List destination, {
    int offset = 0,
    int? length,
  }) {
    if (destination.length % 2 != 0) {
      throw 'Invalid destination length';
    }

    int sampleCount = length ?? (destination.length ~/ 2 - offset);

    final left = Float32List(sampleCount);
    final right = Float32List(sampleCount);

    render(left, right);

    for (var t = 0; t < sampleCount; t++) {
      // Clamp values between -32768 and 32767 to prevent overflow
      int sampleLeft = (32768 * left[t]).clamp(-32768, 32767).toInt();
      int sampleRight = (32768 * right[t]).clamp(-32768, 32767).toInt();

      destination[offset + t * 2] = sampleLeft;
      destination[offset + t * 2 + 1] = sampleRight;
    }
  }

  /// Renders the waveform as a monaural signal with 16-bit quantization.
  void renderMonoInt16(Int16List destination, {int offset = 0, int? length}) {
    int sampleCount = length ?? (destination.length - offset);

    final left = Float32List(sampleCount);
    final right = Float32List(sampleCount);

    render(left, right);

    for (var t = 0; t < sampleCount; t++) {
      // Mix to mono and convert to 16-bit integer with clamping
      int sample = (16384 * (left[t] + right[t])).clamp(-32768, 32767).toInt();
      destination[offset + t] = sample;
    }
  }
}
