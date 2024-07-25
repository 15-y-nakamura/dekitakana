import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({Key? key}) : super(key: key);

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dayController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _dayController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newTask = Task(
          recordNumber: 0, // ダミーのレコード番号、実際にはkintoneから取得される
          isComplete: false, // 初期状態で完了はfalse
          title: _titleController.text,
          day: _dayController.text,
          time: _timeController.text,
        );

        final secureStorage = FlutterSecureStorage();
        final token = await secureStorage.read(key: 'kintoneAPI');
        if (token == null) {
          throw Exception('APIトークンがnullです');
        }

        final appId = '16'; // kintoneのアプリIDを設定する
        final url =
            'https://kvt9cht6gak2.cybozu.com/k/v1/record.json'; // 実際のkintoneのURLに置き換える

        final body = {
          'app': appId,
          'record': {
            '完了': {
              'value': [] // デフォルトで空のリストを送信
            },
            'タイトル': {'value': newTask.title},
            '日付': {'value': newTask.day},
            '時刻': {'value': newTask.time},
          }
        };

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'X-Cybozu-API-Token': token,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('成功'),
              content: Text('追加されました。'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pop(context, newTask);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          final errorResponse = jsonDecode(response.body);
          final errorMessage = errorResponse['message'] ?? 'Unknown error';
          throw Exception('追加に失敗しました: ${response.statusCode} - $errorMessage');
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('エラー'),
            content: Text('追加に失敗しました。エラー: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('閉じる'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('追加'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dayController,
                decoration: const InputDecoration(
                  labelText: '日付',
                  hintText: 'YYYY-MM-DD', // 日付フィールドのステークホルダー
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '日付を入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: '時刻',
                  hintText: 'HH:MM', // 時刻フィールドのステークホルダー
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '時刻を入力してください';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: _addCustomer,
                child: const Text('追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Task {
  final int recordNumber;
  bool isComplete;
  final String title;
  final String day;
  final String time;

  Task({
    required this.recordNumber,
    required this.isComplete,
    required this.title,
    required this.day,
    required this.time,
  });
}
