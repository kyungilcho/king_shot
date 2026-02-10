String formatMmSs(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 5999).toInt();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
