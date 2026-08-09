import 'package:flutter_test/flutter_test.dart';
import 'package:rihlat_alarabiyya/domain/models/outfit.dart';
import 'package:rihlat_alarabiyya/game/world/realm.dart';

void main() {
  group('Outfit', () {
    test('يبدأ اللاعبُ طالبَ علمٍ بلا كتاب', () {
      expect(Outfit.forBooks(0).id, Outfit.student.id);
    });

    test('الهيئةُ ترتقي كلّما بلَغ نصابَ كتبٍ جديد', () {
      expect(Outfit.forBooks(2).id, Outfit.student.id);
      expect(Outfit.forBooks(3).id, Outfit.grammarian.id);
      expect(Outfit.forBooks(6).id, Outfit.grammarian.id);
      expect(Outfit.forBooks(7).id, Outfit.litterateur.id);
      expect(Outfit.forBooks(100).id, Outfit.sheikh.id);
    });

    test('الهيئةُ لا تتراجع أبدًا مع زيادة الكتب', () {
      var previous = -1;
      for (var books = 0; books < 40; books++) {
        final index = Outfit.all.indexOf(Outfit.forBooks(books));
        expect(index, greaterThanOrEqualTo(previous));
        previous = index;
      }
    });

    test('يُعلَم اللاعبُ كم بقي له حتى الزيّ التالي', () {
      expect(Outfit.booksToNext(0), 3);
      expect(Outfit.booksToNext(2), 1);
      expect(Outfit.booksToNext(3), 4);
      expect(Outfit.booksToNext(18), 0, reason: 'بلغ آخرَ الأزياء');
    });

    test('لكلّ زيٍّ هيئةٌ مميّزةٌ لا تلتبس بغيرها', () {
      final ids = Outfit.all.map((o) => o.id).toSet();
      expect(ids.length, Outfit.all.length);

      final looks = Outfit.all
          .map((o) => '${o.robe}-${o.turban}-${o.hasCloak}-${o.carriesBook}')
          .toSet();
      expect(looks.length, Outfit.all.length);
    });
  });

  group('Realm', () {
    test('الأقاليمُ تدور فلا تقف عند آخرها', () {
      var realm = Realm.all.first;
      for (var i = 0; i < Realm.all.length; i++) {
        realm = realm.next;
      }
      expect(realm.id, Realm.all.first.id);
    });

    test('كلّ إقليمٍ يختلف عن غيره في الهيئة لا في اللون فحسب', () {
      // هذا هو جوهرُ الإصلاح: تبديلُ الألوان وحدَه لا يكسر الرتابة.
      final signatures = Realm.all
          .map((r) => '${r.roadside}-${r.skyline}-${r.surface}')
          .toSet();
      expect(
        signatures.length,
        Realm.all.length,
        reason: 'إقليمان يتشابهان في هيئتهما، فسيبدوان مكرّرَين للاعب',
      );
    });

    test('لكلّ إقليمٍ اسمٌ عربيٌّ يُعرض للاعب', () {
      for (final realm in Realm.all) {
        expect(realm.name.trim(), isNotEmpty);
      }
    });
  });
}
