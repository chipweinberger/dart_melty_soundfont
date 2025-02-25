import 'dart:typed_data';

import 'binary_reader.dart';

class ArrayInt16 {
  final ByteData bytes;

  ArrayInt16({required this.bytes});

  factory ArrayInt16.zeros({required int numShorts}) {
    Uint8List list = Uint8List(numShorts * 2);
    return ArrayInt16(bytes: list.buffer.asByteData());
  }

  factory ArrayInt16.empty() {
    return ArrayInt16.zeros(numShorts: 0);
  }

  factory ArrayInt16.fromReader(BinaryReader reader, int numShorts) {
    ByteData? data = reader.read(numShorts * 2);

    if (data == null) {
      throw "hit end of data";
    }

    return ArrayInt16(bytes: data);
  }

  operator [](int idx) {
    int vv = bytes.getInt16(idx * 2, Endian.little);
    return vv;
  }

  operator []=(int idx, int value) {
    return bytes.setInt16(idx * 2, value, Endian.little);
  }
}
