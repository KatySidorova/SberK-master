import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class QuizPage extends StatefulWidget {
  final String category;
  const QuizPage({super.key, required this.category});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final user = FirebaseAuth.instance.currentUser!;
  late DatabaseReference _resultsRef;

  int currentIndex = 0;
  int correctAnswers = 0;
  int? selectedIndex;

  late List<Map<String, dynamic>> questions;

  @override
  void initState() {
    super.initState();
    _resultsRef = FirebaseDatabase.instance.ref('quiz_results/${user.uid}');
    questions = _getQuestions(widget.category);
  }

  List<Map<String, dynamic>> _getQuestions(String category) {
    switch (category) {
      case 'Финансовая грамотность':
        return _financeQuestions;
      case 'Кибербезопасность':
        return _cyberQuestions;
      case 'Право России':
        return _lawQuestions;
      default:
        return [];
    }
  }

  void _checkAnswer(int index) {

    setState(() {
      selectedIndex = index;
    });
  }

  void _nextQuestion() {
    if (selectedIndex == null) return;


    if (questions[currentIndex]['correct'] == selectedIndex) {
      correctAnswers++;
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedIndex = null;
      });
    } else {
      _showResult();
    }
  }

  Future<void> _showResult() async {
    final score = ((correctAnswers / questions.length) * 100).round();
    await _resultsRef.child(widget.category).set({
      'score': score,
      'correct': correctAnswers,
      'total': questions.length,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎯 Результат'),
        content: Text(
          'Вы ответили правильно на $correctAnswers из ${questions.length} вопросов.\n\nРезультат: $score%',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }


  IconData _getCategoryIcon() {
    switch (widget.category) {
      case 'Финансовая грамотность':
        return Icons.savings_rounded;
      case 'Кибербезопасность':
        return Icons.security_rounded;
      case 'Право России':
        return Icons.balance_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }

  Color _getCategoryColor() {
    switch (widget.category) {
      case 'Финансовая грамотность':
        return Colors.green;
      case 'Кибербезопасность':
        return Colors.blue;
      case 'Право России':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[currentIndex];
    final progress = (currentIndex + 1) / questions.length;
    final categoryColor = _getCategoryColor();
    final categoryIcon = _getCategoryIcon();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔙 Навигация
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 6),


              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Вопрос ${currentIndex + 1} из ${questions.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: categoryColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(categoryColor),
                ),
              ),

              const SizedBox(height: 20),


              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(categoryIcon,
                          color: categoryColor, size: 30),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      q['question'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),


              Expanded(
                child: ListView.builder(
                  itemCount: q['options'].length,
                  itemBuilder: (context, i) {
                    final option = q['options'][i];
                    final isSelected = selectedIndex == i;

                    Color borderColor = Colors.grey.shade300;
                    Color fillColor = Colors.white;

                    if (isSelected) {
                      borderColor = categoryColor;
                      fillColor = categoryColor.withOpacity(0.1);
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected ? categoryColor : Colors.grey,
                        ),
                        title: Text(option,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black87)),
                        onTap: () => _checkAnswer(i),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),


              ElevatedButton(
                onPressed: selectedIndex != null ? _nextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedIndex != null
                      ? Colors.black
                      : Colors.grey.shade400,
                  minimumSize: const Size(double.infinity, 54),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  currentIndex == questions.length - 1
                      ? 'Завершить'
                      : 'Следующий вопрос  →',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
final _financeQuestions = [
  {
    'question': 'Что такое бюджет?',
    'options': ['План доходов и расходов', 'Вид кредита', 'Банк для детей', 'Счёт в банке'],
    'correct': 0
  },
  {
    'question': 'Что нужно делать, чтобы накопить деньги?',
    'options': ['Тратить всё сразу', 'Откладывать часть дохода', 'Просить у друзей', 'Игнорировать расходы'],
    'correct': 1
  },
  {
    'question': 'Как называется плата банку за использование кредита?',
    'options': ['Процент', 'Бонус', 'Налог', 'Подарок'],
    'correct': 0
  },
  {
    'question': 'Что безопаснее для хранения денег?',
    'options': ['Под подушкой', 'В банке', 'В кармане', 'У друга'],
    'correct': 1
  },
  {
    'question': 'Что такое инвестиции?',
    'options': ['Покупка игрушек', 'Вложение денег с целью прибыли', 'Подарки друзьям', 'Траты на еду'],
    'correct': 1
  },
  {
    'question': 'Что значит "доход"?',
    'options': ['Деньги, которые ты зарабатываешь', 'Твои расходы', 'Долг', 'Кредит'],
    'correct': 0
  },
  {
    'question': 'Что такое кредит?',
    'options': ['Подарок от банка', 'Деньги, взятые взаймы под проценты', 'Доход', 'Инвестиция'],
    'correct': 1
  },
  {
    'question': 'Какой из вариантов помогает экономить?',
    'options': ['Планирование покупок', 'Импульсивные траты', 'Игнорирование бюджета', 'Покупка лишнего'],
    'correct': 0
  },
  {
    'question': 'Кто такой вкладчик?',
    'options': ['Тот, кто берёт кредит', 'Тот, кто кладёт деньги в банк', 'Работник банка', 'Продавец'],
    'correct': 1
  },
  {
    'question': 'Что делать при получении зарплаты?',
    'options': ['Потратить всё', 'Часть отложить и часть потратить', 'Отдать друзьям', 'Игнорировать'],
    'correct': 1
  },
];

final _cyberQuestions = [
  {
    'question': 'Что нельзя сообщать в интернете?',
    'options': ['Имя', 'Возраст', 'Пароль и номер карты', 'Любимый цвет'],
    'correct': 2
  },
  {
    'question': 'Фишинг — это...',
    'options': ['Игра', 'Мошенничество с поддельными письмами', 'Обновление приложения', 'Защита данных'],
    'correct': 1
  },
  {
    'question': 'Как распознать вирусное письмо?',
    'options': ['Ошибки в тексте, ссылки, просьбы что-то скачать', 'От друга', 'С адреса банка', 'Без текста'],
    'correct': 0
  },
  {
    'question': 'Что нужно делать с подозрительной ссылкой?',
    'options': ['Открыть её', 'Переслать другу', 'Игнорировать и удалить', 'Сохранить'],
    'correct': 2
  },
  {
    'question': 'Безопасный пароль — это...',
    'options': ['123456', 'qwerty', 'Katya2025!', 'parol'],
    'correct': 2
  },
  {
    'question': 'Нужно ли делиться личными фото с незнакомцами?',
    'options': ['Да', 'Нет', 'Если просят вежливо', 'Если обещают подарок'],
    'correct': 1
  },
  {
    'question': 'Что делать, если тебе пишут с угрозами?',
    'options': ['Ответить', 'Удалить аккаунт', 'Сказать взрослым и пожаловаться', 'Игнорировать'],
    'correct': 2
  },
  {
    'question': 'Можно ли заходить на подозрительные сайты?',
    'options': ['Да', 'Нет', 'Иногда', 'Только днём'],
    'correct': 1
  },
  {
    'question': 'Для чего нужен антивирус?',
    'options': ['Для игр', 'Для защиты устройства от вредных программ', 'Для ускорения интернета', 'Для загрузки видео'],
    'correct': 1
  },
  {
    'question': 'Что делать перед установкой приложения?',
    'options': ['Проверить отзывы и разрешения', 'Сразу установить', 'Игнорировать', 'Открыть через почту'],
    'correct': 0
  },
];

final _lawQuestions = [
  {
    'question': 'Конституция РФ — это...',
    'options': ['Закон о погоде', 'Основной закон государства', 'Сборник рассказов', 'Документ о налогах'],
    'correct': 1
  },
  {
    'question': 'С какого возраста наступает административная ответственность?',
    'options': ['6 лет', '14 лет', '16 лет', '18 лет'],
    'correct': 2
  },
  {
    'question': 'Кто защищает права граждан?',
    'options': ['Президент', 'Прокуратура и суд', 'Полиция и МЧС', 'Соседи'],
    'correct': 1
  },
  {
    'question': 'Что нельзя делать в общественных местах?',
    'options': ['Помогать людям', 'Слушать музыку в наушниках', 'Нарушать порядок и мусорить', 'Читать книгу'],
    'correct': 2
  },
  {
    'question': 'Какой документ удостоверяет личность?',
    'options': ['Паспорт', 'Блокнот', 'Дневник', 'Телефон'],
    'correct': 0
  },
  {
    'question': 'Что означает слово "обязанность"?',
    'options': ['То, что ты можешь не делать', 'То, что нужно выполнять по закону', 'Игра', 'Желание'],
    'correct': 1
  },
  {
    'question': 'Кто имеет право на бесплатное образование?',
    'options': ['Только взрослые', 'Все граждане России', 'Иностранцы', 'Только богатые'],
    'correct': 1
  },
  {
    'question': 'Что запрещает Конституция РФ?',
    'options': ['Труд', 'Отдых', 'Дискриминацию и насилие', 'Образование'],
    'correct': 2
  },
  {
    'question': 'Как гражданин может участвовать в жизни страны?',
    'options': ['Выбирать власть на выборах', 'Игнорировать политику', 'Не работать', 'Нарушать законы'],
    'correct': 0
  },
  {
    'question': 'Что делать, если нарушены твои права?',
    'options': ['Ничего', 'Жаловаться в соответствующие органы', 'Злиться', 'Молчать'],
    'correct': 1
  },
];
