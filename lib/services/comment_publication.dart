Future<T> publishConfirmedComment<T>({
  required Future<T> Function() publish,
  required void Function(T value) onConfirmed,
  required Future<void> Function() clearDraft,
}) async {
  final value = await publish();
  onConfirmed(value);
  await clearDraft();
  return value;
}
