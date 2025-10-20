import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final user = FirebaseAuth.instance.currentUser!;
  late DatabaseReference _userRef;
  late DatabaseReference _purchasesRef;

  int pocket = 0;
  bool loading = true;

  final List<Map<String, dynamic>> _items = [
    {
      'name': 'Футболка 👕',
      'price': 120,
      'image': 'https://cdn-icons-png.flaticon.com/512/2331/2331716.png',
    },
    {
      'name': 'Кружка Katy Bank ☕',
      'price': 80,
      'image': 'https://cdn-icons-png.flaticon.com/512/2738/2738742.png',
    },
    {
      'name': 'Стикеры 💸',
      'price': 40,
      'image': 'https://cdn-icons-png.flaticon.com/512/3585/3585892.png',
    },
    {
      'name': 'Эко-сумка 🛍️',
      'price': 100,
      'image': 'https://cdn-icons-png.flaticon.com/512/679/679922.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    _purchasesRef = FirebaseDatabase.instance.ref('purchases/${user.uid}');
    _loadPocket();
  }

  void _loadPocket() {
    _userRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          pocket = (data['pocket'] ?? 0) as int;
          loading = false;
        });
      }
    });
  }

  Future<void> _buyItem(Map<String, dynamic> item) async {
    final price = item['price'] as int;
    if (pocket < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Недостаточно средств 💸'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _userRef.update({'pocket': pocket - price});
    await _purchasesRef.push().set({
      'item': item['name'],
      'price': price,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Покупка "${item['name']}" успешна! 🎉'),
        backgroundColor: const Color(0xFFB6FF3B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF4F8FB),
        centerTitle: true,
        title: const Text(
          'Магазин мерча',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ваш баланс: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$pocket ₽',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFFB6FF3B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),


            Expanded(
              child: GridView.builder(
                itemCount: _items.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Image.network(
                          item['image'],
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['name'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['price']} ₽',
                          style: const TextStyle(
                            color: Color(0xFFB6FF3B),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          child: ElevatedButton(
                            onPressed: () => _buyItem(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFFB6FF3B),
                              foregroundColor: Colors.black,
                              minimumSize:
                              const Size(double.infinity, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Купить',
                              style:
                              TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
