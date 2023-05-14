import 'binary_reader.dart';
import 'generator_type.dart';

class Generator {
  late final GeneratorType _type;
  late final int _value; // ushort

  Generator(BinaryReader reader) {
    _type = generatorTypeFromInt(reader.readUInt16())!;
    _value = reader.readUInt16();
  }

  static List<Generator> readFromChunk(BinaryReader reader, int size) {
    if (size % 4 != 0) {
      throw "The generator list is invalid.";
    }

    // The last one is the terminator.
    int count = (size ~/ 4) - 1;

    List<Generator> generators = [];

    for (var i = 0; i < count; i++) {
      generators.add(Generator(reader));
    }

    // The last one is the terminator.
    Generator(reader);

    return generators;
  }

  GeneratorType get type => _type;
  int get value => _value;
}
