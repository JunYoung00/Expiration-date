import 'package:flutter/material.dart';

class CustomThemeToggle extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggle;

  const CustomThemeToggle({
    required this.isDarkMode,
    required this.onToggle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '알림 설정',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => onToggle(!isDarkMode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF222222) : Color(0xFFB0B0B0),
              border: Border.all(
                color: Color(0xFFB0B0B0),
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  left: isDarkMode ? 24 : 0,
                  child: Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: isDarkMode ? Color(0xFF181818) : Color(0xFFB0B0B0)),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: isDarkMode ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
