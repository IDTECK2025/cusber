import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gold_pos/utils/colors.dart';

class EmpIndicator extends StatefulWidget {
  final String imagePath;
  final double size;
  final Duration rotationDuration;
  final Color color;
  final Color? backgroundColor;

  const EmpIndicator({
    super.key,
    this.imagePath = 'assets/images/emp_bg.png',
    this.size = 30.0,
    this.rotationDuration = const Duration(seconds: 4),
    this.color = kPrimaryColor,
    this.backgroundColor,
  });

  @override
  _EmpIndicatorState createState() => _EmpIndicatorState();
}

class _EmpIndicatorState extends State<EmpIndicator>
    with TickerProviderStateMixin {
  // Changed back to TickerProviderStateMixin
  late AnimationController _rotationController;
  late AnimationController
  _progressController; // Added back for custom progress speed
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation controller (slower speed)
    _rotationController = AnimationController(
      duration: widget.rotationDuration,
      vsync: this,
    );

    // Custom progress controller for slower circular progress indicator
    _progressController = AnimationController(
      duration: Duration(
        seconds: 2,
      ), // Adjust this for slower/faster progress indicator
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Start animations
    _rotationController.repeat();
    _progressController
        .repeat(); // This will control the progress indicator speed
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _progressController.dispose(); // Don't forget to dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size + 5,
      height: widget.size + 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Custom slower circular progress indicator
          SizedBox(
            width: widget.size + 5,
            height: widget.size + 5,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _progressController.value * 2 * math.pi,
                  child: CircularProgressIndicator(
                    value: 0.25, // Fixed value to show only a quarter arc
                    strokeWidth: 2.0,
                    backgroundColor:
                        widget.backgroundColor ?? Colors.grey.withOpacity(.3),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  ),
                );
              },
            ),
          ),

          // Rotating logo (your existing code)
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: widget.progressColor.withOpacity(0.3),
                    //     blurRadius: 8,
                    //     spreadRadius: 2,
                    //   ),
                    // ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    child: Image.asset(
                      widget.imagePath,
                      fit: BoxFit.contain,
                      color: widget.color,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
