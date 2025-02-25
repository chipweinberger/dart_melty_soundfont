import 'dart:typed_data';

void multiplyAdd({
  required double factorA,
  required Float32List factorB,
  required Float32List dest,
}) {
  assert(factorB.length == dest.length);

  for (var i = 0; i < dest.length; i++) {
    dest[i] += factorA * factorB[i];
  }
}

void multiplyAddStep({
  required double factorA,
  required double step,
  required Float32List factorB,
  required Float32List dest,
}) {
  for (var i = 0; i < dest.length; i++) {
    dest[i] += factorA * factorB[i];
    factorA += step;
  }
}
