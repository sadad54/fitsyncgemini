// lib/utils/map_utils.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class MapUtils {
  /// Create custom markers with icons and background colors
  static Future<BitmapDescriptor> createCustomMarker({
    required String iconPath,
    required int size,
    ui.Color? backgroundColor,
  }) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      // Draw background circle
      if (backgroundColor != null) {
        final Paint backgroundPaint = Paint()..color = backgroundColor;
        canvas.drawCircle(
          Offset(size / 2, size / 2),
          size / 2,
          backgroundPaint,
        );
      }

      // Load and draw icon
      final ByteData data = await rootBundle.load(iconPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: (size * 0.6).round(),
        targetHeight: (size * 0.6).round(),
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      canvas.drawImage(
        frameInfo.image,
        Offset(size * 0.2, size * 0.2),
        Paint(),
      );

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image image = await picture.toImage(size, size);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    } catch (e) {
      // Fallback to default marker
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Get marker for different types with predefined colors
  static BitmapDescriptor getMarkerForType(String type) {
    switch (type) {
      case 'person':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'event':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'hotspot':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'user':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  /// Build a circular marker with a Material icon centered inside
  static Future<BitmapDescriptor> createIconMarker({
    required IconData icon,
    required ui.Color backgroundColor,
    ui.Color iconColor = const ui.Color(0xFFFFFFFF),
    int size = 120,
  }) async {
    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final Paint backgroundPaint = Paint()..color = backgroundColor;
      final double radius = size / 2.0;
      canvas.drawCircle(Offset(radius, radius), radius, backgroundPaint);

      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: size * 0.56,
            color: iconColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      final double dx = (size - painter.width) / 2.0;
      final double dy = (size - painter.height) / 2.0;
      painter.paint(canvas, Offset(dx, dy));

      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(size, size);
      final ByteData? bytes = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    } catch (_) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Create a marker from text (useful for count badges)
  static Future<BitmapDescriptor> createTextMarker({
    required String text,
    int size = 100,
    ui.Color backgroundColor = const ui.Color(0xFFFF6B9D),
    ui.Color textColor = const ui.Color(0xFFFFFFFF),
  }) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      // Draw background circle
      final Paint backgroundPaint = Paint()..color = backgroundColor;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2, backgroundPaint);

      // Draw text
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
      );

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image image = await picture.toImage(size, size);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    } catch (e) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Get camera position bounds for multiple markers
  static LatLngBounds getBounds(List<LatLng> positions) {
    if (positions.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(37.7749, -122.4194), // San Francisco
        northeast: const LatLng(37.7849, -122.4094),
      );
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (LatLng position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Convert distance in meters to human readable string
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Check if coordinates are valid
  static bool isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  /// Get optimal zoom level for a given radius
  static double getOptimalZoom(double radiusKm) {
    if (radiusKm <= 1) return 15.0;
    if (radiusKm <= 5) return 13.0;
    if (radiusKm <= 10) return 12.0;
    if (radiusKm <= 25) return 11.0;
    return 10.0;
  }
}
