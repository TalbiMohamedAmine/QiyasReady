class GlobalMistake {
  const GlobalMistake({
    required this.questionId,
    required this.totalAttempts,
    required this.failureRate,
    required this.subject,
    required this.questionText,
    required this.staticExplanation,
    required this.correctAnswer,
    required this.popularWrongAnswer,
  });

  final String questionId;
  final int totalAttempts;
  final double failureRate;
  final String subject;
  final String questionText;
  final String staticExplanation;
  final String correctAnswer;
  final String popularWrongAnswer;

  bool get hasAiInputs =>
      questionText.trim().isNotEmpty &&
      correctAnswer.trim().isNotEmpty &&
      popularWrongAnswer.trim().isNotEmpty;
}
