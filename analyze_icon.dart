import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final imagePath = 'assets/icon/app_icon.png';
  final file = File(imagePath);
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes)!;
  
  final pixel0 = image.getPixel(0, 0);
  int r0 = pixel0.r.toInt(), g0 = pixel0.g.toInt(), b0 = pixel0.b.toInt();
  print('Top-Left Pixel: $r0, $g0, $b0');

  int minX = image.width, minY = image.height, maxX = 0, maxY = 0;
  
  // Find bounds with a higher tolerance or adaptive threshold
  int brightnessThreshold = 50; // Ignore anything very dark
  
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      
      // Calculate brightness or diff from background
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
  
  print('Image Size: ${image.width}x${image.height}');
  print('Detected Bounds: minX=$minX, minY=$minY, maxX=$maxX, maxY=$maxY');
  print('Content Size: ${maxX - minX}x${maxY - minY}');
}
