


import 'dart:typed_data';
import 'dart:io';


class BinaryReader
{

  final Uint8List bytes;
  int pos = 0;

  BinaryReader({required this.bytes});

  // reads entire file into memory
  factory BinaryReader.fromFile(String url) {
    File file = File(url);
    file.openRead();
    Uint8List bytes = file.readAsBytesSync();
    return BinaryReader(bytes:bytes);
  }

  factory BinaryReader.fromByteData(ByteData data) {

    Uint8List u8 = Uint8List(data.lengthInBytes);

    // copy to Uint8List
    for (int i = 0; i < data.lengthInBytes; i++) {
      u8[i] = data.getUint8(i);
    }
    
    return BinaryReader(bytes:u8);
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

      if(data == null){
        throw 'no more data';
      }

      return data.getUint8(0);
  }

  int readInt8() {
    
      ByteData? data = read(1);

      if(data == null){
        throw 'no more data';
      }

      return data.getInt8(0);
  }

  int readInt16() {
    
      ByteData? data = read(2);

      if(data == null){
        throw 'no more data';
      }

      return data.getInt16(0, Endian.little);
  }

  int readUInt16() {
    
      ByteData? data = read(2);

      if(data == null){
        throw 'no more data';
      }

      return data.getUint16(0, Endian.little);
  }

  int readInt32() {
    
      ByteData? data = read(4);

      if(data == null){
        throw 'no more data';
      }

      return data.getInt32(0, Endian.little);
  }

  int readUInt32() {
    
      ByteData? data = read(4);

      if(data == null){
        throw 'no more data';
      }

      return data.getUint32(0, Endian.little);
  }

  String readFourCC()
  {
      ByteData? dataIn = read(4);

      if(dataIn == null){
        throw 'no more data';
      }

      Uint8List byteList = Uint8List(4);

      for (int i = 0; i < byteList.length; i++)
      {
          byteList[i] = dataIn.getUint8(i);
      }

      String out = String.fromCharCodes(byteList);

      return out;
  }

  String readFixedLengthString(int length)
  {
      ByteData? data = read(length);

      if(data == null){
        throw 'no more data';
      }

      Uint8List byteList = Uint8List(length);

      for(int i = 0; i < length; i++) {
        byteList[i] = data.getUint8(i);
      }

      String out = String.fromCharCodes(byteList);

      return out;
  }

  int readInt16BigEndian()
  {
      int value = readInt16();
      int b1 = 0xFF & (value >> 0);
      int b2 = 0xFF & (value >> 8);
      return ((b1 << 8) | b2);
  }

  int readInt32BigEndian()
  {
      int value = readInt32();
      int b1 = 0xFF & (value >> 0);
      int b2 = 0xFF & (value >> 8);
      int b3 = 0xFF & (value >> 16);
      int b4 = 0xFF & (value >> 24);
      return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
  }

  int readMidiVariablelength()
  {
      var acc = 0;
      var count = 0;
      while (true)
      {
          var value = readUInt8();
          acc = (acc << 7) | (value & 127);
          if ((value & 128) == 0)
          {
              break;
          }
          count++;
          if (count == 4)
          {
              throw "The length of the value must be equal to or less than 4.";
          }
      }
      return acc;
  }
}

