import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> fetchAllRecords() async {
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
      if (record['完了']['value'].contains('完了')) {
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

void main() {
  fetchAllRecords();
}
