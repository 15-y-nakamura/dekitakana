# dekitakana

flutterで作成したモバイルアプリからやることと期限を設定し、
期限になると、micro:bitを使用したレゴブロックが暴れます。

## ライブラリのインストール
モバイルアプリからkintone APIをたたくので、httpリクエストを実行するためのパッケージhttpをインストールします。
VSCodeのコマンドラインで以下のコマンドを実行します。

`flutter pub add http`

また、kintoneのAPIトークンを秘匿するためのライブラリ「flutter_secure_storage」もインストールします。

`flutter pub add flutter_secure_storage`
