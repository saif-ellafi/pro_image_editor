// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/shared/widgets/auto_image.dart';

import '../../fake/fake_image.dart';
import 'auto_image_test.mocks.dart';

@GenerateNiceMocks([MockSpec<EditorImage>()])
void main() {
  final mockEditorImage = MockEditorImage();

  group('AutoImage Widget Tests', () {
    testWidgets('displays image from memory', (WidgetTester tester) async {
      when(mockEditorImage.type).thenReturn(EditorImageType.memory);
      when(mockEditorImage.byteArray).thenReturn(fakeMemoryImage);

      await tester.pumpWidget(
        AutoImage(
          mockEditorImage,
          configs: const ProImageEditorConfigs(),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('displays image from network', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        when(mockEditorImage.type).thenReturn(EditorImageType.network);
        when(mockEditorImage.networkUrl).thenReturn(fakeNetworkImage);

        await tester.pumpWidget(
          AutoImage(
            mockEditorImage,
            configs: const ProImageEditorConfigs(),
          ),
        );

        expect(find.byType(Image), findsOneWidget);
      });
    });
  });
}
