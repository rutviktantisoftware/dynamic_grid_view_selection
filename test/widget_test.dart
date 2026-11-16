import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_grid_view_selection/main.dart';

void main() {
  testWidgets('Gallery smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DynamicGridDemoApp());
    expect(find.text('Photos & Gallery'), findsOneWidget);
  });
}
