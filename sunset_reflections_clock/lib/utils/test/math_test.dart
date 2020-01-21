import "package:test/test.dart";
import '../math.dart';

void main() {
  test("Circular interpolation", () {
    final fn = makeInterpolationDouble([0.2, 0.7], [2, 7], 0, 1);
    expect(fn(0.2), equals(2));
    expect(fn(0.7), equals(7));
    expect(fn(1.5), equals(5));
  });
}
