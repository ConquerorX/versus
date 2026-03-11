import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final imagePath = 'assets/icon/app_icon.png';
  final file = File(imagePath);
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes)!;

  final r0 = 0, g0 = 0, b0 = 0; // Black background
  int brightnessThreshold = 50;
  
  int minX = image.width, minY = image.height, maxX = 0, maxY = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      
      var totalDiff = (r - r0).abs() + (g - g0).abs() + (b - b0).abs();
      var brightness = (r + g + b) ~/ 3;
      
      if (totalDiff > 50 && brightness > brightnessThreshold) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  // Crop the true logo region
  final cropped = img.copyCrop(image, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
  
  // Make the background transparent in the cropped region just in case.
  for (var y = 0; y < cropped.height; y++) {
    for (var x = 0; x < cropped.width; x++) {
       final p = cropped.getPixel(x, y);
       if ((p.r.toInt() < brightnessThreshold && p.g.toInt() < brightnessThreshold && p.b.toInt() < brightnessThreshold)) {
          cropped.setPixelRgba(x, y, 0, 0, 0, 0); // Transparent
       }
    }
  }

  // Create a 512x512 canvas. 
  // For flutter_launcher_icons adaptive foreground, the safe zone is typically the inner 66% (which would be ~338x338 in a 512x512 image).
  // We want the logo to be as large as possible within the 338x338 boundary.
  int safeZoneSize = 340; 
  
  double scale = safeZoneSize / (cropped.width > cropped.height ? cropped.width : cropped.height);
  int newWidth = (cropped.width * scale).toInt();
  int newHeight = (cropped.height * scale).toInt();
  final scaled = img.copyResize(cropped, width: newWidth, height: newHeight);

  final canvas = img.Image(width: 512, height: 512);
  final dstX = (512 - newWidth) ~/ 2;
  final dstY = (512 - newHeight) ~/ 2;
  for (int y = 0; y < newHeight; y++) {
    for (int x = 0; x < newWidth; x++) {
      canvas.setPixel(dstX + x, dstY + y, scaled.getPixel(x, y));
    }
  }

  // Save the new foreground
  await File('assets/icon/app_icon_fg.png').writeAsBytes(img.encodePng(canvas));
  print('Successfully created app_icon_fg.png with accurate scaled cropped dimensions!');
}
