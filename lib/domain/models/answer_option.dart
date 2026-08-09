/// خيار إعرابيّ واحد يُعرض على اللاعب بوصفه طريقًا في العالم، لا زرًّا في واجهة.
class AnswerOption {
  const AnswerOption({
    required this.id,
    required this.label,
    this.misconception,
    this.nudge,
  });

  /// معرّف ثابت للموضوع النحويّ الذي يمثّله هذا الخيار (مثل: fael).
  final String id;

  /// النصّ العربيّ المعروض على البوابة (مثل: «فاعل»).
  final String label;

  /// سببُ وقوع المتعلّم في هذا الخطأ — يُستعمل لاحقًا في التشخيص الدقيق.
  /// يكون `null` في الخيار الصحيح.
  final String? misconception;

  /// كلمةُ المعلّم حين يقع اللاعب في هذا الخطأ بعينه: سؤالٌ يستنطق فكرَه،
  /// أو تعليلٌ لطيفٌ للصواب. تُعرض على اللافتة دون أن تُشعره بالإخفاق.
  final String? nudge;

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'] as String,
      label: json['label'] as String,
      misconception: json['misconception'] as String?,
      nudge: json['nudge'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (misconception != null) 'misconception': misconception,
        if (nudge != null) 'nudge': nudge,
      };

  @override
  bool operator ==(Object other) =>
      other is AnswerOption && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);

  @override
  String toString() => 'AnswerOption($id: $label)';
}
