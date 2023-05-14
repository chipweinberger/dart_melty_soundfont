void multiplyAdd(
  double a,
  List<double> x,
  List<double> destination,
) {
  for (int i = 0; i < destination.length; i++) {
    destination[i] += a * x[i];
  }
}

void multiplyAddStep(
  double a,
  double step,
  List<double> x,
  List<double> destination,
) {
  for (int i = 0; i < destination.length; i++) {
    destination[i] += a * x[i];
    a += step;
  }
}
