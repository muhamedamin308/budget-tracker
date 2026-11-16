enum AutoLockTimeout {
  immediately(0, 'Immediately'),
  oneMinute(60, 'After 1 minute'),
  fiveMinutes(300, 'After 5 minutes'),
  fifteenMinutes(900, 'After 15 minutes');

  const AutoLockTimeout(this.seconds, this.label);
  final int seconds;
  final String label;

  static AutoLockTimeout fromSeconds(int? sec) {
    if (sec == null) return AutoLockTimeout.immediately;
    return AutoLockTimeout.values.firstWhere(
      (e) => e.seconds == sec,
      orElse: () => AutoLockTimeout.immediately,
    );
  }
}
