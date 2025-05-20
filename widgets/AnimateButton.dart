import 'package:flutter/material.dart';

class AnimatedBounceButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const AnimatedBounceButton({
    Key? key,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<AnimatedBounceButton> createState() => _AnimatedBounceButtonState();
}

class _AnimatedBounceButtonState extends State<AnimatedBounceButton> {
  double _elevation = 10;
  Offset _offset = Offset.zero;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _offset = Offset(0, 1);
      _elevation = 4;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _offset = Offset.zero;
      _elevation = 10;
    });
  }

  void _onTapCancel() {
    setState(() {
      _offset = Offset.zero;
      _elevation = 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: _elevation,
              offset: Offset(0, _elevation / 2),
            )
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w500,
              textBaseline: TextBaseline.alphabetic,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
