import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/question.dart';
import '../../domain/repositories/question_repository.dart';

/// يحمّل بنك الأسئلة من ملفّات JSON المرفقة بالتطبيق — فاللعبة تعمل بلا إنترنت.
///
/// الملفّات هي مصدرُ الحقيقة للمحتوى، ومراجعتُها تتمّ خارج الكود،
/// وهو ما يسمح بإضافة آلاف الأسئلة لاحقًا دون لمس سطرٍ برمجيّ واحد.
class AssetQuestionRepository implements QuestionRepository {
  AssetQuestionRepository({this.basePath = 'assets/content/questions'});

  final String basePath;

  final Map<int, List<Question>> _cache = {};

  @override
  Future<List<Question>> loadLevel(int level) async {
    final cached = _cache[level];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('$basePath/level_$level.json');
    final questions = parseLevel(raw);
    _cache[level] = questions;
    return questions;
  }

  /// يفصل التحليلَ عن القراءة ليكون قابلًا للاختبار بلا مُحرِّك Flutter.
  ///
  /// يستبعد كلَّ سؤالٍ لم تُعتمد مراجعتُه، حمايةً للمتعلّم من محتوًى غير مُدقَّق.
  static List<Question> parseLevel(String rawJson) {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final items = decoded['questions'] as List<dynamic>;

    final questions = items
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .where((q) => q.reviewStatus == ReviewStatus.approved)
        .toList(growable: false);

    if (questions.isEmpty) {
      throw StateError('لم يُعثر على أيّ سؤالٍ معتمدٍ في هذا المستوى.');
    }

    final ids = <String>{};
    for (final question in questions) {
      if (!ids.add(question.id)) {
        throw StateError('معرّف سؤال مكرّر: ${question.id}');
      }
    }

    return questions;
  }
}
