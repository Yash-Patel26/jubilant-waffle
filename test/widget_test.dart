// Minimal test so CI `flutter test` does not fail with "Test directory test not found".
// Add real tests as the project grows.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    expect(1 + 1, 2);
  });
}
