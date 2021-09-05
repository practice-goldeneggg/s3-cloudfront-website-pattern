# What is this?

[こちらの記事](TODO) で利用した成果物リポジトリ

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
# 検証環境構築
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
