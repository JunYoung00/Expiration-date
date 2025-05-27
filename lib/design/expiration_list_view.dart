import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:capstone/widgets/custom_checkbox.dart';


class ExpirationListView extends StatefulWidget {
  final List<Map<String, dynamic>> expirationList;
  final int Function(String) calculateDday;
  final void Function(int index, String newName, DateTime newDate) onEdit;
  final void Function(int index) onDelete;
  final VoidCallback onPickImage;
  final VoidCallback onPickFromGallery;
  final void Function(BuildContext context) onShowAddDialog;
  final void Function(BuildContext context) onSearchPage;


  const ExpirationListView({
    required this.expirationList,
    required this.calculateDday,
    required this.onEdit,
    required this.onDelete,
    required this.onPickImage,
    required this.onPickFromGallery,
    required this.onShowAddDialog,
    required this.onSearchPage,
    Key? key,
  }) : super(key: key);

  @override
  State<ExpirationListView> createState() => _ExpirationListViewState();
}

class _ExpirationListViewState extends State<ExpirationListView> {
  bool isEditing = false;
  Set<int> selectedIndexes = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('유통기한', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
                selectedIndexes.clear();
              });
            },
            child: Text(
              isEditing ? '취소' : '편집',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

      ),
      drawer: _buildDrawer(context),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SlidableAutoCloseBehavior(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(context, "📌 D-DAY", (item) => widget.calculateDday(item['expirationDate']) == 0),
              _buildSection(context, "⏳ 임박", (item) {
                final d = widget.calculateDday(item['expirationDate']);
                return d >= 1 && d <= 7;
              }),
              _buildSection(context, "🍀 여유", (item) => widget.calculateDday(item['expirationDate']) > 7),
              _buildSection(context, "⚠️ 지난 항목", (item) => widget.calculateDday(item['expirationDate']) < 0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isEditing && selectedIndexes.isNotEmpty
          ? Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: () {
            final indexes = selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
            for (final index in indexes) {
              widget.onDelete(index);
            }
            setState(() {
              selectedIndexes.clear();
              isEditing = false;
            });
          },
          icon: Icon(Icons.delete),
          label: Text('선택 삭제 (${selectedIndexes.length})'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(16, 60, 16, 20),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).primaryColor
                  : Colors.white,
              alignment: Alignment.bottomLeft,
              child: Text(
                '기능 메뉴',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            Divider(height: 1),
            _drawerItem(Icons.camera_alt, '카메라 인식', () {
              Navigator.pop(context);
              widget.onPickImage();
            }),
            _drawerItem(Icons.photo, '앨범에서 선택', () {
              Navigator.pop(context);
              widget.onPickFromGallery(); // ✅ 앨범 인식
            }),
            _drawerItem(Icons.search, '음식 검색', () {
              Navigator.pop(context);
              widget.onSearchPage(context);
            }),
            _drawerItem(Icons.add, '직접 추가', () {
              Navigator.pop(context);
              widget.onShowAddDialog(context);
            }),

            // ✅ 아래로 공간을 더 확보
            SizedBox(height: 300),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildSection(BuildContext context, String title, bool Function(Map<String, dynamic>) condition) {
    final filtered = widget.expirationList.where((item) {
      final date = item['expirationDate'];
      return date != null && condition(item);
    }).toList();

// 🔥 여기서 정렬! (가장 빠른 날짜가 위로)
    filtered.sort((a, b) {
      final dateA = a['expirationDate'] != null
          ? DateTime.parse(a['expirationDate'])
          : DateTime(2100); // 없는건 맨 뒤로
      final dateB = b['expirationDate'] != null
          ? DateTime.parse(b['expirationDate'])
          : DateTime(2100);
      return dateA.compareTo(dateB);
    });

    if (filtered.isEmpty) return SizedBox.shrink();

    final sectionColor = Theme.of(context).cardColor;

    return Container(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionColor, // ✅ 공통 배경색
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...filtered.asMap().entries.map((entry) {
            final index = widget.expirationList.indexOf(entry.value);
            return _buildCard(context, index, entry.value, sectionColor); // ✅ 동일 색 전달
          }).toList(),
        ],
      ),
    );
  }




  Widget _buildCard(BuildContext context, int index, Map<String, dynamic> item, Color backgroundColor) {
    final name = item['name'];
    final expirationDateStr = item['expirationDate'];
    final dday = widget.calculateDday(expirationDateStr);
    final ddayLabel = dday < 0 ? '' : (dday == 0 ? 'D-DAY' : 'D-$dday');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedIndexes.contains(index);

    return InkWell(
      onTap: isEditing
          ? () {
        setState(() {
          if (isSelected) {
            selectedIndexes.remove(index);
          } else {
            selectedIndexes.add(index);
          }
        });
      }
          : () {},
      child: Opacity(
        opacity: isEditing && !isSelected ? 0.6 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // ✅ 카드와 동일한 radius
          child: Slidable(
            key: ValueKey(name + expirationDateStr),
            enabled: !isEditing,
            endActionPane: ActionPane(
              motion: DrawerMotion(),
              extentRatio: 0.4,
              children: [
                SlidableAction(
                  onPressed: (_) => _showEditDialog(context, index, item),
                  backgroundColor: Color(0xFFC1BFBF),
                  foregroundColor: Colors.black87,
                  icon: Icons.edit,
                  label: '수정',
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  flex: 1,
                ),
                SlidableAction(
                  onPressed: (_) => _showDeleteConfirm(context, index, item),
                  backgroundColor: Color(0xFFFF5C5C),
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  flex: 1,
                  label: '삭제',
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (isEditing)
                    CustomCheckbox(
                      isChecked: isSelected,
                      onChanged: () {
                        setState(() {
                          if (isSelected) {
                            selectedIndexes.remove(index);
                          } else {
                            selectedIndexes.add(index);
                          }
                        });
                      },
                    ),
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (ddayLabel.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Text(
                        ddayLabel,
                        style: TextStyle(
                          color: isDarkMode ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

  }


  void _showEditDialog(BuildContext context, int index, Map<String, dynamic> item) {
    final nameController = TextEditingController(text: item['name']);
    DateTime? expirationDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: '이름')),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) expirationDate = picked;
              },
              child: Text('유통기한 선택'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
          TextButton(
            onPressed: () {
              if (expirationDate != null) {
                widget.onEdit(index, nameController.text.trim(), expirationDate!);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('날짜를 선택하세요.')));
              }
            },
            child: Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, int index, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('삭제 확인'),
        content: Text('"${item['name']}" 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
          TextButton(
            onPressed: () {
              widget.onDelete(index);
              Navigator.pop(context);
            },
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

Future<void> showRegisterFailDialog(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '일부 품목 등록 실패',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black, // 🔥
                ),
              ),
              SizedBox(height: 22),
              Text(
                '유통기한 리스트/가계부는\n다른 기능을 이용해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black, // 🔥
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('확인', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}