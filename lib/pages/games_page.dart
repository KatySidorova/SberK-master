import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'goals_page.dart';
import 'quiz_page.dart';
import 'quiz_results_page.dart';
import 'store_page.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  double progress = 0.0;
  final databaseRef = FirebaseDatabase.instance.ref();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadQuizProgress();
  }

  Future<void> _loadQuizProgress() async {
    if (user == null) return;

    final userId = user!.uid;
    final snapshot = await databaseRef.child('quiz_results/$userId').get();

    if (snapshot.exists) {
      final quizzes = snapshot.value as Map<dynamic, dynamic>;
      final completedCount = quizzes.length;

      const totalQuizzes = 3;
      final ratio = (completedCount / totalQuizzes).clamp(0.0, 1.0);

      setState(() {
        progress = ratio.toDouble();
      });
    } else {
      setState(() => progress = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF5),
      body: RefreshIndicator(
        onRefresh: _loadQuizProgress,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 70, left: 20, right: 20, bottom: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE9FFE7),
                      Color(0xFFF8FFF5),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Игры и обучение',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Выбери своё приключение',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),

                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB9FBC0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sports_esports, color: Colors.green, size: 26),
                    ),
                  ],
                ),
              ),


              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _gameCard(
                      context,
                      icon: Icons.shopping_cart,
                      iconColor: Colors.green,
                      title: 'Магазин мерча',
                      subtitle: 'уникальные предметы от Нексии',
                      tagText: 'Новинки',
                      tagColor: Colors.green.shade200,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StorePage()),
                      ),
                    ),
                    _gameCard(
                      context,
                      icon: Icons.savings_rounded,
                      iconColor: Colors.pink,
                      title: 'Копилка',
                      subtitle: 'учись копить и достигать целей',
                      tagText: 'Цели',
                      tagColor: Colors.pink.shade100,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GoalsPage()),
                      ),
                    ),
                    _gameCard(
                      context,
                      icon: Icons.quiz_rounded,
                      iconColor: Colors.blue,
                      title: 'Викторины',
                      subtitle: 'проверь свои знания и получи награды',
                      tagText: 'Играть',
                      tagColor: Colors.blue.shade100,
                      onTap: () => _openQuizSelector(context),
                    ),
                    const SizedBox(height: 20),


                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Твой прогресс',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.green, Colors.lightGreenAccent],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _gameCard(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required String tagText,
        required Color tagColor,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(subtitle, style: const TextStyle(fontSize: 14)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: tagColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tagText,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }


  void _openQuizSelector(BuildContext context) {
    final quizzes = [
      {
        'title': 'Финансовая грамотность',
        'subtitle': 'Управление деньгами и инвестиции',
        'icon': Icons.account_balance_wallet_rounded,
        'emoji': '💰',
        'questions': 10,
        'accentColor': Colors.green
      },
      {
        'title': 'Кибербезопасность',
        'subtitle': 'Защита в цифровом мире',
        'icon': Icons.security_rounded,
        'emoji': '🔒',
        'questions': 10,
        'accentColor': Colors.blue
      },
      {
        'title': 'Право России',
        'subtitle': 'Основы российского законодательства',
        'icon': Icons.balance_rounded,
        'emoji': '⚖️',
        'questions': 10,
        'accentColor': Colors.teal
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8FFF5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Выбери викторину 💡',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 60,
              height: 3,
              margin: const EdgeInsets.only(top: 4, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(3),
              ),
            ),


            ...quizzes.map((q) {
              final accent = q['accentColor'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      q['icon'] as IconData,
                      color: accent,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    q['title'] as String,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q['subtitle'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${q['emoji']} ${q['questions']} вопросов',
                        style: TextStyle(
                          fontSize: 14,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: accent, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizPage(
                          category: (q['title'] as String),
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),

            const SizedBox(height: 10),


            ElevatedButton.icon(
              icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
              label: const Text(
                'Мои результаты',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                elevation: 5,
                shadowColor: Colors.green.withOpacity(0.3),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizResultsPage()),
                );
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }


}
