import 'dart:typed_data';
import 'binary_reader.dart';

extension BinaryReaderEx on BinaryReader {
  String readFourCC() {
    ByteData? dataIn = read(4);

    if (dataIn == null) {
      throw 'no more data';
    }

    Uint8List byteList = Uint8List(4);

    for (int i = 0; i < byteList.length; i++) {
      byteList[i] = dataIn.getUint8(i);
    }

    String out = String.fromCharCodes(byteList);

    return out;
  }

  String readFixedLengthString(int length) {
    ByteData? data = read(length);

    if (data == null) {
      throw 'no more data';
    }

    Uint8List byteList = Uint8List(length);

    for (int i = 0; i < length; i++) {
      byteList[i] = data.getUint8(i);
    }

    String out = String.fromCharCodes(byteList);

    return out;
  }

  int readInt16BigEndian() {
    int value = readInt16();
    int b1 = 0xFF & (value >> 0);
    int b2 = 0xFF & (value >> 8);
    return ((b1 << 8) | b2);
  }

  int readInt32BigEndian() {
    int value = readInt32();
    int b1 = 0xFF & (value >> 0);
    int b2 = 0xFF & (value >> 8);
    int b3 = 0xFF & (value >> 16);
    int b4 = 0xFF & (value >> 24);
    return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
  }

  int readMidiVariableLength() {
    var acc = 0;
    var count = 0;
    while (true) {
      var value = readUInt8();
      acc = (acc << 7) | (value & 127);
      if ((value & 128) == 0) {
        break;
      }
      count++;
      if (count == 4) {
        throw "The length of the value must be equal to or less than 4.";
      }
    }
    return acc;
  }

  int readIntVariableLength() {
    var acc = 0;
    var count = 0;
    while (true) {
      var value = readUInt8();
      acc = (acc << 7) | (value & 127);
      if ((value & 128) == 0) {
        break;
      }
      count++;
      if (count == 4) {
        throw "The length of the value must be equal to or less than 4.";
      }
    }
    return acc;
  }
}
