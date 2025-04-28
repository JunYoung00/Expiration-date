import 'package:flutter/material.dart';

class ExpirationDatePage extends StatefulWidget {
  @override
  _ExpirationDatePageState createState() => _ExpirationDatePageState();
}

class _ExpirationDatePageState extends State<ExpirationDatePage> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _cameraController;
  late AnimationController _searchController;
  late Animation<Offset> _cameraOffsetAnimation;
  late Animation<Offset> _searchOffsetAnimation;
  late Animation<double> _cameraOpacity;
  late Animation<double> _searchOpacity;

  @override
  void initState() {
    super.initState();

    _cameraController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _searchController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _cameraOffsetAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -1.2),
    ).animate(CurvedAnimation(parent: _cameraController, curve: Curves.easeOut));

    _searchOffsetAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -2.4),
    ).animate(CurvedAnimation(parent: _searchController, curve: Curves.easeOut));

    _cameraOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_cameraController);
    _searchOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_searchController);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpand() async {
    if (_isExpanded) {
      _searchController.reverse();
      _cameraController.reverse();
    } else {
      _cameraController.forward();
      _searchController.forward();
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }


  void _collapseIfExpanded() async {
    if (_isExpanded) {
      await _searchController.reverse();
      await _cameraController.reverse();
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _collapseIfExpanded,
      child: Scaffold(
        body: Center(
          child: Text(
            '유통기한 확인 페이지',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButton: Stack(
          alignment: Alignment.bottomRight,
          children: [
            FadeTransition(
              opacity: _searchOpacity,
              child: SlideTransition(
                position: _searchOffsetAnimation,
                child: FloatingActionButton(
                  heroTag: "searchButton",
                  onPressed: () {
                    print('검색 버튼 클릭');
                  },
                  backgroundColor: Colors.grey[700],
                  child: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _cameraOpacity,
              child: SlideTransition(
                position: _cameraOffsetAnimation,
                child: FloatingActionButton(
                  heroTag: "cameraButton",
                  onPressed: () {
                    print('카메라 버튼 클릭');
                  },
                  backgroundColor: Colors.grey[700],
                  child: Icon(Icons.camera_alt),
                ),
              ),
            ),
            SizedBox(height: 20),
            FloatingActionButton(
              heroTag: "mainButton",
              onPressed: _toggleExpand,
              backgroundColor: Colors.grey[800],
              child: Icon(_isExpanded ? Icons.close : Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
