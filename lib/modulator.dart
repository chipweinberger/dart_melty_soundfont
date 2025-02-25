import 'binary_reader.dart';

class Modulator {
  // Since modulators will not be supported, we discard the data.
  static void discardData(BinaryReader reader, int size) {
    if (size % 10 != 0) {
      throw "The modulator list is invalid.";
    }

    reader.skip(size);
  }
}
