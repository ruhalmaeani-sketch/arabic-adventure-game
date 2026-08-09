import '../models/question.dart';

/// مصدر الأسئلة. الواجهة مجرَّدة عن مكان التخزين،
/// فيمكن أن يكون ملفَّ JSON محليًّا اليوم وخادمًا بعيدًا غدًا
/// دون تغيير سطرٍ واحد في محرّكات اللعبة.
abstract class QuestionRepository {
  /// يحمّل أسئلة مستوًى معيّن. المطلوب أن يُرجع الأسئلةَ المعتمدةَ فقط.
  Future<List<Question>> loadLevel(int level);
}
