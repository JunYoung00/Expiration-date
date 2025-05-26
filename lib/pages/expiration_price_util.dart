import 'package:capstone/pages/money_page.dart';

// 금액 추출
List<String> extractPrices(String text) {
  final priceRegex = RegExp(r'\b\d{1,3}(?:,\d{3})+\b|\b\d{4,}\b');
  return priceRegex.allMatches(text).map((m) => m.group(0)!).toList();
}

Future<void> processPriceFromText(String text) async {
  List<String> prices = extractPrices(text);

  // 중복 제거 + 숫자로 정리
  Set<int> uniquePrices = prices
      .map((p) => int.parse(p.replaceAll(',', '')))
      .toSet();

  if (uniquePrices.isNotEmpty) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    for (var price in uniquePrices) {
      // await MoneyPage.addExpense(todayStr, price);
      print("💸 ${price}원이 가계부에 저장됨");
    }
  }
}