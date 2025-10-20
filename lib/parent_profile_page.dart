import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key});

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  late DatabaseReference parentRef;
  late DatabaseReference childrenRef;

  String name = '';
  String email = '';
  String uid = '';
  int balance = 0;
  bool showUid = false;

  List<Map<String, dynamic>> children = [];
  double totalChildrenBalance = 0;
  double totalChildrenGoals = 0;

  @override
  void initState() {
    super.initState();
    email = user.email ?? '';
    uid = user.uid;

    parentRef = FirebaseDatabase.instance.ref('parent/$uid');
    childrenRef = FirebaseDatabase.instance.ref('parent/$uid/children');

    _loadParentData();
    _loadChildrenData();
  }

  void _loadParentData() {
    parentRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          name = (data['name'] ?? 'Без имени').toString();
          final pocketVal = data['pocket'];
          if (pocketVal is int) balance = pocketVal;
          else if (pocketVal is double) balance = pocketVal.toInt();
          else balance = int.tryParse(pocketVal?.toString() ?? '0') ?? 0;
        });
      }
    });
  }

  void _loadChildrenData() {
    // Используем ту же ссылку, что и в ParentHomePage
    final parentRef = FirebaseDatabase.instance.ref('parents/$uid');

    parentRef.onValue.listen((event) async {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        setState(() {
          children = [];
          totalChildrenBalance = 0;
          totalChildrenGoals = 0;
        });
        return;
      }

      // Извлекаем всех детей
      final kids = Map<String, dynamic>.from(data['children'] ?? {});
      List<Map<String, dynamic>> list = [];
      double totalBal = 0;
      double totalGoal = 0;

      for (final entry in kids.entries) {
        final childUid = entry.key;
        final child = Map<String, dynamic>.from(entry.value);
        final name = child['name'] ?? 'Без имени';

        // Загружаем актуальные данные ребёнка из users
        final userSnap = await FirebaseDatabase.instance.ref('users/$childUid').get();
        int balance = 0;
        double goalSum = 0;

        if (userSnap.exists) {
          final udata = Map<String, dynamic>.from(userSnap.value as Map);
          final p = udata['pocket'];
          if (p is int) balance = p;
          else if (p is double) balance = p.toInt();
          else balance = int.tryParse(p?.toString() ?? '0') ?? 0;

          // Суммируем цели
          final goalsSnap = await FirebaseDatabase.instance.ref('users/$childUid/goals').get();
          if (goalsSnap.exists) {
            final gdata = Map<String, dynamic>.from(goalsSnap.value as Map);
            for (final g in gdata.values) {
              final goal = Map<String, dynamic>.from(g);
              final saved = goal['saved'];
              if (saved is int) goalSum += saved.toDouble();
              else if (saved is double) goalSum += saved;
              else goalSum += double.tryParse(saved?.toString() ?? '0') ?? 0;
            }
          }
        }

        totalBal += balance;
        totalGoal += goalSum;

        list.add({
          'uid': childUid,
          'name': name,
          'balance': balance,
          'goals': goalSum,
        });
      }

      setState(() {
        children = list;
        totalChildrenBalance = totalBal;
        totalChildrenGoals = totalGoal;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final formattedBalance = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format(balance);
    final formattedChildrenBalance = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format(totalChildrenBalance);
    final formattedChildrenGoals = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format(totalChildrenGoals);
    final maskedUid = uid.length > 10 ? uid.replaceRange(6, uid.length - 4, '•' * (uid.length - 10)) : uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE9FFD7), Color(0xFFF8FFF1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Профиль родителя',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 💳 Карточка родителя
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFB6FF3B),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Баланс',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        Text(name,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(formattedBalance,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 34,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            showUid ? uid : maskedUid,
                            style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                letterSpacing: 1.2),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            showUid
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.black54,
                            size: 20,
                          ),
                          onPressed: () async {
                            setState(() => showUid = !showUid);
                            await Clipboard.setData(ClipboardData(text: uid));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('UID скопирован'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),


              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Дети и их накопления',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    const SizedBox(height: 10),
                    if (children.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Дети не добавлены',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      Column(
                        children: children.map((child) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FFF3),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFB6FF3B), width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.child_care,
                                        color: Colors.lightGreen),
                                    const SizedBox(width: 10),
                                    Text(child['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                Text(
                                  '${child['balance']} ₽ / ${child['goals']} ₽',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const Divider(height: 30),
                    Text('Общий баланс детей: $formattedChildrenBalance',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87)),
                    Text('Общая сумма в целях: $formattedChildrenGoals',
                        style:
                        const TextStyle(color: Colors.black54, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 25),


              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;


                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/splash',
                        (Route<dynamic> route) => false,
                  );
                },

                icon: const Icon(Icons.logout),
                label: const Text('Выйти'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
