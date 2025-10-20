import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  late DatabaseReference _goalsRef;
  late DatabaseReference _userRef;
  int pocket = 0;

  @override
  void initState() {
    super.initState();
    _goalsRef = FirebaseDatabase.instance.ref('users/${user.uid}/goals');
    _userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    _loadPocket();
  }

  Future<void> _loadPocket() async {
    final snap = await _userRef.child('pocket').get();
    if (snap.exists) {
      final val = snap.value;
      setState(() {
        if (val is int) pocket = val;
        else if (val is double) pocket = val.toInt();
        else pocket = int.tryParse(val?.toString() ?? '0') ?? 0;
      });
    }
  }

  Future<void> _createGoal() async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    XFile? image;
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('✨ Новая цель'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      image = picked;
                      setStateDialog(() {});
                    }
                  },
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: const Color(0xFFEFFFE0),
                    backgroundImage:
                    image != null ? FileImage(File(image!.path)) : null,
                    child: image == null
                        ? const Icon(Icons.add_a_photo, size: 30, color: Colors.black54)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Название цели',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Сумма (₽)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? 'До: ${DateFormat('dd.MM.yyyy').format(selectedDate!)}'
                            : 'Выберите дату окончания',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: Colors.black54),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB6FF3B),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final target = double.tryParse(targetCtrl.text.trim()) ?? 0;
                if (name.isEmpty || target <= 0) return;

                String? localPath;
                if (image != null) {
                  final dir = await getApplicationDocumentsDirectory();
                  final file = File(
                      '${dir.path}/goal_${DateTime.now().millisecondsSinceEpoch}.jpg');
                  await File(image!.path).copy(file.path);
                  localPath = file.path;
                }

                final id = DateTime.now().millisecondsSinceEpoch.toString();
                await _goalsRef.child(id).set({
                  'id': id,
                  'name': name,
                  'target': target,
                  'saved': 0,
                  'imagePath': localPath,
                  'completed': false,
                  'endDate':
                  selectedDate != null ? selectedDate!.toIso8601String() : null,
                });
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMoney(String goalId, double currentSaved, double target) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Пополнить цель 💸'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Введите сумму (₽)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB6FF3B),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final value = double.tryParse(controller.text.trim()) ?? 0;
              if (value <= 0) return;

              final snap = await _userRef.child('pocket').get();
              int currentPocket = (snap.value ?? 0) as int;
              if (currentPocket < value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Недостаточно средств 💰')),
                );
                return;
              }

              await _userRef.update({'pocket': currentPocket - value.toInt()});
              final newSaved = currentSaved + value;
              final Map<String, dynamic> updates = {'saved': newSaved};
              if (newSaved >= target) updates['completed'] = true;
              await _goalsRef.child(goalId).update(updates);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Добавить'),
          ),
        ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Мои цели 💰',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFB6FF3B),
          foregroundColor: Colors.black,
          onPressed: _createGoal,
          icon: const Icon(Icons.add),
          label: const Text('Новая цель'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: StreamBuilder(
        stream: _goalsRef.onValue,
        builder: (context, snapshot) {
          final map = snapshot.data?.snapshot.value as Map?;
          if (map == null || map.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pan_tool_alt, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Целей пока нет',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54)),
                  const SizedBox(height: 6),
                  const Text(
                    'Создайте свою первую цель\nи начните путь к успеху!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final goals = map.values.cast<Map>().toList();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: goals.length,
            itemBuilder: (context, i) {
              final g = goals[i];
              final target = (g['target'] as num).toDouble();
              final saved = (g['saved'] as num).toDouble();
              final percent = (target > 0) ? (saved / target).clamp(0.0, 1.0) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FFF1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircularPercentIndicator(
                      radius: 65,
                      lineWidth: 10,
                      percent: percent,
                      progressColor: const Color(0xFFB6FF3B),
                      backgroundColor: Colors.grey.shade200,
                      circularStrokeCap: CircularStrokeCap.round,
                      center: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: g['imagePath'] != null
                            ? FileImage(File(g['imagePath']))
                            : null,
                        child: g['imagePath'] == null
                            ? const Icon(Icons.photo_camera, size: 30, color: Colors.black45)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      g['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('🎯 Цель: ${target.toInt()} ₽', style: const TextStyle(color: Colors.black87)),
                    Text('💰 Накоплено: ${saved.toInt()} ₽', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _addMoney(g['id'], saved, target),
                      icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                      label: const Text('Пополнить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB6FF3B),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
