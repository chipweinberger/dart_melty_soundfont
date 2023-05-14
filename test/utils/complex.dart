import 'dart:math';

class Complex {
  double real;
  double imaginary;

  Complex(this.real, this.imaginary);

  Complex.fromReal(this.real) : this.imaginary = 0;

  Complex.fromImaginary(this.imaginary) : this.real = 0;

  Complex.zero() : this(0, 0);

  Complex.i() : this(0, 1);

  Complex.fromPolar(double r, double theta)
      : this(r * cos(theta), r * sin(theta));

  Complex operator +(Complex other) {
    return Complex(real + other.real, imaginary + other.imaginary);
  }

  Complex operator -(Complex other) {
    return Complex(
      this.real - other.real,
      this.imaginary - other.imaginary,
    );
  }

  Complex operator *(Complex other) {
    return Complex(
      (this.real * other.real) - (this.imaginary * other.imaginary),
      (this.real * other.imaginary) + (this.imaginary * other.real),
    );
  }

  Complex operator /(Complex other) {
    double realAux =
        (this.real * other.real + this.imaginary * other.imaginary) /
            (other.real * other.real + other.imaginary * other.imaginary);
    double imaginaryAux =
        (this.imaginary * other.real - this.real * other.imaginary) /
            (other.real * other.real + other.imaginary * other.imaginary);
    return Complex(realAux, imaginaryAux);
  }

  Complex operator -() {
    return Complex(-real, -imaginary);
  }

  bool operator ==(Object other) {
    if (other is Complex) {
      return real == other.real && imaginary == other.imaginary;
    }
    return false;
  }

  int get hashCode => real.hashCode * 31 + imaginary.hashCode;

  String toString() => '($real + ${imaginary}i)';

  double norm() => real * real + imaginary * imaginary;

  Complex conjugate() => Complex(real, -imaginary);

  double magnitude() => sqrt(norm());
}

extension NumUtils on num {
  Complex toComplex() => Complex.fromReal(this.toDouble());
}
