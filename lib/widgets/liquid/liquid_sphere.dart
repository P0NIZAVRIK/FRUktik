import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../design_system/colors.dart';

/// Liquid sphere widget with wave physics and tilt effect
class LiquidSphere extends StatefulWidget {
  final double currentValue;
  final double targetValue;
  final double size;
  
  const LiquidSphere({
    super.key,
    required this.currentValue,
    required this.targetValue,
    this.size = 200,
  });

  @override
  State<LiquidSphere> createState() => _LiquidSphereState();
}

class _LiquidSphereState extends State<LiquidSphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  double _tilt = 0.0;
  bool _sensorAvailable = false;

  @override
  void initState() {
    super.initState();
    
    // Wave animation (continuous 2 second loop)
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Listen to accelerometer for tilt effect (mobile only)
    _initAccelerometer();
  }
  
  void _initAccelerometer() {
    // Only try accelerometer on mobile platforms
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        _accelerometerSubscription = accelerometerEventStream().listen(
          (event) {
            if (mounted) {
              setState(() {
                _tilt = event.x * 0.1; // Subtle tilt effect
                _sensorAvailable = true;
              });
            }
          },
          onError: (e) {
            // Sensor not available, continue without tilt
            debugPrint('Accelerometer not available: $e');
          },
        );
      } catch (e) {
        // Platform doesn't support sensors
        debugPrint('Failed to initialize accelerometer: $e');
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Color _getLiquidColor() {
    final percentage = widget.currentValue / widget.targetValue;
    
    if (percentage > 1.1) {
      return AppColors.error;      // Over limit - RED
    } else if (percentage >= 0.8) {
      return AppColors.success;    // Perfect - GREEN
    } else {
      return AppColors.info;       // On track - BLUE
    }
  }

  @override
  Widget build(BuildContext context) {
    final fillPercentage = (widget.currentValue / widget.targetValue).clamp(0.0, 1.0);
    final liquidColor = _getLiquidColor();
    
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: LiquidSpherePainter(
            fillPercentage: fillPercentage,
            wavePhase: _waveController.value,
            tilt: _tilt,
            liquidColor: liquidColor,
          ),
        );
      },
    );
  }
}

/// Custom painter for liquid sphere with wave physics
class LiquidSpherePainter extends CustomPainter {
  final double fillPercentage;
  final double wavePhase;
  final double tilt;
  final Color liquidColor;

  LiquidSpherePainter({
    required this.fillPercentage,
    required this.wavePhase,
    required this.tilt,
    required this.liquidColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 1. Draw sphere outline
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outlinePaint);
    
    // 2. Calculate liquid level
    final liquidHeight = size.height * (1 - fillPercentage);
    
    // 3. Draw wave path
    final wavePath = Path();
    wavePath.moveTo(0, liquidHeight);
    
    for (double x = 0; x <= size.width; x += 1) {
      // Sine wave with tilt
      final y = liquidHeight + 
          10 * math.sin((x / 30 + wavePhase * 2 * math.pi)) +
          tilt * x / size.width * 20;
      wavePath.lineTo(x, y);
    }
    
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    
    // 4. Clip to sphere
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    
    // 5. Draw gradient liquid
    final liquidPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          liquidColor,
          liquidColor.withOpacity(0.6),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(wavePath, liquidPaint);
    canvas.restore();
    
    // 6. Add shimmer/reflection
    final shimmerPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.4,
      shimmerPaint,
    );
    
    // 7. Add percentage text in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(fillPercentage * 100).toInt()}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.15,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(LiquidSpherePainter oldDelegate) =>
      fillPercentage != oldDelegate.fillPercentage ||
      wavePhase != oldDelegate.wavePhase ||
      tilt != oldDelegate.tilt ||
      liquidColor != oldDelegate.liquidColor;
}
