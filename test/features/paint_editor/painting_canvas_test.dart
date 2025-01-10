// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/features/paint_editor/controllers/paint_controller.dart';
import 'package:pro_image_editor/features/paint_editor/enums/paint_editor_enum.dart';
import 'package:pro_image_editor/features/paint_editor/widgets/paint_canvas.dart';

void main() {
  group('PaintCanvas Tests', () {
    testWidgets(
        'Handles gestures and updates paint-items with start/stop offsets',
        (WidgetTester tester) async {
      final GlobalKey<PaintCanvasState> canvasKey = GlobalKey();
      PaintController ctrl = PaintController(
        color: Colors.red,
        mode: PaintMode.arrow,
        fill: false,
        strokeWidth: 1,
        strokeMultiplier: 1,
        opacity: 1,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaintCanvas(
              key: canvasKey,
              drawAreaSize: const Size(1000, 1000),
              paintCtrl: ctrl,
            ),
          ),
        ),
      );

      Offset center = tester.getCenter(find.byKey(canvasKey));

      // Simulate scale start gesture
      final TestGesture gesture = await tester.startGesture(center);

      /// Assuming the start point is not null
      expect(ctrl.start, isNotNull);

      // Simulate scale update gesture
      Offset updatedPoint = center + const Offset(10, 10);
      await gesture.moveTo(updatedPoint);

      /// Assuming the end point is not null
      expect(ctrl.end, isNotNull);

      // Simulate scale end gesture
      await gesture.up();

      // Assuming the paintMode didn't change
      expect(ctrl.mode, PaintMode.arrow);

      // Assuming the gesture creates an undoable action
      expect(ctrl.canUndo, isTrue);
    });

    testWidgets('Handles gestures and updates paint-items in freestyle-mode',
        (WidgetTester tester) async {
      final GlobalKey<PaintCanvasState> canvasKey = GlobalKey();
      PaintController ctrl = PaintController(
        color: Colors.red,
        mode: PaintMode.freeStyle,
        fill: false,
        strokeWidth: 1,
        strokeMultiplier: 1,
        opacity: 1,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaintCanvas(
              key: canvasKey,
              drawAreaSize: const Size(1000, 1000),
              paintCtrl: ctrl,
            ),
          ),
        ),
      );

      Offset center = tester.getCenter(find.byKey(canvasKey));

      // Simulate scale start gesture
      final TestGesture gesture = await tester.startGesture(center);

      // Simulate scale update gesture
      await gesture.moveTo(center + const Offset(0, 10));
      await gesture.moveTo(center + const Offset(10, 0));
      await gesture.moveTo(center + const Offset(10, 10));

      /// Assuming the offset length is correct
      expect(ctrl.offsets.length, 4);

      // Simulate scale end gesture
      await gesture.up();

      // Assuming the paintMode didn't change
      expect(ctrl.mode, PaintMode.freeStyle);

      // Assuming the gesture creates an undoable action
      expect(ctrl.canUndo, isTrue);
    });

    testWidgets('Performs undo and redo actions', (WidgetTester tester) async {
      PaintController ctrl = PaintController(
        color: Colors.red,
        mode: PaintMode.arrow,
        fill: false,
        strokeWidth: 1,
        strokeMultiplier: 1,
        opacity: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaintCanvas(
              drawAreaSize: const Size(200, 200),
              paintCtrl: ctrl,
            ),
          ),
        ),
      );

      // Simulate scale start gesture
      const Offset startPoint = Offset(50, 50);
      final TestGesture gesture = await tester.startGesture(startPoint);
      await tester.pump();

      // Simulate scale update gesture
      const Offset updatedPoint = Offset(70, 70);
      await gesture.moveTo(updatedPoint);
      await tester.pump();

      // Simulate scale end gesture
      await gesture.up();
      await tester.pump();

      // Perform an undo action
      ctrl.undo();
      await tester.pump();

      // Verify that undo action has an effect
      expect(ctrl.canUndo, isFalse); // Assuming the undo clears the action
      expect(ctrl.canRedo, isTrue); // There should be an action to redo now

      // Perform a redo action
      ctrl.redo();
      await tester.pump();

      // Verify that redo action has an effect
      expect(ctrl.canUndo, isTrue); // The action should be back in the history
      expect(ctrl.canRedo, isFalse); // There should be no actions to redo now
    });
  });
}
