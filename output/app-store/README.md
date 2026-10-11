# App Store ストア画像 — 日本語

2026-10-11 更新。4テーマ × 7サイズ = 28枚。全画像は縦向き、sRGB PNG、アルファチャンネルなし。

## 画像の順序

1. **01-reward-road.png** — 小さな「できた」を、ごほうびに。
2. **02-stickers.png** — 今日のがんばりに、お気に入りの一枚。
3. **03-widgets.png** — ホーム画面でも、いっしょ。
4. **04-goal-card.png** — がんばった日々を、一枚のカードに。

## 出力サイズ

| フォルダ | 寸法（px） | 対象 |
|---|---|---|
| ja/iphone-6.9 | 1320 × 2868 | iPhone 大型 Dynamic Island |
| ja/iphone-6.5 | 1284 × 2778 | iPhone 大型 Face ID |
| ja/iphone-6.3 | 1206 × 2622 | iPhone 中型 Dynamic Island |
| ja/iphone-6.1 | 1179 × 2556 | iPhone 中型 Dynamic Island 別解像度 |
| ja/ipad-13 | 2064 × 2752 | iPad 13インチ |
| ja/ipad-12.9 | 2048 × 2732 | iPad 12.9インチ／13インチ対応解像度 |
| ja/ipad-11 | 1668 × 2420 | iPad 11インチ |

フォルダ名のインチ表記は整理用です。App Store Connectの現在の表示名と必ずしも一致しません。アップロード欄が許容するピクセル寸法を優先してください。

Apple公式仕様を2026-10-10に確認：
https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications

現行仕様では中型Dynamic IslandのiPhoneと13インチiPadが必須。まず `iphone-6.3` と `ipad-13` の4枚ずつを利用してください。他のサイズは個別登録用です。全サイズを登録する必要はなく、App Store Connectは対応する小さいサイズへ自動縮小します。ホームボタン搭載機やMac/Watch/Vision用は今回のセットに含めていません。

## 素材・作成方法

- iPhone 17 Pro / iPad Pro 13-inch (M5)、iOS 26.5シミュレータで実画面を撮影。現在のソースを一時プロジェクトへコピーし、`source/CaptureApp.swift` を撮影専用エントリーポイントとして使用。本番アプリのソースやユーザーデータは変更しない。
- 撮影データは「お勉強ロード」、青・レモンの2スタンプ、2個で達成する「お気に入りのケーキ」。スタンプ選択画面は最新カタログ順。
- 4枚目はアプリの `GoalShareCardRenderer` が生成したゴールカード全体。3スタンプ・ごほうび名・達成日を欠けずに掲載。原本は `ja/raw/goal-card.png`。
- `CaptureApp` が表示中の UIWindow をPNGへ書き出し、`ja/raw` に未加工の実画面を保存。PNGのDPIに影響されないよう、レイアウト時は画像サイズをピクセル寸法に正規化する。掲載画像ではステータスバー部分をフレーム外にし、画面の縦横比を維持。iPhone系はiPhone実画面、iPad系はiPad実画面を使用。
- ウィジェット画像は `docs/widget-review/*-history.png` の既存SwiftUIレンダリングを使用。ホーム画面全体のキャプチャではなく、ウィジェット自体の紹介画像。表示件数はデモデータ。
- 紙の背景のみbuilt-in ImageGenで作成。UIと日本語見出しはAppKitで配置。UIやキャラクターの再生成はしていません。
- 3枚目は大きなウィジェット2つを見出し・説明と組にして配置。端末の縦横比に合わせて間隔を調整。
- 2026-10-11：App Store ConnectのiOS 1.0／日本語へ `iphone-6.3` と `ipad-13` の4枚ずつをアップロード済み。再読み込み後も各4枚の登録を確認。審査申請は未実施。公開ビルドでUIが変わった場合はraw素材を撮り直してください。

## 再書き出し

リポジトリのルートで：

```sh
DEVELOPER_DIR=/Applications/Xcode2650.app/Contents/Developer xcrun swift -module-cache-path /tmp/gohobi-store-render-265-v2 output/app-store/source/render.swift
```

`source/render.swift` の見出し・サイズ・レイアウトを編集して再実行できます。`source/paper-background.png` が背景原本、`source/imagegen-prompt.txt` が生成プロンプトです。

`preview.png` は確認用一覧で、アップロード用ではありません。`app-store-ja.zip` にはサイズ別の完成画像28枚とこのREADMEを収録しています。

ZIPは重複を避けるためGit管理対象外です。必要ならリポジトリのルートで再作成できます：

```sh
(cd output/app-store && zip -r app-store-ja.zip ja/iphone-* ja/ipad-* README.md manifest.json)
```
