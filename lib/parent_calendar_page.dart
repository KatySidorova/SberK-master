import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';

class ParentCalendarPage extends StatefulWidget {
  const ParentCalendarPage({super.key});

  @override
  State<ParentCalendarPage> createState() => _ParentCalendarPageState();
}

class _ParentCalendarPageState extends State<ParentCalendarPage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<Map<String, dynamic>> children = [];
  String? selectedChildUid;
  String? selectedChildName;

  DatabaseReference? _eventsRef;

  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final parentRef =
    FirebaseDatabase.instance.ref('parents/${user.uid}/children');
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
          _setEventRef();
        }
      });
    }
  }

  void _setEventRef() {
    if (selectedChildUid == null) return;
    _eventsRef = FirebaseDatabase.instance.ref('users/$selectedChildUid/events');
    _loadEvents();
  }

  void _loadEvents() {
    _eventsRef?.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        setState(() => _events = {});
        return;
      }

      final Map<DateTime, List<String>> loaded = {};
      data.forEach((key, value) {
        try {
          final date = DateTime.parse(key);
          final list = (value as List).map((e) => e.toString()).toList();
          loaded[date] = list;
        } catch (_) {}
      });

      setState(() => _events = loaded);
    });
  }

  List<String> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  Future<void> _addEvent() async {
    if (selectedChildUid == null || _eventsRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите ребёнка')),
      );
      return;
    }

    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Новое событие (${selectedChildName ?? ""})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Введите заметку',
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
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Отмена',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final text = controller.text.trim();
                        if (text.isNotEmpty) {
                          final dateKey =
                              '${_selectedDay.year.toString().padLeft(4, '0')}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}';

                          final eventsList = _getEventsForDay(_selectedDay);
                          eventsList.add('👨‍👩‍👧 Родитель: $text');
                          await _eventsRef!.child(dateKey).set(eventsList);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Событие добавлено ✅')),
                          );
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB6FF3B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Добавить',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                      top: 30, left: 20, right: 20, bottom: 25),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDAFECF), Color(0xFFEFFFF8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Календарь детей",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("Планируй свой день",
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),


                if (children.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedChildUid,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    icon:
                    const Icon(Icons.arrow_drop_down, color: Colors.black),
                    items: children.map((child) {
                      return DropdownMenuItem<String>(
                        value: child['uid'],
                        child: Row(
                          children: [
                            const Icon(Icons.child_care,
                                color: Colors.lightBlueAccent),
                            const SizedBox(width: 10),
                            Text(child['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedChildUid = val;
                        selectedChildName = children
                            .firstWhere((c) => c['uid'] == val)['name'];
                        _setEventRef();
                      });
                    },
                  ),

                const SizedBox(height: 16),

                // 📅 Календарь
                Container(
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
                  child: TableCalendar(
                    focusedDay: _focusedDay,
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    calendarFormat: _format,
                    onFormatChanged: (f) => setState(() => _format = f),
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    eventLoader: _getEventsForDay,
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.lightBlueAccent.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFFB6FF3B),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Colors.lightBlueAccent,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "События сегодня",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),
                const SizedBox(height: 10),

                if (selectedEvents.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Text("Событий пока нет",
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...selectedEvents.map((e) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFFF8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFB6FF3B), width: 1),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.event_note,
                            color: Colors.lightGreen),
                        title: Text(e,
                            style:
                            const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),


      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFB6FF3B),
          elevation: 5,
          onPressed: _addEvent,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
