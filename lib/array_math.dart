void multiplyAdd({required double factorA, required List<double> factorB, required List<double> dest}) {
  assert(factorB.length == dest.length);

  for (var i = 0; i < dest.length; i++) {
    dest[i] += factorA * factorB[i];
  }
}

void multiplyAddStep(
    {required double factorA, required double step, required List<double> factorB, required List<double> dest}) {
  for (var i = 0; i < dest.length; i++) {
    dest[i] += factorA * factorB[i];
    factorA += step;
  }
}
