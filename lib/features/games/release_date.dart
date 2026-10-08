/// Reads an IGDB `first_release_date`, sent as Unix seconds or an RFC 3339
/// string.
///
/// The API sends 0 when IGDB has no date. The Unix epoch and the Go zero
/// time also mean unknown. These values and missing values return null, so
/// no screen shows 1970 for a game without a date. Set [isUtc] to build
/// Unix seconds as a UTC date; strings keep their own offset.
DateTime? parseReleaseDate(Object? value, {bool isUtc = false}) {
  final date = switch (value) {
    final num seconds => DateTime.fromMillisecondsSinceEpoch(
      (seconds * 1000).toInt(),
      isUtc: isUtc,
    ),
    final String text => DateTime.tryParse(text),
    _ => null,
  };
  if (date == null || date.millisecondsSinceEpoch == 0 || date.year <= 1) {
    return null;
  }
  return date;
}
