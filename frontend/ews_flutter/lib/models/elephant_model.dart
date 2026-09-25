/// Herd categories used by the field forms.
enum ElephantType {
  loneMale('lm', 'Lone Male'),
  maleGroup('mg', 'Male Group'),
  femaleGroup('fg', 'Female Group'),
  femaleCalf('fc', 'Female+Calf'),
  singleFemale('sf', 'Single Female'),
  makhna('mk', 'Makhna');

  const ElephantType(this.key, this.label);
  final String key;
  final String label;
}

/// Immutable counter set: one number per [ElephantType].
class ElephantCounts {
  final Map<ElephantType, int> _c;

  ElephantCounts([Map<ElephantType, int>? init])
      : _c = {for (final t in ElephantType.values) t: init?[t] ?? 0};

  int operator [](ElephantType t) => _c[t] ?? 0;

  int get total => _c.values.fold(0, (a, b) => a + b);

  ElephantCounts change(ElephantType t, int delta) {
    final next = Map<ElephantType, int>.from(_c);
    next[t] = ((next[t] ?? 0) + delta).clamp(0, 999).toInt();
    return ElephantCounts(next);
  }

  /// e.g. "3 Lone Male, 1 Female+Calf"
  String get summary {
    final parts = <String>[
      for (final t in ElephantType.values)
        if (this[t] > 0) '${this[t]} ${t.label}',
    ];
    return parts.isEmpty ? 'No elephants' : parts.join(', ');
  }

  Map<String, dynamic> toJson() => {for (final e in _c.entries) e.key.key: e.value};

  factory ElephantCounts.fromJson(Map<String, dynamic>? j) => ElephantCounts({
        for (final t in ElephantType.values) t: (j?[t.key] as num?)?.toInt() ?? 0,
      });
}
