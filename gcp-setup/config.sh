#!/bin/bash

# GCP フルスタック セットアップ - 設定ファイル

# 設定変数
PROJECT_ID="project-$(date +%Y%m%d%H%M)"
PROJECT_NAME="My Fullstack Project"
REPOSITORY_NAME="my-app-repo"
LOCATION="asia-northeast1"
REPOSITORY_FORMAT="docker"
DESCRIPTION="My application repository"
BILLING_ACCOUNT_ID=""

# アプリケーション設定
IMAGE_NAME="my-app"
DOCKERFILE_PATH="./docker_gcp/Dockerfile_gcp"
SERVICE_NAME="my-app-service"
CLOUD_RUN_REGION="asia-northeast1"

# Cloud SQL設定（MySQL用に変更）
SQL_INSTANCE_NAME="my-sql-instance"
SQL_DATABASE_NAME="my_database"
SQL_USER="app_user"
SQL_PASSWORD="$(openssl rand -base64 16 | tr -d '+=/' | head -c 16)"
SQL_TIER="db-f1-micro"
SQL_REGION="asia-northeast1"

# SQLファイル設定
SQL_FILE_PATH="./src/DB.sql"

# 色付きの出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
