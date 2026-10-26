import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_marketplace/app.dart';

void main() {
  testWidgets('un vendedor puede abrir tienda y publicar un producto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: MercadoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vender'));
    await tester.pumpAndSettle();
    expect(find.text('Vende en Mercado'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar').last);
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido de vuelta'), findsOneWidget);

    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'vendedor@demo.com');
    await tester.enterText(loginFields.at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar').last);
    await tester.pumpAndSettle();
    expect(find.text('Abre tu tienda'), findsNothing);
    expect(find.textContaining('Hola, Vendedor Demo'), findsOneWidget);

    await tester.ensureVisible(find.text('Abrir mi tienda'));
    await tester.tap(find.text('Abrir mi tienda'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir mi tienda'), findsOneWidget);

    final storeFields = find.byType(TextFormField);
    await tester.enterText(storeFields.at(0), 'Tienda de Prueba');
    await tester.enterText(storeFields.at(2), 'Productos hechos a mano.');
    await tester.enterText(storeFields.at(3), '+52 555 123 4567');
    await tester.pumpAndSettle();

    final createButton = find.widgetWithText(FilledButton, 'Crear tienda');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(find.text('Mis productos'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Nuevo producto'));
    await tester.pumpAndSettle();

    final productFields = find.byType(TextFormField);
    await tester.enterText(productFields.at(0), 'Producto de prueba');
    await tester.enterText(productFields.at(2), '25.50');
    await tester.enterText(productFields.at(3), '3');

    final publishButton = find.widgetWithText(
      FilledButton,
      'Publicar producto',
    );
    await tester.ensureVisible(publishButton);
    await tester.tap(publishButton);
    await tester.pumpAndSettle();

    expect(find.text('Mis productos'), findsOneWidget);
    expect(find.text('Producto de prueba'), findsOneWidget);
  });
}
