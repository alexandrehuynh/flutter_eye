import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;

  PosePainter(this.poses, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
          Offset(
            landmark.x * size.width / imageSize.width,
            landmark.y * size.height / imageSize.height,
          ),
          2,
          paint,
        );
      });

      // Draw connections between landmarks
      void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
        final PoseLandmark? start = pose.landmarks[type1];
        final PoseLandmark? end = pose.landmarks[type2];
        if (start == null || end == null) return;

        canvas.drawLine(
          Offset(start.x * size.width / imageSize.width, start.y * size.height / imageSize.height),
          Offset(end.x * size.width / imageSize.width, end.y * size.height / imageSize.height),
          paint,
        );
      }

      // Draw body connections
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
      // Add more connections as needed
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}