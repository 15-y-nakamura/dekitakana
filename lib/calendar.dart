import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Map<DateTime, List<dynamic>> _events;
  late List<dynamic> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _events = {};
    _selectedEvents = [];
    fetchKintoneData();
  }

  Future<void> fetchKintoneData() async {
    final token = await storage.read(key: 'kintoneAPI');
    if (token == null) {
      throw Exception('APIトークンがnullです');
    }

    final param = {"app": '16'};
    final uri =
        Uri.https('kvt9cht6gak2.cybozu.com', '/k/v1/records.json', param);

    final response = await http.get(
      uri,
      headers: {'X-Cybozu-API-Token': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _events = {};
        for (var record in data['records']) {
          DateTime date = DateTime.parse(record['日付']['value']);
          if (_events[date] == null) _events[date] = [];
          _events[date]!.add({
            'title': record['タイトル']['value'],
            'time': record['時刻']['value'],
            'isComplete': record['完了']['value'].isNotEmpty,
          });
        }
      });
    } else {
      throw Exception('データの読み込みに失敗しました: ${response.statusCode}');
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedEvents = _getEventsForDay(selectedDay);
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
                    child: Text('この日にイベントはありません。'),
                  )
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_selectedEvents[index]['title']),
                        subtitle: Text(_selectedEvents[index]['time']),
                        trailing: Icon(
                          _selectedEvents[index]['isComplete']
                              ? Icons.check_circle
                              : Icons.circle,
                          color: _selectedEvents[index]['isComplete']
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
