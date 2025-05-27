// 📁 lib/widgets/glass_plus_button.dart
import 'package:flutter/material.dart';

class GlassPlusButton extends StatefulWidget {
  final VoidCallback onPressed;

  const GlassPlusButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  _GlassPlusButtonState createState() => _GlassPlusButtonState();
}

class _GlassPlusButtonState extends State<GlassPlusButton>
    with SingleTickerProviderStateMixin {
  double _yOffset = -4;
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _yOffset = -2;
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _yOffset = -4;
      _isPressed = false;
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() {
        _yOffset = -4;
        _isPressed = false;
      }),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow
          Transform.translate(
            offset: Offset(0, _isPressed ? 1 : 4),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blueGrey[300],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
            ),
          ),

          // Edge
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6A5ACD),
                    Color(0xFF836FFF),
                    Color(0xFF6A5ACD),
                    Color(0xFF483D8B),
                  ],
                  stops: [0.0, 0.08, 0.92, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Front
          Transform.translate(
            offset: Offset(0, _yOffset),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Color(0xFF7B68EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          )
        ],
      ),
    );
  }
}
