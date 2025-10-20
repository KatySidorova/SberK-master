import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class QuizResultsPage extends StatefulWidget {
  const QuizResultsPage({super.key});

  @override
  State<QuizResultsPage> createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  late DatabaseReference _resultsRef;
  Map<String, dynamic> _results = {};

  @override
  void initState() {
    super.initState();
    _resultsRef = FirebaseDatabase.instance.ref('quiz_results/${user.uid}');
    _loadResults();
  }

  void _loadResults() {
    _resultsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() => _results = Map<String, dynamic>.from(data));
      } else {
        setState(() => _results = {});
      }
    });
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Мои результаты'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: _results.isEmpty
          ? const Center(
        child: Text(
          'Вы ещё не проходили викторины 📚',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: _results.entries.map((entry) {
          final category = entry.key;
          final result = Map<String, dynamic>.from(entry.value);
          final score = result['score'] ?? 0;
          final correct = result['correct'] ?? 0;
          final total = result['total'] ?? 10;
          final timestamp = result['timestamp'] ?? 0;

          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.star, color: Colors.blueAccent),
              ),
              title: Text(
                category,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                'Результат: $score%\nПравильных ответов: $correct из $total\nДата: ${_formatDate(timestamp)}',
                style: const TextStyle(height: 1.4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
