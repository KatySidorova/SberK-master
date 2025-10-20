import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:katy/splash_screen.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  late DatabaseReference userRef;
  late DatabaseReference goalsRef;
  late DatabaseReference quizRef;

  String name = '';
  String email = '';
  String uid = '';
  int balance = 0;
  double totalSaved = 0;
  double quizProgress = 0.0;
  bool showUid = false;

  @override
  void initState() {
    super.initState();
    email = user.email ?? '';
    uid = user.uid;
    userRef = FirebaseDatabase.instance.ref('users/$uid');
    goalsRef = FirebaseDatabase.instance.ref('users/$uid/goals');
    quizRef = FirebaseDatabase.instance.ref('users/$uid/quizProgress');
    _loadUserData();
    _loadGoals();
    _loadQuizProgress();
  }

  void _loadUserData() {
    userRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          name = (data['name'] ?? 'Пользователь').toString();
          final pocketVal = data['pocket'];
          if (pocketVal is int) balance = pocketVal;
          else if (pocketVal is double) balance = pocketVal.toInt();
          else balance = int.tryParse(pocketVal?.toString() ?? '0') ?? 0;
        });
      }
    });
  }

  void _loadGoals() {
    goalsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        double total = 0;
        for (final item in data.values) {
          final goal = Map<String, dynamic>.from(item);
          final saved = goal['saved'];
          if (saved is int) total += saved.toDouble();
          else if (saved is double) total += saved;
          else total += double.tryParse(saved?.toString() ?? '0') ?? 0;
        }
        setState(() => totalSaved = total);
      } else {
        setState(() => totalSaved = 0);
      }
    });
  }

  void _loadQuizProgress() {
    quizRef.onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        double val = 0;
        if (value is int) val = value.toDouble();
        else if (value is double) val = value;
        else val = double.tryParse(value.toString()) ?? 0;
        setState(() => quizProgress = val.clamp(0.0, 1.0));
      }
    });
  }

  Future<void> _copyUid() async {
    await Clipboard.setData(ClipboardData(text: uid));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UID скопирован 📋')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedBalance = NumberFormat.currency(
      locale: 'ru_RU', symbol: '₽', decimalDigits: 0,
    ).format(balance);

    final formattedSaved = NumberFormat.currency(
      locale: 'ru_RU', symbol: '₽', decimalDigits: 0,
    ).format(totalSaved);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Профиль',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              // 🌀 Полностью очищаем стек навигации
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (route) => false,
              );
            },

            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),


            const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, color: Colors.black54, size: 45),
            ),
            const SizedBox(height: 10),
            Text(
              name.isEmpty ? 'Имя пользователя' : name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),


            Container(
              width: double.infinity,
              height: 250, // увеличил высоту с 150 до 200
              decoration: BoxDecoration(
                color: const Color(0xFFB7FF48),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Katy Bank',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.credit_card, size: 18, color: Colors.black54),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Баланс
                  const Text(
                    'Баланс',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formattedBalance,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),


                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          showUid ? uid : _maskUid(uid),
                          style: const TextStyle(
                            color: Colors.black87,
                            letterSpacing: 2,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: Colors.black54),
                        onPressed: _copyUid,
                      ),
                    ],
                  ),

                  const Spacer(),


                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name.isEmpty ? 'Пользователь' : name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        '12/28',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),


            const SizedBox(height: 24),


            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Информация о пользователе',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person, 'Имя', name),
                  _buildInfoRow(Icons.email, 'Email', email),
                  _buildInfoRow(Icons.wallet, 'Баланс', formattedBalance),
                  _buildInfoRow(Icons.savings, 'Накоплено в целях', formattedSaved),
                ],
              ),
            ),

            const SizedBox(height: 24),


            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Прогресс викторин',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: quizProgress,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: Colors.grey.shade300,
                    color: const Color(0xFF4FC3F7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(quizProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _maskUid(String uid) {
    if (uid.length > 10) {
      return uid.replaceRange(6, uid.length - 4, '•' * (uid.length - 10));
    }
    return uid;
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(color: Colors.black54, fontSize: 15)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
