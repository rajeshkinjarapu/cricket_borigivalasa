import 'package:flutter/material.dart';

class AnimatedCricketLogo extends StatefulWidget {
  final double size;
  const AnimatedCricketLogo({super.key, this.size = 110});

  @override
  State<AnimatedCricketLogo> createState() => _AnimatedCricketLogoState();
}

class _AnimatedCricketLogoState extends State<AnimatedCricketLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
    _floatAnim = Tween<double>(begin: 3.0, end: -3.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
    _glowAnim = Tween<double>(begin: 12.0, end: 30.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentGold = Color(0xFFFFB300);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentGold, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: accentGold.withOpacity(0.6),
                    blurRadius: _glowAnim.value,
                    spreadRadius: _glowAnim.value / 6,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.35),
                    blurRadius: _glowAnim.value * 1.1,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
