import 'package:ews_flutter/models/elephant_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ElephantCounts adds, totals and never goes below zero', () {
    var c = ElephantCounts();
    c = c.change(ElephantType.loneMale, 3);
    c = c.change(ElephantType.makhna, -1); // clamped at 0
    c = c.change(ElephantType.femaleCalf, 2);
    expect(c[ElephantType.makhna], 0);
    expect(c.total, 5);
    expect(c.summary, '3 Lone Male, 2 Female+Calf');
  });
}
