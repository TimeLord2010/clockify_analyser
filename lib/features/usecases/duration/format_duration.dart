String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  } else {
    return '${minutes}m';
  }
}
