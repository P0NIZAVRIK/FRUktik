import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../../design_system/colors.dart';

/// Particle class for background animation
class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  Color color;
  double opacity;
  
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    required this.opacity,
  });
}

/// Animated particle background with gyroscope parallax effect
class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final bool enableGyroscope;
  
  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 50,
    this.enableGyroscope = true,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  StreamSubscription? _gyroSubscription;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    _initParticles();
    _initGyroscope();
  }
  
  void _initParticles() {
    final colors = [
      AppColors.proteinNeon,
      AppColors.fatsNeon,
      AppColors.carbsNeon,
      AppColors.caloriesNeon,
      AppColors.primary,
    ];
    
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        vx: (_random.nextDouble() - 0.5) * 0.002,
        vy: (_random.nextDouble() - 0.5) * 0.002,
        radius: _random.nextDouble() * 3 + 1,
        color: colors[_random.nextInt(colors.length)],
        opacity: _random.nextDouble() * 0.5 + 0.2,
      ));
    }
  }
  
  void _initGyroscope() {
    if (!widget.enableGyroscope) return;
    
    // Only enable on mobile platforms
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        _gyroSubscription = gyroscopeEventStream().listen(
          (event) {
            if (mounted) {
              setState(() {
                _gyroX = event.y * 0.02; // Subtle effect
                _gyroY = event.x * 0.02;
              });
            }
          },
          onError: (e) {
            debugPrint('Gyroscope not available: $e');
          },
        );
      } catch (e) {
        debugPrint('Failed to initialize gyroscope: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _gyroSubscription?.cancel();
    super.dispose();
  }
  
  void _updateParticles() {
    for (final particle in _particles) {
      // Update position with velocity
      particle.x += particle.vx + _gyroX;
      particle.y += particle.vy + _gyroY;
      
      // Wrap around screen
      if (particle.x < 0) particle.x = 1;
      if (particle.x > 1) particle.x = 0;
      if (particle.y < 0) particle.y = 1;
      if (particle.y > 1) particle.y = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _updateParticles();
        
        return Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    AppColors.backgroundSecondary,
                    AppColors.backgroundPrimary,
                  ],
                ),
              ),
            ),
            
            // Particles layer
            CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
                gyroX: _gyroX,
                gyroY: _gyroY,
              ),
              size: Size.infinite,
            ),
            
            // Glow overlay
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.3 + _gyroX * 2, -0.3 + _gyroY * 2),
                  radius: 0.8,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Child content
            widget.child,
          ],
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double gyroX;
  final double gyroY;

  ParticlePainter({
    required this.particles,
    required this.gyroX,
    required this.gyroY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.radius);
      
      canvas.drawCircle(
        Offset(
          particle.x * size.width,
          particle.y * size.height,
        ),
        particle.radius,
        paint,
      );
    }
    
    // Draw connection lines between nearby particles
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;
    
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final dx = (particles[i].x - particles[j].x) * size.width;
        final dy = (particles[i].y - particles[j].y) * size.height;
        final distance = math.sqrt(dx * dx + dy * dy);
        
        if (distance < 100) {
          linePaint.color = Colors.white.withOpacity(0.05 * (1 - distance / 100));
          canvas.drawLine(
            Offset(particles[i].x * size.width, particles[i].y * size.height),
            Offset(particles[j].x * size.width, particles[j].y * size.height),
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
