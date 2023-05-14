import 'src/binary_reader.dart';

/// Reperesents the version of a SoundFont.
class SoundFontVersion {
  final int major;
  final int minor;

  SoundFontVersion({required this.major, required this.minor});

  factory SoundFontVersion.fromReader(BinaryReader reader) {
    int major = reader.readInt16();
    int minor = reader.readInt16();
    return SoundFontVersion(major: major, minor: minor);
  }

  /// Gets the string representation of the version.
  @override
  String toString() {
    return "$major.$minor";
  }
}
