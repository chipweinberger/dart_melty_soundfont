import 'dart:math';

import 'complex.dart';

/**
 * Returns the radix-2 fast fourier transform of the given array.
 * Optionally computes the radix-2 inverse fast fourier transform.
 *
 * @param {List<Complex>} inputData
 * @param {bool} [inverse]
 * @return {List<Complex>}
 */
List<Complex> fastFourierTransform(
  List<Complex> inputData, {
  bool inverse = false,
}) {
  final bitsCount = _bitLength(inputData.length - 1);
  final N = 1 << bitsCount;

  while (inputData.length < N) {
    inputData.add(Complex.zero());
  }

  final output = List.generate(N, (index) => Complex.zero());

  for (int dataSampleIndex = 0; dataSampleIndex < N; dataSampleIndex++) {
    output[dataSampleIndex] =
        inputData[reverseBits(dataSampleIndex, bitsCount)];
  }

  for (int blockLength = 2; blockLength <= N; blockLength *= 2) {
    final imaginarySign = inverse ? -1 : 1;
    final phaseStep = Complex(
      cos(2 * pi / blockLength),
      imaginarySign * sin(2 * pi / blockLength),
    );

    for (int blockStart = 0; blockStart < N; blockStart += blockLength) {
      Complex phase = Complex(1, 0);

      for (int signalId = blockStart;
          signalId < (blockStart + blockLength / 2);
          signalId++) {
        final idx = (signalId + blockLength / 2).toInt();
        final component = output[idx] * phase;

        final upd1 = output[signalId] + component;
        final upd2 = output[signalId] - component;

        output[signalId] = upd1;
        output[idx] = upd2;

        phase *= phaseStep;
      }
    }
  }

  if (inverse) {
    for (int signalId = 0; signalId < N; signalId++) {
      output[signalId] /= N.toComplex();
    }
  }

  return output;
}

/**
 * Returns the number of bits in the binary representation of the given number.
 *
 * @param {int} number
 * @return {int}
 */
int _bitLength(int number) {
  int bitLength = 0;
  // while (number > 0) {
  //   number >>= 1;
  //   bitLength++;
  // }

  while ((1 << bitLength) <= number) {
    bitLength += 1;
  }

  return bitLength;
}

int reverseBits(int val, int width) {
  int result = 0;
  for (var i = 0; i < width; i++) {
    result = (result << 1) | (val & 1);
    val >>>= 1;
  }
  return result;
}
