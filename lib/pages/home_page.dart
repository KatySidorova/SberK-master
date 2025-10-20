
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  late DatabaseReference userRef;
  late DatabaseReference tipsRef;
  late DatabaseReference usersRef;
  late DatabaseReference transactionsRef;

  int pocket = 0;
  String name = '';
  List<Map> tips = [];

  @override
  void initState() {
    super.initState();
    userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    tipsRef = FirebaseDatabase.instance.ref('tips');
    usersRef = FirebaseDatabase.instance.ref('users');
    transactionsRef = FirebaseDatabase.instance.ref('transactions');

    _listenUser();
    _listenTips();
  }

  void _listenUser() {
    userRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          name = data['name'] ?? '';
          pocket = (data['pocket'] ?? 0) as int;
        });
      }
    });
  }

  void _listenTips() {
    tipsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final loaded =
        data.values.map((e) => Map<String, dynamic>.from(e)).toList();
        loaded.sort(
                (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        setState(() => tips = loaded);
      } else {
        setState(() => tips = []);
      }
    });
  }

  Future<void> _updatePocket(int change) async {
    await userRef.update({'pocket': pocket + change});
  }

  Future<void> _transferMoney() async {
    final idController = TextEditingController();
    final amountController = TextEditingController();
    String transferMode = 'email';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Перевод денег 💸'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('По Email'),
                      selected: transferMode == 'email',
                      onSelected: (_) => setState(() => transferMode = 'email'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('По UID'),
                      selected: transferMode == 'uid',
                      onSelected: (_) => setState(() => transferMode = 'uid'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    labelText: transferMode == 'email'
                        ? 'Email получателя'
                        : 'UID получателя',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Сумма перевода',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final target = idController.text.trim();
                final amount = int.tryParse(amountController.text.trim()) ?? 0;

                if (target.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите корректные данные')),
                  );
                  return;
                }

                if (amount > pocket) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Недостаточно средств 💸')),
                  );
                  return;
                }

                String? receiverUid;

                if (transferMode == 'email') {
                  final snapshot = await usersRef.get();
                  for (final child in snapshot.children) {
                    final data = child.value as Map?;
                    if (data != null && data['email'] == target) {
                      receiverUid = child.key;
                      break;
                    }
                  }
                } else {
                  receiverUid = target;
                }

                if (receiverUid == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пользователь не найден ❌')),
                  );
                  return;
                }

                if (receiverUid == user.uid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Нельзя перевести самому себе 🚫')),
                  );
                  return;
                }

                final receiverRef = usersRef.child(receiverUid);
                final receiverSnap = await receiverRef.get();
                final receiverData = receiverSnap.value as Map?;
                final receiverPocket = (receiverData?['pocket'] ?? 0) as int;

                await userRef.update({'pocket': pocket - amount});
                await receiverRef.update({'pocket': receiverPocket + amount});

                final time = DateTime.now().millisecondsSinceEpoch;

                await transactionsRef.push().set({
                  'from_uid': user.uid,
                  'to_uid': receiverUid,
                  'amount': amount,
                  'timestamp': time,
                  'type': transferMode,
                });

                if (mounted) Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                      Text('Перевод выполнен успешно ✅ (-$amount ₽)')),
                );
              },
              child: const Text('Перевести'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  Future<void> _copyUid() async {
    await Clipboard.setData(ClipboardData(text: user.uid));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UID скопирован 📋')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Приветствие
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()),
                      );
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.lightGreenAccent,
                      radius: 18,
                      child: Icon(Icons.person, color: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Привет, ${name.isNotEmpty ? name : 'пользователь'}!",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text("Управляй своими деньгами!",
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 16),

              // Карта
              Container(
                height: 180,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/32.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              user.uid,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy,
                                color: Colors.white, size: 18),
                            onPressed: _copyUid,
                          ),
                        ],
                      ),
                      const Text('VALID THRU 04/28',
                          style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),


              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Мой баланс 💰",
                              style:
                              TextStyle(color: Colors.grey, fontSize: 14)),
                          Text(
                            "$pocket ₽",
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Image.asset("assets/33.png", height: 60),
                  ],
                ),
              ),
              const SizedBox(height: 20),


              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updatePocket(10),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      child: const Text("+10 ₽",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updatePocket(-10),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      child: const Text("-10 ₽",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),


              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _transferMoney,
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text(
                    'Перевести',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Советы
              const Text("Советы дня 💡",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (tips.isEmpty)
                const Center(child: Text('Советов пока нет. ✍️'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tips.length,
                  itemBuilder: (ctx, i) {
                    final tip = tips[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb,
                              color: Colors.amber, size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tip['text'],
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 6),
                                Text(
                                  "${tip['author']} • ${_formatDate(tip['timestamp'])}",
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 30),


              Padding(
                padding: const EdgeInsets.only(bottom: 90),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _addTip,
                    icon: const Icon(Icons.lightbulb_outline,
                        color: Colors.black),
                    label: const Text('Добавить совет',
                        style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellowAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addTip() async {
    if (_hasPostedToday()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вы уже публиковали совет сегодня 🌞'),
        ),
      );
      return;
    }

    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить совет 💡'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Напиши свой совет...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите текст совета')),
                );
                return;
              }
              if (_containsBadWords(text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Недопустимые слова 🚫')),
                );
                return;
              }
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              await tipsRef.child(id).set({
                'id': id,
                'text': text,
                'author': name.isNotEmpty ? name : 'Аноним',
                'uid': user.uid,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
              if (mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Совет добавлен 💡')),
              );
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  bool _containsBadWords(String text) {
    final badWords = [
      'дурак',
      'идиот',
      'тупой',
      'глупый',
      'чёрт',
      'блин',
      'сволочь',
      'сука',
      'мразь',
      'хрен',
      'дебил',
      'пошёл',
      'урод'
    ];
    final lower = text.toLowerCase();
    for (final word in badWords) {
      if (lower.contains(word)) return true;
    }
    return false;
  }

  bool _hasPostedToday() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final tip in tips) {
      if (tip['uid'] == user.uid) {
        final date = DateFormat('yyyy-MM-dd').format(
          DateTime.fromMillisecondsSinceEpoch(tip['timestamp']),
        );
        if (date == today) return true;
      }
    }
    return false;
  }
}
