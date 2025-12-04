import 'package:flutter/material.dart';

/// Custom clipper for Home header with smooth bottom-right curve
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start at top-left
    path.lineTo(0, 0);
    
    // Top edge
    path.lineTo(size.width, 0);
    
    // Right edge down to curve start
    path.lineTo(size.width, size.height - 80);
    
    // Smooth bottom-right curve using quadratic bezier
    path.quadraticBezierTo(
      size.width, // control point x
      size.height, // control point y
      size.width - 80, // end point x
      size.height, // end point y
    );
    
    // Bottom edge to left
    path.lineTo(0, size.height);
    
    // Close path
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
