import 'package:dart_melty_soundfont/src/utils/span.dart';
import 'package:test/test.dart';

void main() {
  test('sanity', () {
    final buffer = List<double>.filled(20, 0);

    // Get sub list of first 10
    final left = buffer.span(0, 10);

    // Modify sub list
    left[0] = 1;

    // Check that the original list is modified
    expect(left[0], 1);
    expect(buffer[0], 1);
  });
}
