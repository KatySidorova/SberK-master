import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  late DatabaseReference parentRef;

  String name = '';
  int pocket = 0;
  Map<String, dynamic> children = {};

  final _childUidCtrl = TextEditingController();
  final _childNameCtrl = TextEditingController();
  final _transferAmountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    parentRef = FirebaseDatabase.instance.ref('parents/${user.uid}');
    _loadParentData();
  }

  void _loadParentData() {
    parentRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          name = data['name'] ?? 'Пользователь';
          pocket = (data['pocket'] ?? 0) as int;
          children = Map<String, dynamic>.from(data['children'] ?? {});
        });
      }
    });
  }

  Future<void> _updatePocket(int change) async {
    await parentRef.update({'pocket': pocket + change});
  }

  Future<void> _addChild() async {
    final uid = _childUidCtrl.text.trim();
    final cname = _childNameCtrl.text.trim();

    if (uid.isEmpty || cname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите UID и имя ребёнка')),
      );
      return;
    }

    final childSnap = await FirebaseDatabase.instance.ref('users/$uid').get();

    if (!childSnap.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ребёнок с таким UID не найден ❌')),
      );
      return;
    }

    await parentRef.child('children/$uid').set({
      'uid': uid,
      'name': cname,
    });

    _childUidCtrl.clear();
    _childNameCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ребёнок $cname добавлен ✅')),
    );
  }

  Future<void> _transferToChild(String childUid, String childName) async {
    final amount = int.tryParse(_transferAmountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную сумму')),
      );
      return;
    }
    if (amount > pocket) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно средств 💸')),
      );
      return;
    }

    final childRef = FirebaseDatabase.instance.ref('users/$childUid');
    final snap = await childRef.get();

    if (!snap.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ребёнок не найден ❌')),
      );
      return;
    }

    final data = snap.value as Map;
    final currentPocket = (data['pocket'] ?? 0) as int;

    await childRef.update({'pocket': currentPocket + amount});
    await parentRef.update({'pocket': pocket - amount});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Перевод $amount ₽ → $childName выполнен ✅')),
    );

    _transferAmountCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFB6FF3B),
                    radius: 18,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Привет, ${name.isNotEmpty ? name : 'друг'}!",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Управляй своими деньгами!",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 20),


              Center(
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/35.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),


              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text("Ваш баланс",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      "$pocket ₽",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updatePocket(100),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB6FF3B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "+100 ₽",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updatePocket(-100),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "-100 ₽",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),


              _buildAddChildSection(),

              const SizedBox(height: 24),


              children.isEmpty
                  ? _buildEmptyChildrenCard()
                  : _buildChildrenList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddChildSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Добавить ребёнка 🔒",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _childUidCtrl,
            decoration: InputDecoration(
              hintText: "UID ребёнка",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _childNameCtrl,
            decoration: InputDecoration(
              hintText: "Имя ребёнка",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton.icon(
              onPressed: _addChild,
              icon: const Icon(Icons.person_add, color: Colors.black),
              label: const Text("Добавить",
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB6FF3B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChildrenCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.sentiment_satisfied_alt,
              size: 36, color: Colors.amber),
          SizedBox(width: 12),
          Expanded(
            child: Text("Дети пока не добавлены",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ваши дети',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...children.values.map((child) {
          final c = Map<String, dynamic>.from(child);
          return Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFB6FF3B),
                child: Icon(Icons.child_care, color: Colors.black),
              ),
              title: Text(c['name'] ?? 'Без имени',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('UID: ${c['uid']}'),
              trailing: IconButton(
                icon: const Icon(Icons.send, color: Colors.lightBlueAccent),
                onPressed: () {
                  _transferAmountCtrl.clear();
                  showDialog(
                    context: context,
                    builder: (_) => _buildTransferDialog(c),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTransferDialog(Map<String, dynamic> c) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Перевод для ${c['name']}",
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: _transferAmountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Введите сумму (₽)",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Отмена",
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _transferToChild(c['uid'], c['name']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB6FF3B),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Перевести",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
