import 'package:flutter/material.dart';

class NotificationToggle extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onToggle;

  const NotificationToggle({
    Key? key,
    required this.isEnabled,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: isEnabled ? 0.0 : 1.0,
              duration: Duration(milliseconds: 300),
              child: Icon(Icons.notifications_none, size: 30, color: Colors.grey),
            ),
            AnimatedOpacity(
              opacity: isEnabled ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Icon(Icons.notifications, size: 30, color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}
