class NoteResultDetail {
  final int noteIndex;
  final String expectedNote;
  final String playedNote;
  final String lyric;
  final double expectedSecond;
  final double playedSecond;
  final double timingErrorMs;
  final String judgeResult;

  NoteResultDetail({
    required this.noteIndex,
    required this.expectedNote,
    required this.playedNote,
    required this.lyric,
    required this.expectedSecond,
    required this.playedSecond,
    required this.timingErrorMs,
    required this.judgeResult,
  });
}
