import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class TimePage extends StatefulWidget {
  @override
  _TimePageState createState() => _TimePageState();
}

class _TimePageState extends State<TimePage> {
  String currentTime = DateTime.now().toString();
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchTimeRecords();
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now().toString();
      });
    });
  }

  Future<void> fetchTimeRecords() async {
    final String apiUrl = 'https://kvt9cht6gak2.cybozu.com/k/v1/records.json';
    final String apiToken =
        'eacrQLrVRaSeFYkafsZr2NjthyqnyGZGAFBEHW3n'; // あなたのAPIトークンを設定する

    final Map<String, String> headers = {
      'X-Cybozu-API-Token': apiToken,
    };

    // GETリクエストのURL構築
    final String url = '$apiUrl?app=16';

    final http.Response response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      List<dynamic> records = data['records']; // レコードのリストを取得

      //レコードごとに処理する例を示すためのコメントアウト
      List<int> formattedRecords = [];
      for (var record in records) {
        if (record['時刻']['value'].contains('13:50')) {
          formattedRecords.add(int.parse(record['レコード番号']['value']));
          print("通りました");
        } else {
          print("完了ではありません");
        }
      }

      print(formattedRecords);
      // 実際に使う場合は formattedRecords を返したり他の処理に渡したりする

      await deleteRecords(formattedRecords, apiToken);
    } else {
      print('Failed to fetch records. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  Future<void> deleteRecords(List<int> recordIds, String apiToken) async {
    String apiUrl = 'https://kvt9cht6gak2.cybozu.com/k/v1/records.json';

    print(recordIds);

    Map<String, dynamic> body = {
      "app": 16, // 実際のアプリIDに置き換えてください
      "ids": recordIds, // 削除したいレコードIDのリスト
    };

    Map<String, String> headers = {
      "X-Cybozu-API-Token": apiToken,
      "Content-Type": "application/json"
    };

    try {
      var response = await http.delete(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('レコードを削除しました。');
      } else {
        print('リクエストが失敗しました。ステータスコード: ${response.statusCode}');
        print('レスポンスボディ: ${response.body}');
      }
    } catch (e) {
      print('レコードの削除中にエラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Time Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              '現在の時間: $currentTime',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            if (isLoading) CircularProgressIndicator(),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            if (!isLoading && errorMessage == null)
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('レコード番号: ${records[index]['レコード番号']}'),
                      subtitle: Text('時刻: ${records[index]['時刻']}'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: TimePage(),
  ));
}
