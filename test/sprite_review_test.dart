import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:snake/image_store.dart';
import 'package:snake/ui_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shifted poses remain whole without sampling their neighbours', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(10, 10, 98, 70), ui.Paint()..color = const ui.Color(0xffff0000));
    canvas.drawRect(const ui.Rect.fromLTWH(120, 20, 70, 60), ui.Paint()..color = const ui.Color(0xff00ff00));
    final picture = recorder.endRecording();
    final image = await picture.toImage(200, 100);
    final sheet = SheetInfo(image, 2, 1);
    await sheet.prepareCharacterFrames();
    // Each pose is repacked whole (plus a 1px clear border) into its own slot.
    expect(sheet.content(0, 0).size, const ui.Size(100, 72));
    expect(sheet.content(1, 0).size, const ui.Size(72, 62));
    expect(sheet.content(0, 0).overlaps(sheet.content(1, 0)), isFalse);
    expect(sheet.cellWidth, 100);
    // The sheet replaced (and disposed) the original with its packed atlas.
    sheet.image.dispose();
    picture.dispose();
  });

  test('all ten snake skins render complete isolated poses', () async {
    final output = Directory('build/review')..createSync(recursive: true);
    for (var skin = 1; skin <= 10; skin++) {
      final name = skin.toString().padLeft(2, '0');
      final sheet = (await ImageStore.instance.loadSheet(
        'skin_${name}_motion_a-transparent.webp', cols: 5, rows: 4,
      ))!;
      final rgba = (await sheet.image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
      int alpha(int x, int y) => rgba[(y * sheet.image.width + x) * 4 + 3];
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xff273b4a), ui.BlendMode.src);
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 5; col++) {
          final src = sheet.content(col, row);
          expect(src.width, greaterThan(60), reason: '$name $row $col');
          expect(src.height, greaterThan(30), reason: '$name $row $col');
          var clipped = 0;
          for (var y = src.top.toInt(); y < src.bottom.toInt(); y++) {
            if (src.left > 0 && alpha(src.left.toInt(), y) >= 32) clipped++;
            if (src.right < sheet.image.width && alpha(src.right.toInt() - 1, y) >= 32) clipped++;
          }
          for (var x = src.left.toInt(); x < src.right.toInt(); x++) {
            if (src.top > 0 && alpha(x, src.top.toInt()) >= 32) clipped++;
            if (src.bottom < sheet.image.height && alpha(x, src.bottom.toInt() - 1) >= 32) clipped++;
          }
          expect(clipped, 0, reason: 'skin $name frame ($col, $row) cuts visible artwork');
          canvas.save();
          canvas.translate(col * 230.0 + 10, row * 230.0);
          canvas.drawLine(const ui.Offset(0, 210), const ui.Offset(210, 210), ui.Paint()..color = const ui.Color(0xff7f9f98));
          SpriteFrame(sheet, col, row).paint(canvas, const ui.Size(210, 210));
          canvas.restore();
        }
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(1150, 920);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      File('${output.path}/skin_${name}_frames.png').writeAsBytesSync(bytes.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
  });
}
