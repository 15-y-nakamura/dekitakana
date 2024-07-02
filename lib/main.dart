import 'dart:developer';
import 'package:flutter/foundation.dart'; // low-level Utilityクラスのライブラリ
import 'package:flutter/material.dart'; // Material Designのウィジェットのライブラリ

import 'dart:async'; // 非同期プログラムをサポートするライブラリ
import 'dart:convert'; // JSONデータの変換用ライブラリ

import 'package:http/http.dart' as http; // Http Request用のライブラリ
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Secure Storage用のライブラリ
import 'add.dart';
import 'delete.dart'; // ここでdelete.dartをインポートします
import 'time.dart';

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
        '/time': (context) => TimePage(),
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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<Customer>>(
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
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 追加ボタン
          Container(
            width: 70,
            height: 70,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/addCustomer');
              },
              child: const Icon(Icons.add, size: 30),
            ),
          ),
          const SizedBox(height: 16), // ボタン間のスペース

          // 削除ボタン
          Container(
            width: 70,
            height: 70,
            child: FloatingActionButton(
              onPressed: () async {
                print('削除ボタンが押されました。');
                await fetchAllRecords(); // fetchAllRecordsを呼び出す
              },
              child: const Icon(Icons.delete, size: 30),
            ),
          ),
          const SizedBox(height: 16), // ボタン間のスペース

          // 更新ボタン
          Container(
            width: 70,
            height: 70,
            child: FloatingActionButton(
              onPressed: () {
                // 更新ボタンが押された時の処理
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        MyHomePage(title: 'がんばればできる'),
                  ),
                );
              },
              child: const Icon(Icons.refresh, size: 30),
            ),
          ),

          const SizedBox(height: 16), // ボタン間のスペース

          // time.dartに遷移するボタン
          Container(
            width: 70,
            height: 70,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/time');
              },
              child: const Icon(Icons.access_time, size: 30),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                Text('日付: ${widget.customers[index].day}'),
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
  final String day;
  final String time;

  Customer({
    required this.isComplete,
    required this.title,
    required this.day,
    required this.time,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
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
