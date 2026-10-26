import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_marketplace/app.dart';

void main() {
  testWidgets('la portada muestra el catálogo', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MercadoApp()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Mercado'), findsWidgets);
    expect(find.textContaining('Compra a personas'), findsOneWidget);
  });
}
