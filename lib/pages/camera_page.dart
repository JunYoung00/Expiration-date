import 'package:flutter/material.dart';

class CameraPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('사진 촬영'),
      ),
      body: Center(
        child: Text('카메라 페이지'),
      ),
    );
  }
}