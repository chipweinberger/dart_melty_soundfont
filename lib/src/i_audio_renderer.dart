import 'utils/span.dart';

/// <summary>
/// Defines a common interface for audio rendering.
/// </summary>
abstract class IAudioRenderer {
  /// <summary>
  /// Renders the waveform.
  /// </summary>
  /// <param name="left">The buffer of the left channel to store the rendered waveform.</param>
  /// <param name="right">The buffer of the right channel to store the rendered waveform.</param>
  /// <remarks>
  /// The output buffers for the left and right must be the same length.
  /// </remarks>
  void render(
    Span<double> left,
    Span<double> right,
  );
}
