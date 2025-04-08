import 'package:flutter/material.dart';
import 'expiration_date_page.dart';
import 'camera_page.dart';
import '../widgets/rounded_button.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('유통기한 알림 앱', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoundedButton(
              text: '유통기한',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExpirationDatePage()),
              ),
            ),
            SizedBox(height: 20),
            RoundedButton(
              text: '사진',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}