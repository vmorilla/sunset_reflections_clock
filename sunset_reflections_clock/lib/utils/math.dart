typedef LerpFn<T> = T Function(T a, T b, double t);

double Function(double) makeInterpolationDouble(
        List<double> inputRange, List<double> outputRange,
        [double min, double max]) =>
    makeInterpolation(
        inputRange, outputRange, (a, b, t) => a + (b - a) * t, min, max);

double Function(T) makeInterpolationDoubleT<T>(List<T> inputRange,
        List<double> outputRange, double Function(T) mapInput,
        [T min, T max]) =>
    makeInterpolationT(inputRange, outputRange, (a, b, t) => a + (b - a) * t,
        mapInput, min, max);

T Function(double) makeInterpolation<T>(
    List<double> inputRange, List<T> outputRange, LerpFn<T> lerpFn,
    [double min, double max]) {
  if (inputRange.length != outputRange.length)
    throw ArgumentError('"inputRange" and "outputRange" lengths must match.');
  if (min != null && max == null || min == null && max != null)
    throw ArgumentError('"min" and "max" values must both be defined or null.');
  if (min != null && max != null && max == min)
    throw ArgumentError('"min" and "max" cannot have the same value.');

  double lerp(double min, double max, double value) =>
      (value - min) / (max - min);

  double normalizeInput(double input) {
    if (min == null) return input;
    final norm = lerp(min, max, input);
    final normPositive = norm - norm.floor();

    return normPositive;
  }

  final normInputRange = inputRange.map(normalizeInput).toList();

  return (double input) {
    final normInput = normalizeInput(input);

    if (normInput < normInputRange[0]) {
      if (min != null) {
        final lowInput = min - (max - normInputRange.last);
        final highInput = normInputRange.first;
        final normValue = lerp(lowInput, highInput, normInput);
        return lerpFn(outputRange.last, outputRange.first, normValue);
      } else
        return outputRange.first;
    }

    for (var i = 0; i < normInputRange.length - 1; i++) {
      final inputRangeHigh = inputRange[i + 1];
      if (input < inputRangeHigh) {
        final inputRangeLow = inputRange[i];
        final normalInput =
            (input - inputRangeLow) / (inputRangeHigh - inputRangeLow);

        return lerpFn(outputRange[i], outputRange[i + 1], normalInput);
      }
    }

    if (min != null) {
      final lowInput = normInputRange.last;
      final highInput = max + normInputRange.first - min;

      final normValue = lerp(lowInput, highInput, normInput);
      return lerpFn(outputRange.last, outputRange.first, normValue);
    } else
      return outputRange.last;
  };
}

O Function(I) makeInterpolationT<I, O>(List<I> inputRange, List<O> outputRange,
    LerpFn<O> lerpFn, double Function(I) mapInput,
    [I min, I max]) {
  final interpolation = makeInterpolation(
      inputRange.map(mapInput).toList(),
      outputRange,
      lerpFn,
      min != null ? mapInput(min) : null,
      max != null ? mapInput(max) : null);

  return (I input) => interpolation(mapInput(input));
}
