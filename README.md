# What is this?

[こちらの記事](https://horizoon.jp/post/2021/09/05/s3_website_hosting/) で利用した動作確認用のリポジトリです。
※記事の補足のみが目的のリポジトリの為、内容不備以外でのメンテナンス予定はありません。

## Requirements

```sh
$ terraform version
Terraform v1.0.5
on darwin_amd64

$ node -v
v14.17.6
```

## Setup

```sh
# variables.tf の project を任意で設定した上で、検証環境構築
$ cd tf
$ terraform init
$ terraform plan
$ terraform apply

# package.json で aws s3 sync している処理のバケット名部分を構築したバケット名に修正した上で、
# 動作確認用アプリをS3にデプロイ
$ cd ..
$ npm i
$ npm run deploy
```
