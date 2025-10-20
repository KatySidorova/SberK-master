import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class ParentGoalsPage extends StatefulWidget {
  const ParentGoalsPage({super.key});

  @override
  State<ParentGoalsPage> createState() => _ParentGoalsPageState();
}

class _ParentGoalsPageState extends State<ParentGoalsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<Map<String, dynamic>> children = [];
  String? selectedChildUid;
  String? selectedChildName;
  int parentPocket = 0;

  @override
  void initState() {
    super.initState();
    _loadParentPocket();
    _loadChildren();
  }


  Future<void> _loadParentPocket() async {
    final parentRef = FirebaseDatabase.instance.ref('parents/${user.uid}/pocket');
    final snapshot = await parentRef.get();
    if (snapshot.exists) {
      setState(() {
        parentPocket = (snapshot.value as num).toInt();
      });
    }
  }


  Future<void> _loadChildren() async {
    final parentRef = FirebaseDatabase.instance.ref('parents/${user.uid}/children');
    final snapshot = await parentRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        children = data.entries.map((e) {
          final child = Map<String, dynamic>.from(e.value);
          return {
            'uid': e.key,
            'name': child['name'] ?? 'Без имени',
          };
        }).toList();
        if (children.isNotEmpty) {
          selectedChildUid = children.first['uid'];
          selectedChildName = children.first['name'];
        }
      });
    }
  }


  Future<void> _helpChildGoal(String goalId, String childUid, double amount) async {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную сумму')),
      );
      return;
    }

    if (amount > parentPocket) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно средств 💸')),
      );
      return;
    }

    final parentRef = FirebaseDatabase.instance.ref('parents/${user.uid}');
    final childGoalRef = FirebaseDatabase.instance.ref('users/$childUid/goals/$goalId/saved');

    await childGoalRef.runTransaction((value) {
      double cur = 0.0;
      if (value is int) cur = value.toDouble();
      if (value is double) cur = value;
      return Transaction.success(cur + amount);
    });

    await parentRef.update({'pocket': parentPocket - amount.toInt()});

    setState(() {
      parentPocket -= amount.toInt();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Вы перевели ${amount.toInt()}₽ ребёнку 🎁')),
    );
  }


  void _showTransferDialog(String goalId, String childUid, String goalName) {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Помочь с целью 💰",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Цель: $goalName",
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Введите сумму (₽)",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Отмена", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        Navigator.pop(context);
                        _helpChildGoal(goalId, childUid, amount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB6FF3B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Перевести",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            const Icon(Icons.child_care, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text(
              "Дети не добавлены",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Добавьте своих детей, чтобы начать\nставить и отслеживать их цели",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add, color: Colors.black),
              label: const Text("Добавить ребёнка",
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB6FF3B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildChildSelector() {
    return DropdownButtonFormField<String>(
      value: selectedChildUid,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
      items: children.map((child) {
        return DropdownMenuItem<String>(
          value: child['uid'],
          child: Row(
            children: [
              const Icon(Icons.child_care, color: Colors.lightBlueAccent),
              const SizedBox(width: 10),
              Text(child['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          selectedChildUid = val;
          selectedChildName = children.firstWhere((c) => c['uid'] == val)['name'];
        });
      },
    );
  }


  Widget _buildNoGoalsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.flag_outlined, size: 70, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "У ребёнка пока нет целей",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Цели детей',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: children.isEmpty
            ? _buildEmptyState()
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChildSelector(),
            const SizedBox(height: 10),
            Text(
              "Ваш баланс: $parentPocket ₽",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseDatabase.instance
                    .ref('users/$selectedChildUid/goals')
                    .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                    return _buildNoGoalsState();
                  }

                  final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                  final goals = data.entries.map((e) {
                    final goal = Map<String, dynamic>.from(e.value);
                    goal['id'] = e.key;
                    return goal;
                  }).toList();

                  return ListView.builder(
                    itemCount: goals.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, i) {
                      final g = goals[i];
                      final saved = (g['saved'] ?? 0).toDouble();
                      final target = (g['target'] ?? 1).toDouble();
                      final percent = (saved / target).clamp(0.0, 1.0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircularPercentIndicator(
                              radius: 38,
                              lineWidth: 6,
                              animation: true,
                              percent: percent,
                              progressColor: const Color(0xFFB6FF3B),
                              backgroundColor: Colors.grey.shade300,
                              circularStrokeCap: CircularStrokeCap.round,
                              center: Text(
                                '${(percent * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g['name'] ?? 'Без названия',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Накоплено: ${saved.toInt()}₽ из ${target.toInt()}₽',
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _showTransferDialog(g['id'], selectedChildUid!, g['name']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB6FF3B),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                              ),
                              child: const Text(
                                '💸',
                                style: TextStyle(color: Colors.black, fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
