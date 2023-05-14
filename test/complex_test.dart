import 'package:test/test.dart';

import 'utils/complex.dart';

void main() {
  group('Complex number tests', () {
    test('should create a complex number with real and imaginary parts', () {
      final complex = Complex(1.0, 2.0);
      expect(complex.real, 1.0);
      expect(complex.imaginary, 2.0);
    });

    test(
      'Making sure that real numbers are properly converted into complex ones.',
      () {
        expect(Complex.fromReal(7).real, equals(7));
        expect(Complex.fromReal(7).imaginary, isZero);

        expect(Complex.fromImaginary(7).real, isZero);
        expect(Complex.fromImaginary(7).imaginary, equals(7));
      },
    );

    test("Making sure that named constructor for '0' and 'i' work.", () {
      final zero = Complex.zero();
      expect(zero.real, isZero);
      expect(zero.imaginary, isZero);

      final i = Complex.i();
      expect(i.real, isZero);
      expect(i.imaginary, equals(1));
    });

    test('Making sure that the sum between two complex numbers is correct', () {
      final value = Complex(3, -5) + Complex(-8, 13);
      expect(value.real, equals(-5));
      expect(value.imaginary, equals(8));

      final value2 = Complex.fromReal(5) + Complex.fromImaginary(-16);
      expect(value2.real, equals(5));
      expect(value2.imaginary, equals(-16));
    });

    test(
      'Making sure that the difference between two complex numbers is correct',
      () {
        final value = Complex(3, -5) - Complex(-8, 13);
        expect(value.real, equals(11));
        expect(value.imaginary, equals(-18));

        final value2 = Complex.fromReal(5) - Complex.fromImaginary(-16);
        expect(value2.real, equals(5));
        expect(value2.imaginary, equals(16));
      },
    );

    test(
      'Making sure that the product between two complex numbers is correct',
      () {
        final value = Complex(3, -5) * Complex(-8, 13);
        expect(value.real, equals(41));
        expect(value.imaginary, equals(79));

        final value2 = Complex.fromReal(5) * Complex.fromImaginary(-16);
        expect(value2.real, equals(0));
        expect(value2.imaginary, equals(-80));

        final value3 = Complex(1, 2) * Complex(3, 4);
        expect(value3.real, equals(-5));
        expect(value3.imaginary, equals(10));
      },
    );
  });
}
