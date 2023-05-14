import 'i_audio_renderer.dart';
import 'utils/span.dart';
import 'utils/short.dart';

/// <summary>
/// Provides utility methods to convert the format of samples.
/// </summary>
extension IAudioRendererEx on IAudioRenderer {
  /// <summary>
  /// Renders the waveform as a stereo interleaved signal.
  /// </summary>
  /// <param name="renderer">The audio renderer.</param>
  /// <param name="destination">The destination buffer.</param>
  /// <remarks>
  /// This utility method internally uses <see cref="ArrayPool{T}"/>,
  /// which may result in memory allocation on the first call.
  /// To completely avoid memory allocation,
  /// use <see cref="IAudioRenderer.Render(Span{float}, Span{float})"/>.
  /// </remarks>
  void renderInterleaved(Span<double> destination) {
    final IAudioRenderer renderer = this;

    if (destination.length % 2 != 0) {
      throw "The length of the destination buffer must be even.";
    }

    final sampleCount = (destination.length / 2).round();
    final bufferLength = destination.length;

    //var buffer = ArrayPool<float>.Shared.Rent(bufferLength);
    final buffer = List<double>.filled(bufferLength, 0);

    try {
      final left = buffer.span(0, sampleCount);
      final right = buffer.span(sampleCount, sampleCount);
      renderer.render(left, right);

      var pos = 0;
      for (var t = 0; t < sampleCount; t++) {
        destination[pos++] = left[t];
        destination[pos++] = right[t];
      }
    } catch (e) {
      print('error in renderInterleaved: $e');
    }
  }

  /// <summary>
  /// Renders the waveform as a monaural signal.
  /// </summary>
  /// <param name="renderer">The audio renderer.</param>
  /// <param name="destination">The destination buffer.</param>
  /// <remarks>
  /// This utility method internally uses <see cref="ArrayPool{T}"/>,
  /// which may result in memory allocation on the first call.
  /// To completely avoid memory allocation,
  /// use <see cref="IAudioRenderer.Render(Span{float}, Span{float})"/>.
  /// </remarks>
  void renderMono(Span<double> destination) {
    final IAudioRenderer renderer = this;

    final sampleCount = destination.length;
    final bufferLength = destination.length * 2;

    //var buffer = ArrayPool<float>.Shared.Rent(bufferLength);
    final buffer = List<double>.filled(bufferLength, 0);

    try {
      final left = buffer.span(0, sampleCount);
      final right = buffer.span(sampleCount, sampleCount);
      renderer.render(left, right);

      for (var t = 0; t < sampleCount; t++) {
        destination[t] = (left[t] + right[t]) / 2;
      }
    } catch (e) {
      print('error in renderMono: $e');
    }
  }

  /// <summary>
  /// Renders the waveform with 16-bit quantization.
  /// </summary>
  /// <param name="renderer">The audio renderer.</param>
  /// <param name="left">The buffer of the left channel to store the rendered waveform.</param>
  /// <param name="right">The buffer of the right channel to store the rendered waveform.</param>
  /// <remarks>
  /// Out of range samples will be clipped.
  /// This utility method internally uses <see cref="ArrayPool{T}"/>,
  /// which may result in memory allocation on the first call.
  /// To completely avoid memory allocation,
  /// use <see cref="IAudioRenderer.Render(Span{float}, Span{float})"/>.
  /// The output buffers for the left and right must be the same length.
  /// </remarks>
  void renderInt16(Span<int> left, Span<int> right) {
    final IAudioRenderer renderer = this;

    if (left.length != right.length) {
      throw "The output buffers for the left and right must be the same length.";
    }

    final sampleCount = left.length;
    final bufferLength = 2 * left.length;

    final buffer = List<double>.filled(bufferLength, 0);

    try {
      final bufLeft = buffer.span(0, sampleCount);
      final bufRight = buffer.span(sampleCount, sampleCount);
      renderer.render(bufLeft, bufRight);

      for (var t = 0; t < sampleCount; t++) {
        var sample = 32768 * bufLeft[t];
        if (sample < Short.MinValue) {
          sample = Short.MinValue.toDouble();
        } else if (sample > Short.MaxValue) {
          sample = Short.MaxValue.toDouble();
        }

        left[t] = sample.toInt();
      }

      for (var t = 0; t < sampleCount; t++) {
        var sample = 32768 * bufRight[t];
        if (sample < Short.MinValue) {
          sample = Short.MinValue.toDouble();
        } else if (sample > Short.MaxValue) {
          sample = Short.MaxValue.toDouble();
        }

        right[t] = sample.toInt();
      }
    } catch (e) {
      print('error in renderInt16: $e');
    }
  }

  /// <summary>
  /// Renders the waveform as a stereo interleaved signal with 16-bit quantization.
  /// </summary>
  /// <param name="renderer">The audio renderer.</param>
  /// <param name="destination">The destination buffer.</param>
  /// <remarks>
  /// Out of range samples will be clipped.
  /// This utility method internally uses <see cref="ArrayPool{T}"/>,
  /// which may result in memory allocation on the first call.
  /// To completely avoid memory allocation,
  /// use <see cref="IAudioRenderer.Render(Span{float}, Span{float})"/>.
  /// </remarks>
  void renderInterleavedInt16(Span<int> destination) {
    final IAudioRenderer renderer = this;

    if (destination.length % 2 != 0) {
      throw "The length of the destination buffer must be even.";
    }

    final sampleCount = (destination.length / 2).round();
    final bufferLength = destination.length;

    final buffer = List<double>.filled(bufferLength, 0);

    try {
      final left = buffer.span(0, sampleCount);
      final right = buffer.span(sampleCount, sampleCount);
      renderer.render(left, right);

      var pos = 0;
      for (var t = 0; t < sampleCount; t++) {
        var sampleLeft = 32768 * left[t];
        if (sampleLeft < Short.MinValue) {
          sampleLeft = Short.MinValue.toDouble();
        } else if (sampleLeft > Short.MaxValue) {
          sampleLeft = Short.MaxValue.toDouble();
        }

        var sampleRight = 32768 * right[t];
        if (sampleRight < Short.MinValue) {
          sampleRight = Short.MinValue.toDouble();
        } else if (sampleRight > Short.MaxValue) {
          sampleRight = Short.MaxValue.toDouble();
        }

        destination[pos++] = sampleLeft.toInt();
        destination[pos++] = sampleRight.toInt();
      }
    } catch (e) {
      print('error in renderInterleavedInt16: $e');
    }
  }

  /// <summary>
  /// Renders the waveform as a monaural signal with 16-bit quantization.
  /// </summary>
  /// <param name="renderer">The audio renderer.</param>
  /// <param name="destination">The destination buffer.</param>
  /// <remarks>
  /// Out of range samples will be clipped.
  /// This utility method internally uses <see cref="ArrayPool{T}"/>,
  /// which may result in memory allocation on the first call.
  /// To completely avoid memory allocation,
  /// use <see cref="IAudioRenderer.Render(Span{float}, Span{float})"/>.
  /// </remarks>
  void renderMonoInt16(Span<int> destination) {
    final IAudioRenderer renderer = this;

    final sampleCount = destination.length;
    final bufferLength = 2 * destination.length;

    final buffer = List<double>.filled(bufferLength, 0);

    try {
      final left = buffer.span(0, sampleCount);
      final right = buffer.span(sampleCount, sampleCount);
      renderer.render(left, right);

      for (var t = 0; t < sampleCount; t++) {
        var sample = 16384 * (left[t] + right[t]);
        if (sample < Short.MinValue) {
          sample = Short.MinValue.toDouble();
        } else if (sample > Short.MaxValue) {
          sample = Short.MaxValue.toDouble();
        }

        destination[t] = sample.toInt();
      }
    } catch (e) {
      print('error in renderMonoInt16: $e');
    }
  }
}
