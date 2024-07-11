import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart'; // Import the main.dart to access MyHomePage

Future<void> fetchAllRecords(BuildContext context) async {
  final String apiUrl = 'https://kvt9cht6gak2.cybozu.com/k/v1/records.json';
  final String apiToken = 'eacrQLrVRaSeFYkafsZr2NjthyqnyGZGAFBEHW3n';

  final Map<String, String> headers = {
    'X-Cybozu-API-Token': apiToken,
  };

  final String url = '$apiUrl?app=16';

  final http.Response response = await http.get(
    Uri.parse(url),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);

    List<dynamic> records = data['records'];
    List<int> formattedRecords = [];
    for (var record in records) {
      if (record['完了']['value'].contains('完了')) {
        formattedRecords.add(int.parse(record['レコード番号']['value']));
        print("通りました");
      } else {
        print("完了ではありません");
      }
    }

    print(formattedRecords);

    showDeleteConfirmationDialog(context, formattedRecords, apiToken);
  } else {
    print('Failed to fetch records. Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
  }
}

Future<void> deleteRecords(
    BuildContext context, List<int> recordIds, String apiToken) async {
  String apiUrl = 'https://kvt9cht6gak2.cybozu.com/k/v1/records.json';

  Map<String, dynamic> body = {
    "app": 16,
    "ids": recordIds,
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
      showMessageDialog(context, 'レコードを削除しました。');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => MyHomePage(title: 'がんばればできる'),
        ),
      );
    } else {
      showMessageDialog(
          context, 'リクエストが失敗しました。ステータスコード: ${response.statusCode}');
    }
  } catch (e) {
    showMessageDialog(context, 'レコードの削除中にエラーが発生しました: $e');
  }
}

void showMessageDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void showDeleteConfirmationDialog(
    BuildContext context, List<int> recordIds, String apiToken) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('確認'),
        content: Text('本当に削除してもよろしいですか？'),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('削除'),
            onPressed: () {
              Navigator.of(context).pop();
              deleteRecords(context, recordIds, apiToken);
            },
          ),
        ],
      );
    },
  );
}
