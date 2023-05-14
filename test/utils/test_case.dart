import 'package:test/test.dart';

void testCases<T>(
  String description,
  List<T> testCases,
  void Function(T) callback,
) {
  group(description, () {
    for (final testCase in testCases) {
      test(description, () => callback(testCase));
    }
  });
}
