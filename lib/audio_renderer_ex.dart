






import 'audio_renderer.dart';
import 'array_int16.dart';


/// Provides utility methods to convert the format of samples.
extension AudioRenderEx on AudioRenderer
{
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
    void renderInterleaved(List<double> destination, {int offset = 0, int? length})
    {
        if (destination.length % 2 != 0)
        {
            throw "The length of the destination buffer must be even.";
        }

        int sampleCount = 0;

        if (length != null) {
          sampleCount = length;
        } else {
          sampleCount = destination.length ~/ 2;
          sampleCount -= offset;
        }

        List<double> left = List<double>.filled(sampleCount, 0);
        List<double> right = List<double>.filled(sampleCount, 0);

        render(left, right);

        for (var t = 0; t < sampleCount; t++)
        {
            destination[offset + t * 2 + 0] = left[t];
            destination[offset + t * 2 + 1] = right[t];
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
    void renderMono(List<double> destination, {int offset = 0})
    {
        int sampleCount = destination.length ~/ 2;

        sampleCount -= offset;

        List<double> left = List<double>.filled(sampleCount, 0);
        List<double> right = List<double>.filled(sampleCount, 0);

        render(left, right);

        for (var t = 0; t < sampleCount; t++)
        {
            destination[offset + t] = (left[t] + right[t]) / 2;
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
    void renderInterleavedInt16(ArrayInt16 destination, {int offset = 0, int? length})
    {
        if (destination.bytes.lengthInBytes % 4 != 0)
        {
            throw "Invalid destination length";
        }

        int sampleCount = 0;

        if (length != null) {
          sampleCount = length;
        } else {
          sampleCount = destination.bytes.lengthInBytes ~/ 4;
          sampleCount -= offset;
        }

        List<double> left = List<double>.filled(sampleCount, 0);
        List<double> right = List<double>.filled(sampleCount, 0);

        render(left, right);

        for (var t = 0; t < sampleCount; t++)
        {
            int sampleLeft = (32768 * left[t]).toInt();
            var sampleRight = (32768 * right[t]).toInt();

            // these get automaticall casted to shorts in ArrayInt16[]
            destination[offset + t * 2 + 0] = sampleLeft;
            destination[offset + t * 2 + 1] = sampleRight;
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
    void renderMonoInt16(ArrayInt16 destination, {int offset = 0, int? length})
    {
        if (destination.bytes.lengthInBytes % 2 != 0)
        {
            throw "Invalid destination length";
        }

        int sampleCount = 0;

        if (length != null) {
          sampleCount = length;
        } else {
          sampleCount = destination.bytes.lengthInBytes ~/ 2;
          sampleCount -= offset;
        }

        List<double> left = List<double>.filled(sampleCount, 0);
        List<double> right = List<double>.filled(sampleCount, 0);

        render(left, right);

        for (var t = 0; t < sampleCount; t++)
        {
            int sample = (16384 * (left[t] + right[t])).toInt();
            destination[offset + t] = sample;
        }
    }
}

