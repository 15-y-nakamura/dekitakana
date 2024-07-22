import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/foundation.dart';

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

  @override
  void initState() {
    super.initState();
    _events = {};
    _selectedEvents = [];
    fetchKintoneData();
  }

  Future<void> fetchKintoneData() async {
    final List<Customer> customers = await fetchCustomers(http.Client());

    setState(() {
      _events = {};
      for (var customer in customers) {
        DateTime date = DateTime.parse(customer.day);
        date = DateTime(date.year, date.month, date.day); // 日付をフォーマット
        if (_events[date] == null) _events[date] = [];
        _events[date]!.add({
          'title': customer.title,
          'time': customer.time,
          'isComplete': customer.isComplete,
        });
      }
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? []; // 日付をフォーマット
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
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
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

// Customerクラスとデータ取得関数を含む部分

class Customer {
  final int recordNumber;
  bool isComplete;
  final String title;
  final String day;
  final String time;

  Customer({
    required this.recordNumber,
    required this.isComplete,
    required this.title,
    required this.day,
    required this.time,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      recordNumber: int.parse(json['レコード番号']['value']),
      isComplete: json['完了']['value'].isNotEmpty,
      title: json['タイトル']['value'],
      day: json['日付']['value'],
      time: json['時刻']['value'],
    );
  }
}

Future<List<Customer>> fetchCustomers(http.Client client) async {
  const param = {"app": '16'};
  final uri = Uri.https('kvt9cht6gak2.cybozu.com', '/k/v1/records.json', param);

  await SecureStorage().deleteSecureData('kintoneAPI');
  await SecureStorage().writeSecureData(
      'kintoneAPI', 'eacrQLrVRaSeFYkafsZr2NjthyqnyGZGAFBEHW3n');
  final token = await SecureStorage().readSecureData('kintoneAPI');

  if (token == null) {
    throw Exception('API token is null');
  }

  final response = await client.get(
    uri,
    headers: {
      'X-Cybozu-API-Token': token,
    },
  );

  if (response.statusCode == 200) {
    return compute(parseCustomers, response.body);
  } else {
    throw Exception(
        'Failed to load customers: ${response.statusCode} - ${response.reasonPhrase}');
  }
}

List<Customer> parseCustomers(String responseBody) {
  final parsed =
      jsonDecode(responseBody)['records'].cast<Map<String, dynamic>>();
  return parsed.map<Customer>((json) => Customer.fromJson(json)).toList();
}

// SecureStorageクラス

class SecureStorage {
  final storage = const FlutterSecureStorage();

  Future<String?> readSecureData(String key) async {
    return await storage.read(key: key);
  }

  Future<void> writeSecureData(String key, String value) async {
    await storage.write(key: key, value: value);
  }

  Future<void> deleteSecureData(String key) async {
    await storage.delete(key: key);
  }
}
