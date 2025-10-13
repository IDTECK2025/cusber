import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gold_pos/utils/colors.dart';

class DiamondIndicator extends StatefulWidget {
  final double size;
  final Color color;
  final Color accentColor;

  const DiamondIndicator({
    super.key,
    this.size = 9,
    this.color = kPrimaryColor,
    this.accentColor = kBlueColor,
  });

  @override
  State<DiamondIndicator> createState() => _DiamondIndicatorState();
}

class _DiamondIndicatorState extends State<DiamondIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: FourLayerDiamond3DRenderer(
              progress: _animation.value,
              color: widget.color,
              accentColor: widget.accentColor,
            ),
          );
        },
      ),
    );
  }
}

class FourLayerDiamond3DRenderer extends CustomPainter {
  final double progress;
  final Color color;
  final Color accentColor;

  FourLayerDiamond3DRenderer({
    required this.progress,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final diamondSize = size.width * 0.3;

    // Create 4-layer diamond geometry
    FourLayerDiamond3D diamond = FourLayerDiamond3D(diamondSize);

    // Rotation angles
    double rotationX = progress * math.pi * 0.5 + math.pi / 6;
    double rotationY = progress * 2 * math.pi; // Complete 360° flip
    double rotationZ = progress * math.pi * 0.3;

    // Transform and project ALL vertices
    List<Vertex3D> transformedVertices =
        diamond.vertices.map((vertex) {
          return _transform3D(vertex, rotationX, rotationY, rotationZ);
        }).toList();

    List<Offset> projectedVertices =
        transformedVertices.map((vertex) {
          return _projectToScreen(vertex, center, size.width * 0.8);
        }).toList();

    // Process ALL faces
    List<Face3DData> facesWithData = [];
    for (int i = 0; i < diamond.faces.length; i++) {
      Face3D face = diamond.faces[i];

      // Get transformed face vertices
      Vertex3D v1 = transformedVertices[face.v1];
      Vertex3D v2 = transformedVertices[face.v2];
      Vertex3D v3 = transformedVertices[face.v3];

      // Calculate face normal
      Vertex3D normal = _calculateNormal(v1, v2, v3);

      // Calculate lighting
      Vertex3D lightDirection = Vertex3D(0.3, -0.8, 1.0).normalized();
      double lightIntensity = math.max(
        0.15,
        _dotProduct(normal, lightDirection),
      );

      // Calculate depth
      double avgZ = (v1.z + v2.z + v3.z) / 3;

      // Include ALL faces
      facesWithData.add(
        Face3DData(
          face: face,
          normal: normal,
          lightIntensity: lightIntensity,
          avgZ: avgZ,
          projectedVertices: [
            projectedVertices[face.v1],
            projectedVertices[face.v2],
            projectedVertices[face.v3],
          ],
        ),
      );
    }

    // Sort by depth
    facesWithData.sort((a, b) => a.avgZ.compareTo(b.avgZ));

    // Draw all faces
    for (Face3DData faceData in facesWithData) {
      _drawFace(canvas, faceData);
    }

    // Draw sparkles
    _drawSparkles3D(
      canvas,
      center,
      diamondSize,
      transformedVertices,
      projectedVertices,
    );
  }

  Vertex3D _transform3D(
    Vertex3D vertex,
    double rotX,
    double rotY,
    double rotZ,
  ) {
    double x = vertex.x;
    double y = vertex.y;
    double z = vertex.z;

    // Y-axis rotation (main flip)
    double newX = x * math.cos(rotY) + z * math.sin(rotY);
    double newZ = -x * math.sin(rotY) + z * math.cos(rotY);
    x = newX;
    z = newZ;

    return Vertex3D(x, y, z);
  }

  Offset _projectToScreen(Vertex3D vertex, Offset center, double scale) {
    double perspective = 300.0;
    double projectedX = (vertex.x * perspective) / (perspective + vertex.z);
    double projectedY = (vertex.y * perspective) / (perspective + vertex.z);

    return Offset(
      center.dx + projectedX * scale,
      center.dy + projectedY * scale,
    );
  }

  Vertex3D _calculateNormal(Vertex3D v1, Vertex3D v2, Vertex3D v3) {
    Vertex3D edge1 = Vertex3D(v2.x - v1.x, v2.y - v1.y, v2.z - v1.z);
    Vertex3D edge2 = Vertex3D(v3.x - v1.x, v3.y - v1.y, v3.z - v1.z);

    return Vertex3D(
      edge1.y * edge2.z - edge1.z * edge2.y,
      edge1.z * edge2.x - edge1.x * edge2.z,
      edge1.x * edge2.y - edge1.y * edge2.x,
    ).normalized();
  }

  double _dotProduct(Vertex3D a, Vertex3D b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
  }

  void _drawFace(Canvas canvas, Face3DData faceData) {
    Path path = Path();
    path.moveTo(
      faceData.projectedVertices[0].dx,
      faceData.projectedVertices[0].dy,
    );
    path.lineTo(
      faceData.projectedVertices[1].dx,
      faceData.projectedVertices[1].dy,
    );
    path.lineTo(
      faceData.projectedVertices[2].dx,
      faceData.projectedVertices[2].dy,
    );
    path.close();

    // Face color
    Color baseColor = faceData.face.isMainFacet ? color : accentColor;
    double intensity = faceData.lightIntensity;

    Color lightColor =
        Color.lerp(Colors.black, baseColor, 0.4 + intensity * 0.6)!;
    Color highlightColor =
        Color.lerp(baseColor, Colors.white, intensity * 0.5)!;

    Paint paint =
        Paint()
          ..shader = LinearGradient(
            colors: [highlightColor, lightColor, baseColor.withOpacity(0.9)],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(path.getBounds())
          ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Face edges
    Paint edgePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.3 + intensity * 0.2)
          ..strokeWidth = 0.2
          ..style = PaintingStyle.stroke;

    canvas.drawPath(path, edgePaint);
  }

  void _drawSparkles3D(
    Canvas canvas,
    Offset center,
    double size,
    List<Vertex3D> vertices3D,
    List<Offset> vertices2D,
  ) {
    // Sparkles on key vertices
    List<int> sparkleVertices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 25];

    for (int i in sparkleVertices) {
      if (i >= vertices3D.length) continue;

      Vertex3D vertex3D = vertices3D[i];
      Offset vertex2D = vertices2D[i];

      if (vertex3D.z > -0.4) {
        double sparkleIntensity =
            (math.sin(progress * 10 + i * 0.8) * 0.5 + 0.5);

        if (sparkleIntensity > 0.7) {
          Paint sparklePaint =
              Paint()
                ..color = Colors.white.withOpacity(sparkleIntensity * 0.8)
                ..style = PaintingStyle.fill;

          double sparkleSize = 1 + sparkleIntensity * 1.2;
          _drawStar(canvas, vertex2D, sparkleSize, sparklePaint);
        }
      }
    }

    // Central sparkle
    double centralSparkle = (math.sin(progress * 7) * 0.5 + 0.5);
    if (centralSparkle > 0.75) {
      Paint centralPaint =
          Paint()
            ..color = accentColor.withOpacity(centralSparkle * 0.7)
            ..style = PaintingStyle.fill;

      _drawStar(canvas, center, 2.5, centralPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    Path starPath = Path();
    starPath.moveTo(center.dx, center.dy - size);
    starPath.lineTo(center.dx + size * 0.3, center.dy - size * 0.3);
    starPath.lineTo(center.dx + size, center.dy);
    starPath.lineTo(center.dx + size * 0.3, center.dy + size * 0.3);
    starPath.lineTo(center.dx, center.dy + size);
    starPath.lineTo(center.dx - size * 0.3, center.dy + size * 0.3);
    starPath.lineTo(center.dx - size, center.dy);
    starPath.lineTo(center.dx - size * 0.3, center.dy - size * 0.3);
    starPath.close();

    canvas.drawPath(starPath, paint);
  }

  @override
  bool shouldRepaint(FourLayerDiamond3DRenderer oldDelegate) =>
      oldDelegate.progress != progress;
}

// Data structures
class Vertex3D {
  final double x, y, z;
  Vertex3D(this.x, this.y, this.z);

  Vertex3D normalized() {
    double length = math.sqrt(x * x + y * y + z * z);
    if (length == 0) return Vertex3D(0, 0, 0);
    return Vertex3D(x / length, y / length, z / length);
  }
}

class Face3D {
  final int v1, v2, v3;
  final bool isMainFacet;

  Face3D(this.v1, this.v2, this.v3, {this.isMainFacet = false});
}

class Face3DData {
  final Face3D face;
  final Vertex3D normal;
  final double lightIntensity;
  final double avgZ;
  final List<Offset> projectedVertices;

  Face3DData({
    required this.face,
    required this.normal,
    required this.lightIntensity,
    required this.avgZ,
    required this.projectedVertices,
  });
}

class FourLayerDiamond3D {
  late List<Vertex3D> vertices;
  late List<Face3D> faces;

  FourLayerDiamond3D(double size) {
    _createFourLayerGeometry(size);
  }

  void _createFourLayerGeometry(double size) {
    vertices = [
      // Layer 1: Top vertex (Crown apex)
      Vertex3D(0, -size * 0.9, 0), // 0
      // Layer 2: Crown ring (8 vertices)
      Vertex3D(-size * 0.4, -size * 0.6, -size * 0.4), // 1
      Vertex3D(0, -size * 0.6, -size * 0.6), // 2
      Vertex3D(size * 0.4, -size * 0.6, -size * 0.4), // 3
      Vertex3D(size * 0.6, -size * 0.6, 0), // 4
      Vertex3D(size * 0.4, -size * 0.6, size * 0.4), // 5
      Vertex3D(0, -size * 0.6, size * 0.6), // 6
      Vertex3D(-size * 0.4, -size * 0.6, size * 0.4), // 7
      Vertex3D(-size * 0.6, -size * 0.6, 0), // 8
      // Layer 3: Girdle ring (8 vertices) - widest part
      Vertex3D(-size * 0.7, 0, -size * 0.7), // 9
      Vertex3D(0, 0, -size), // 10
      Vertex3D(size * 0.7, 0, -size * 0.7), // 11
      Vertex3D(size, 0, 0), // 12
      Vertex3D(size * 0.7, 0, size * 0.7), // 13
      Vertex3D(0, 0, size), // 14
      Vertex3D(-size * 0.7, 0, size * 0.7), // 15
      Vertex3D(-size, 0, 0), // 16
      // Layer 4: Pavilion ring (8 vertices)
      Vertex3D(-size * 0.3, size * 0.6, -size * 0.3), // 17
      Vertex3D(0, size * 0.6, -size * 0.4), // 18
      Vertex3D(size * 0.3, size * 0.6, -size * 0.3), // 19
      Vertex3D(size * 0.4, size * 0.6, 0), // 20
      Vertex3D(size * 0.3, size * 0.6, size * 0.3), // 21
      Vertex3D(0, size * 0.6, size * 0.4), // 22
      Vertex3D(-size * 0.3, size * 0.6, size * 0.3), // 23
      Vertex3D(-size * 0.4, size * 0.6, 0), // 24
      // Bottom vertex (Culet)
      Vertex3D(0, size * 1.0, 0), // 25
    ];

    faces = [];

    // Layer 1 to Layer 2: Crown faces (8 triangles)
    for (int i = 0; i < 8; i++) {
      int next = (i + 1) % 8;
      faces.add(Face3D(0, i + 1, next + 1, isMainFacet: true));
    }

    // Layer 2 to Layer 3: Crown to girdle (16 triangles)
    for (int i = 0; i < 8; i++) {
      int next = (i + 1) % 8;
      faces.add(Face3D(i + 1, i + 9, next + 1));
      faces.add(Face3D(next + 1, i + 9, next + 9));
    }

    // Layer 3 to Layer 4: Girdle to pavilion (16 triangles)
    for (int i = 0; i < 8; i++) {
      int next = (i + 1) % 8;
      faces.add(Face3D(i + 9, i + 17, next + 9));
      faces.add(Face3D(next + 9, i + 17, next + 17));
    }

    // Layer 4 to bottom: Pavilion to culet (8 triangles)
    for (int i = 0; i < 8; i++) {
      int next = (i + 1) % 8;
      faces.add(Face3D(i + 17, 25, next + 17, isMainFacet: true));
    }

    // Additional connecting faces to ensure no gaps
    for (int i = 0; i < 8; i++) {
      int next = (i + 1) % 8;

      // Extra connections between layers
      faces.add(Face3D(i + 1, next + 9, i + 9));
      faces.add(Face3D(i + 9, next + 17, i + 17));
    }
  }
}
