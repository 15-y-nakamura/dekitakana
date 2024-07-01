import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({Key? key}) : super(key: key);

  @override
  _AddCustomerPageState createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  bool _isComplete = false;
  final _timeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newCustomer = Customer(
          isComplete: _isComplete,
          title: _titleController.text,
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
              'value': newCustomer.isComplete ? ['完了'] : []
            },
            'タイトル': {'value': newCustomer.title},
            '時刻': {'value': newCustomer.time},
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
          Navigator.pop(context, newCustomer);
        } else {
          final errorResponse = jsonDecode(response.body);
          final errorMessage = errorResponse['message'] ?? 'Unknown error';
          throw Exception(
              '顧客の追加に失敗しました: ${response.statusCode} - $errorMessage');
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('エラー'),
            content: Text('顧客の追加に失敗しました。エラー: $e'),
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
                decoration: const InputDecoration(labelText: 'タイトル'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: '時刻'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '時刻を入力してください';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  const Text('完了: '),
                  Checkbox(
                    value: _isComplete,
                    onChanged: (bool? value) {
                      setState(() {
                        _isComplete = value ?? false;
                      });
                    },
                  ),
                ],
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

class Customer {
  bool isComplete;
  final String title;
  final String time;

  Customer({
    required this.isComplete,
    required this.title,
    required this.time,
  });
}
