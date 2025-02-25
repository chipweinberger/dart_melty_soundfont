import 'binary_reader.dart';
import 'soundfont_version.dart';

/// The information of a SoundFont.
class SoundFontInfo {
  final SoundFontVersion version;
  final String targetSoundEngine;
  final String bankName;
  final String romName;
  final SoundFontVersion romVersion;
  final String creationDate;
  final String author;
  final String targetProduct;
  final String copyright;
  final String comments;
  final String tools;

  SoundFontInfo({
    required this.version,
    required this.targetSoundEngine,
    required this.bankName,
    required this.romName,
    required this.romVersion,
    required this.creationDate,
    required this.author,
    required this.targetProduct,
    required this.copyright,
    required this.comments,
    required this.tools,
  });

  factory SoundFontInfo.fromReader(BinaryReader reader) {
    String chunkId = reader.readFourCC();
    if (chunkId != 'LIST') {
      throw 'The LIST chunk was not found.';
    }

    int end = reader.readInt32();
    end += reader.pos;

    String listType = reader.readFourCC();
    if (listType != 'INFO') {
      throw "The type of the LIST chunk must be 'INFO', but was '$listType'.";
    }

    SoundFontVersion version = SoundFontVersion(major: 0, minor: 0);
    String targetSoundEngine = '';
    String bankName = '';
    String romName = '';
    SoundFontVersion romVersion = SoundFontVersion(major: 0, minor: 0);
    String creationDate = '';
    String author = '';
    String targetProduct = '';
    String copyright = '';
    String comments = '';
    String tools = '';

    while (reader.pos < end) {
      String id = reader.readFourCC();
      int size = reader.readInt32();

      switch (id) {
        case 'ifil':
          version = SoundFontVersion.fromReader(reader);
          break;
        case 'isng':
          targetSoundEngine = reader.readFixedLengthString(size);
          break;
        case 'INAM':
          bankName = reader.readFixedLengthString(size);
          break;
        case 'irom':
          romName = reader.readFixedLengthString(size);
          break;
        case 'iver':
          romVersion = SoundFontVersion.fromReader(reader);
          break;
        case 'ICRD':
          creationDate = reader.readFixedLengthString(size);
          break;
        case 'IENG':
          author = reader.readFixedLengthString(size);
          break;
        case 'IPRD':
          targetProduct = reader.readFixedLengthString(size);
          break;
        case 'ICOP':
          copyright = reader.readFixedLengthString(size);
          break;
        case 'ICMT':
          comments = reader.readFixedLengthString(size);
          break;
        case 'ISFT':
          tools = reader.readFixedLengthString(size);
          break;
        default:
          throw "The INFO list contains an unknown ID '$id'.";
      }
    }

    return SoundFontInfo(
      version: version,
      targetSoundEngine: targetSoundEngine,
      bankName: bankName,
      romName: romName,
      romVersion: romVersion,
      creationDate: creationDate,
      author: author,
      targetProduct: targetProduct,
      copyright: copyright,
      comments: comments,
      tools: tools,
    );
  }

  /// Gets the name of the SoundFont.
  @override
  String toString() {
    return bankName;
  }
}
