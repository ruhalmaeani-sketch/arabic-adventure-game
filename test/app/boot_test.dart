import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihlat_alarabiyya/app/app.dart';
import 'package:rihlat_alarabiyya/features/home/home_screen.dart';

/// اختبارُ إقلاع: يضمن أنَّ التطبيق يبني أوّلَ إطارٍ له دون استثناء،
/// وأنَّ الواجهةَ عربيّةٌ من اليمين إلى اليسار.
void main() {
  testWidgets('التطبيق يُقلِع ويعرض شاشةَ البداية', (tester) async {
    await tester.pumpWidget(const RihlaApp());
    await tester.pumpAndSettle();

    expect(find.text('رِحْلَةُ العَرَبِيَّة'), findsOneWidget);
    expect(find.text('ابدأ الرحلة'), findsOneWidget);

    final directionality = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.byType(HomeScreen),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });
}
