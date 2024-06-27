import 'dart:developer';

import 'package:flutter/foundation.dart'; // low-level Utilityクラスのライブラリ
import 'package:flutter/material.dart'; // Material Designのウィジェットのライブラリ

import 'dart:async'; // 非同期プログラムをサポートするライブラリ
import 'dart:convert'; // JSONデータの変換用ライブラリ

import 'package:http/http.dart' as http; // Http Request用のライブラリ
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Secure Storage用のライブラリ

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle = 'がんばればできる';

    return MaterialApp(
      title: appTitle,
      home: const MyHomePage(title: appTitle),
      routes: {
        '/addCustomer': (context) => const AddCustomerPage(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<List<Customer>>(
        future: fetchCustomers(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('An error has occurred: ${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            return CustomersList(customers: snapshot.data!);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addCustomer');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CustomersList extends StatefulWidget {
  final List<Customer> customers;

  const CustomersList({Key? key, required this.customers}) : super(key: key);

  @override
  _CustomersListState createState() => _CustomersListState();
}

class _CustomersListState extends State<CustomersList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.customers.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text('タイトル: ${widget.customers[index].title}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('完了: '),
                    Checkbox(
                      value: widget.customers[index].isComplete,
                      onChanged: (bool? value) {
                        setState(() {
                          widget.customers[index].isComplete = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
                Text('時刻: ${widget.customers[index].time}'),
              ],
            ),
          ),
        );
      },
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

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      isComplete: json['完了']['value'].isNotEmpty,
      title: json['タイトル']['value'],
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

  debugPrint("log: $token");

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
    // フォームのデータを使用して新しいCustomerオブジェクトを作成する
    final newCustomer = Customer(
      isComplete: _isComplete, // Customerが完了しているかどうか
      title: _titleController.text, // Customerのタイトル
      time: _timeController.text, // Customerに関連する時刻
    );

    // APIリクエストのパラメータを定義する
    const param = {"app": '16'};
    // APIエンドポイントのURIを構築する
    final uri =
        Uri.https('kvt9cht6gak2.cybozu.com', '/k/v1/record.json', param);

    // セキュアストレージからAPIトークンを読み取る
    final token = await SecureStorage().readSecureData('kintoneAPI');

    // トークンがnullの場合、例外を投げる
    if (token == null) {
      throw Exception('API token is null');
    }

    // APIリクエストを送信する
    final response = await http.post(
      uri,
      headers: {
        'X-Cybozu-API-Token': token, // APIトークンをヘッダーに設定
        'Content-Type': 'application/json', // コンテンツタイプをJSONに設定
      },
      body: jsonEncode({
        'record': {
          '完了': {'value': newCustomer.isComplete ? '完了' : '未完了'}, // 完了ステータス
          'タイトル': {'value': newCustomer.title}, // タイトル
          '時刻': {'value': newCustomer.time}, // 時刻
        },
      }),
    );

    // リクエストが成功した場合、前の画面に戻る
    if (response.statusCode == 200) {
      Navigator.pop(context, newCustomer);
    } else {
      // 失敗した場合、例外を投げる
      throw Exception(
          'Failed to add customer: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

//追加ボタン
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _addCustomer();
                  }
                },
                child: const Text('追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
