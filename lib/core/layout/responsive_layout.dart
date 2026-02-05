import 'package:flutter/material.dart';

/// Responsive layout builder
/// Breaks at 600px for mobile/tablet, 900px for tablet/desktop
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });
  
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= 900) {
      return desktop;
    } else if (width >= 600) {
      return tablet ?? desktop;
    } else {
      return mobile;
    }
  }
}

/// Responsive value helper
class ResponsiveValue {
  static T get<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= 900) {
      return desktop;
    } else if (width >= 600) {
      return tablet ?? desktop;
    } else {
      return mobile;
    }
  }
}
