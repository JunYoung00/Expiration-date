import 'package:flutter/material.dart';

class CustomCheckbox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onChanged;

  const CustomCheckbox({
    Key? key,
    required this.isChecked,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isChecked ? (isDarkMode ? Colors.white : Colors.black) : Colors.grey;
    final fillColor = isChecked ? (isDarkMode ? Colors.white : Colors.black) : Colors.transparent;
    final iconColor = isDarkMode ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 24,
        height: 24,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          color: fillColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: isChecked
                ? Icon(Icons.check, key: ValueKey(true), color: iconColor, size: 16)
                : SizedBox(key: ValueKey(false)),
          ),
        ),
      ),
    );
  }
}
