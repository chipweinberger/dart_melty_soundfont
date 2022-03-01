


import 'binary_reader.dart';
import 'generator_type.dart';

class Generator
{
    final GeneratorType type;
    final int value; // ushort

    Generator(this.type, this.value);

    factory Generator.fromReader(BinaryReader reader)
    {
        GeneratorType type = generatorTypeFromInt(reader.readUInt16());
        int value = reader.readUInt16();

        return Generator(type, value);
    }

    static List<Generator> readFromChunk(BinaryReader reader, int size)
    {
        if (size % 4 != 0)
        {
            throw "The generator list is invalid.";
        }

      // The last one is the terminator.
        int count = (size ~/ 4) - 1;

        List<Generator> generators = [];

        for (var i = 0; i < count; i++)
        {
            generators.add(
              Generator.fromReader(reader)
            );
        }

        // The last one is the terminator.
        Generator.fromReader(reader);

        return generators;
    }
}

