import 'package:flutter/material.dart';

class RecipePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('가계부', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // // body: Center(
      // //   child: Text(
      // //     '레시피 추천 페이지',
      // //     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      // //   ),
      // ),
    );
  }
}
