import 'dart:typed_data';

class BinaryReader {
  final Uint8List bytes;
  int pos = 0;

  BinaryReader(this.bytes);

  factory BinaryReader.fromByteData(ByteData data) {
    Uint8List u8 = Uint8List(data.lengthInBytes);

    // copy to Uint8List
    for (int i = 0; i < data.lengthInBytes; i++) {
      u8[i] = data.getUint8(i);
    }

    return BinaryReader(u8);
  }

  // read the next X bytes
  ByteData? read(int size) {
    if (bytes.length < pos + size) {
      return null;
    }
    ByteData view = ByteData.view(bytes.buffer, pos, size);
    pos += size;
    return view;
  }

  // skip the next X bytes
  int skip(int size) {
    pos += size;
    return size;
  }

  int readUInt8() {
    ByteData? data = read(1);

    if (data == null) {
      throw 'no more data';
    }

    return data.getUint8(0);
  }

  int readInt8() {
    ByteData? data = read(1);

    if (data == null) {
      throw 'no more data';
    }

    return data.getInt8(0);
  }

  int readInt16() {
    ByteData? data = read(2);

    if (data == null) {
      throw 'no more data';
    }

    return data.getInt16(0, Endian.little);
  }

  int readUInt16() {
    ByteData? data = read(2);

    if (data == null) {
      throw 'no more data';
    }

    return data.getUint16(0, Endian.little);
  }

  int readInt32() {
    ByteData? data = read(4);

    if (data == null) {
      throw 'no more data';
    }

    return data.getInt32(0, Endian.little);
  }

  int readUInt32() {
    ByteData? data = read(4);

    if (data == null) {
      throw 'no more data';
    }

    return data.getUint32(0, Endian.little);
  }
}
