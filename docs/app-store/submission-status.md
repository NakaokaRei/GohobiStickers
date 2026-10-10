# App Store提出準備状況

更新日：2026-10-10

対象：ごほうびロード / Apple ID 6797213381 / iOS 1.0 / 日本語

## 登録済み

- iPhone用スクリーンショット3枚（1206×2622）
- iPad用スクリーンショット3枚（2064×2752）
- プロモーション用テキスト、概要、キーワード、著作権
- サブタイトル：スタンプで続ける、自分へのごほうび
- プライマリカテゴリ：ライフスタイル
- セカンダリカテゴリ：仕事効率化
- 年齢制限：4+（地域別に表示が異なる）、子ども向けカテゴリ指定なし
- 独自サインイン不要、App Review操作説明
- サポートURL：https://github.com/NakaokaRei/GohobiStickers/blob/main/docs/app-store/support.md
- プライバシーポリシーURL：https://github.com/NakaokaRei/GohobiStickers/blob/main/docs/app-store/privacy-policy.md
- 「データの収集なし」はユーザーがすでに公開済み。コード確認と整合するため維持。
- 価格：無料（全通貨で0）
- 配信地域：日本のみ。今後追加される地域への自動配信なし。
- コンテンツ配信権：第三者コンテンツなし（イラストは自作とユーザー確認済み）

## 残り

- App Review連絡先（氏名・電話・メール）：ユーザーが後で入力する指定
- アプリ内ポリシー／サポートリンクを含む配布ビルドのアップロードと選択
- CloudKitの本番スキーマ・実機同期確認（README参照）
- 審査提出。現時点で未実施。

## プライバシー判断の根拠

現在の実装は端末内保存とCloudKitのprivateCloudDatabase同期のみ。広告・追跡・解析SDKや独自収集サーバーは見当たらない。Appleの「収集」は、送信処理に必要な時間を超えて、開発者または第三者パートナーがアクセスできる形で端末外へ送信することを指す。本人のiCloud保存についてはプライバシーポリシーに明記した。

https://developer.apple.com/app-store/app-privacy-details/

新たなSDK、サーバー処理、分析機能などを追加した場合は再判定する。
