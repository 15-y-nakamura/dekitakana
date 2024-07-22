import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'add.dart';
import 'ble_home.dart';
import 'delete.dart';
import 'calendar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle = 'できたかなチェック';

    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: appTitle),
      routes: {
        '/addCustomer': (context) => const AddCustomerPage(),
        '/bleHome': (context) => const BleHomePage(),
        '/calendar': (context) => const CalendarPage(),
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          FutureBuilder<List<Customer>>(
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
          Align(
            alignment: Alignment.bottomCenter,
            child: BLEControl(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              final newCustomer =
                  await Navigator.pushNamed(context, '/addCustomer');
              if (newCustomer != null && newCustomer is Customer) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('追加しました: ${newCustomer.title}')),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        MyHomePage(title: 'できたかなチェック'),
                  ),
                );
              }
            },
            child: const Icon(Icons.add, size: 30),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () async {
              print('削除ボタンが押されました。');
              await fetchAllRecords(context);
            },
            child: const Icon(Icons.delete, size: 30),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      MyHomePage(title: 'できたかなチェック'),
                ),
              );
            },
            child: const Icon(Icons.refresh, size: 30),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/bleHome');
            },
            child: const Icon(Icons.bluetooth, size: 30),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/calendar');
            },
            child: const Icon(Icons.calendar_today, size: 30),
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
  Future<void> _updateCompletionStatus(
      Customer customer, bool isComplete) async {
    final secureStorage = FlutterSecureStorage();
    final token = await secureStorage.read(key: 'kintoneAPI');
    if (token == null) {
      throw Exception('APIトークンがnullです');
    }

    final appId = '16';
    final url = 'https://kvt9cht6gak2.cybozu.com/k/v1/record.json';

    final body = {
      'app': appId,
      'id': customer.recordNumber,
      'record': {
        '完了': {
          'value': isComplete ? ['完了'] : []
        },
      }
    };

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'X-Cybozu-API-Token': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final errorResponse = jsonDecode(response.body);
      final errorMessage = errorResponse['message'] ?? 'Unknown error';
      throw Exception('更新に失敗しました: ${response.statusCode} - $errorMessage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.customers.length,
      itemBuilder: (context, index) {
        final customer = widget.customers[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text('タイトル: ${customer.title}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('完了: '),
                    Checkbox(
                      value: customer.isComplete,
                      onChanged: (bool? value) {
                        setState(() {
                          customer.isComplete = value ?? false;
                        });
                        _updateCompletionStatus(customer, value ?? false);
                      },
                    ),
                  ],
                ),
                Text('日付: ${customer.day}'),
                Text('時刻: ${customer.time}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

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

class BLEControl extends StatefulWidget {
  @override
  _BLEControlState createState() => _BLEControlState();
}

class _BLEControlState extends State<BLEControl> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? targetDevice;

  final String ledServiceUUID = 'e95dd91d-251d-470a-a062-fa1922dfa9a8';
  String message = "Waiting for auto connect...";
  bool isScanning = false; // スキャン状態を追跡するためのフラグ

  @override
  void initState() {
    super.initState();
    fetchAllRecords(); // レコードチェックを開始
  }

  void connectToMicrobit() {
    if (isScanning) return; // スキャンが進行中であれば何もしない

    setState(() {
      message = "Connecting...";
      isScanning = true; // スキャン状態を更新
    });

    flutterBlue.startScan(timeout: Duration(seconds: 4)).then((_) {
      flutterBlue.scanResults.listen((results) async {
        for (ScanResult result in results) {
          if (result.device.name.startsWith('BBC micro:bit')) {
            targetDevice = result.device;
            break;
          }
        }

        if (targetDevice != null) {
          flutterBlue.stopScan().then((_) async {
            await _connectToDevice();
            setState(() {
              isScanning = false; // スキャン状態をリセット
            });
          });
        } else {
          setState(() {
            message = "Device not found.";
            isScanning = false; // スキャン状態をリセット
          });
        }
      });
    });
  }

  Future<void> _connectToDevice() async {
    if (targetDevice == null) return;

    await targetDevice!.connect();
    List<BluetoothService> services = await targetDevice!.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString() == ledServiceUUID) {
        setState(() {
          message = "Connected to micro:bit.";
        });
        // 10秒後に接続を切断
        Future.delayed(Duration(seconds: 10), () {
          _disconnect();
        });
      }
    }
  }

  void _disconnect() {
    if (targetDevice != null) {
      targetDevice!.disconnect();
    }
    setState(() {
      targetDevice = null;
      message = "Disconnected";
    });
  }

  Future<void> fetchAllRecords() async {
    final String apiUrl = 'https://kvt9cht6gak2.cybozu.com/k/v1/records.json';
    final String apiToken =
        'eacrQLrVRaSeFYkafsZr2NjthyqnyGZGAFBEHW3n'; // あなたのAPIトークンを設定する

    final Map<String, String> headers = {
      'X-Cybozu-API-Token': apiToken,
    };

    while (true) {
      // 無限ループでずっと処理する
      // GETリクエストのURL構築
      final String url = '$apiUrl?app=16';

      final http.Response response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        List<dynamic> records = data['records']; // レコードのリストを取得

        print(records);

        //現在の日付と時刻を取得
        DateTime now = DateTime.now();
        String formattedNow = DateFormat('yyyy-MM-dd HH:mm').format(now);

        //レコードごとに処理する例を示すためのコメントアウト
        List<Map<String, dynamic>> formattedRecords = [];
        for (var record in records) {
          String recordDate = record['日付']['value']; // レコードの日付を取得
          String recordTime = record['時刻']['value']; // レコードの時刻を取得
          String recordDateTime = '$recordDate $recordTime';

          if (recordDateTime == formattedNow) {
            formattedRecords.add({
              'レコード番号': record['レコード番号']['value'],
              '日時': recordDateTime,
            });
            print("現在の日付と時刻と一致しました: $recordDateTime");

            // マイクロビットにイベントを送信
            if (targetDevice != null) {
              await _sendEventToMicrobit();
            } else if (!isScanning) {
              // スキャンが進行中でないことを確認
              connectToMicrobit();
            }
          } else {
            print("現在の日付と時刻と一致しません: $recordDateTime");
          }
        }

        print(formattedRecords);

        // 実際に使う場合は formattedRecords を返したり他の処理に渡したりする
      } else {
        print('Failed to fetch records. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      await Future.delayed(Duration(minutes: 1)); // 1分ごとに処理を繰り返す
    }
  }

  Future<void> _sendEventToMicrobit() async {
    if (targetDevice == null) return;

    List<BluetoothService> services = await targetDevice!.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString() == ledServiceUUID) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write) {
            List<int> value = utf8.encode('Event Triggered');
            await characteristic.write(value);
            print("Event sent to micro:bit: $value");
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(message),
        ],
      ),
    );
  }
}
