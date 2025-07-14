#!/bin/bash

# GCP フルスタック セットアップスクリプト
# 使用方法: bash ./start.sh

set -e  # エラーが発生した場合にスクリプトを停止

# 設定変数
PROJECT_ID="project-$(date +%Y%m%d%H%M)"
PROJECT_NAME="My Docker Project"
REPOSITORY_NAME="my-docker-repo"
LOCATION="asia-northeast1"
REPOSITORY_FORMAT="docker"
DESCRIPTION="My Docker repository"
BILLING_ACCOUNT_ID="019B70-7E6EAD-7BF631"

# アプリケーション設定
IMAGE_NAME="my-app"
DOCKERFILE_PATH="./docker_gcp/Dockerfile_gcp"
SERVICE_NAME="my-app-service"
CLOUD_RUN_REGION="asia-northeast1"

# Cloud SQL設定
SQL_INSTANCE_NAME="my-sql-instance"
SQL_DATABASE_NAME="my_database"
SQL_USER="app_user"
SQL_PASSWORD="$(openssl rand -base64 32)"  # ランダムパスワード生成
SQL_TIER="db-f1-micro"  # 開発用の小さなインスタンス
SQL_REGION="asia-northeast1"

# 色付きの出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ出力関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 前提条件チェック
check_prerequisites() {
    log_info "前提条件をチェック中..."
    
    # gcloud コマンドの存在確認
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud コマンドが見つかりません。"
        exit 1
    fi
    
    # Docker コマンドの存在確認
    if ! command -v docker &> /dev/null; then
        log_error "docker コマンドが見つかりません。"
        exit 1
    fi
    
    # Dockerfileの存在確認
    if [ ! -f "$DOCKERFILE_PATH" ]; then
        log_warning "Dockerfile ($DOCKERFILE_PATH) が見つかりません。"
        echo "サンプルDockerfileを作成しますか？ (y/n)"
        read -r response
        if [ "$response" = "y" ]; then
            create_sample_dockerfile
        else
            log_error "Dockerfileが必要です。"
            exit 1
        fi
    fi
    
    # gcloud認証の確認
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "gcloud認証が必要です。以下のコマンドを実行してください:"
        echo "  gcloud auth login"
        exit 1
    fi
    
    log_success "前提条件チェック完了"
}

# サンプルDockerfile作成
create_sample_dockerfile() {
    log_info "サンプルDockerfile作成中..."
    
    cat > "$DOCKERFILE_PATH" << 'EOF'
FROM node:16-alpine

WORKDIR /app

# package.jsonがある場合のサンプル
# COPY package*.json ./
# RUN npm install

# アプリケーションコードをコピー
COPY . .

# ポート8080でリッスン（Cloud Runのデフォルト）
EXPOSE 8080

# 簡単なHTTPサーバー
RUN echo 'const http = require("http"); const server = http.createServer((req, res) => { res.writeHead(200, {"Content-Type": "text/plain"}); res.end("Hello from Cloud Run!"); }); server.listen(8080, () => { console.log("Server running on port 8080"); });' > server.js

CMD ["node", "server.js"]
EOF
    
    log_success "サンプルDockerfileを作成しました: $DOCKERFILE_PATH"
}

# 課金アカウント設定
setup_billing() {
    log_info "課金アカウント設定中..."
    
    local billing_accounts=$(gcloud billing accounts list --format="value(name,displayName)" --filter="open:true")
    
    if [ -z "$billing_accounts" ]; then
        log_error "利用可能な課金アカウントが見つかりません。"
        exit 1
    fi
    
    if [ -z "$BILLING_ACCOUNT_ID" ]; then
        echo "利用可能な課金アカウント:"
        echo "$billing_accounts" | nl -w2 -s'. '
        echo ""
        
        read -p "課金アカウントを選択してください (番号): " selection
        BILLING_ACCOUNT_ID=$(echo "$billing_accounts" | sed -n "${selection}p" | cut -d$'\t' -f1)
        
        if [ -z "$BILLING_ACCOUNT_ID" ]; then
            log_error "無効な選択です。"
            exit 1
        fi
    fi
    
    log_info "選択された課金アカウント: $BILLING_ACCOUNT_ID"
}

# プロジェクト作成
create_project() {
    log_info "プロジェクト作成中: $PROJECT_ID"
    
    if gcloud projects describe $PROJECT_ID &> /dev/null; then
        log_warning "プロジェクト $PROJECT_ID は既に存在します"
    else
        gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"
        log_success "プロジェクト $PROJECT_ID を作成しました"
    fi
}

# プロジェクト設定
set_project() {
    log_info "プロジェクト設定中: $PROJECT_ID"
    gcloud config set project $PROJECT_ID
    log_success "アクティブプロジェクトを設定しました"
}

# 課金アカウントをプロジェクトに紐付け
link_billing() {
    log_info "課金アカウントをプロジェクトに紐付け中..."
    
    local current_billing=$(gcloud billing projects describe $PROJECT_ID --format="value(billingAccountName)" 2>/dev/null || echo "")
    
    if [ -n "$current_billing" ]; then
        log_warning "課金アカウントは既に設定されています"
    else
        gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID
        log_success "課金アカウントを紐付けました"
    fi
}

# API有効化
enable_apis() {
    log_info "必要なAPIを有効化中..."
    
    local apis=(
        "artifactregistry.googleapis.com"
        "cloudbuild.googleapis.com"
        "run.googleapis.com"
        "sql-component.googleapis.com"
        "sqladmin.googleapis.com"
        "compute.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        gcloud services enable "$api"
        log_success "$api を有効化しました"
    done
    
    log_info "API有効化の完了を待機中..."
    sleep 30
}

# Artifact Registry リポジトリ作成
create_repository() {
    log_info "Artifact Registry リポジトリ作成中: $REPOSITORY_NAME"
    
    if gcloud artifacts repositories describe $REPOSITORY_NAME --location=$LOCATION &> /dev/null; then
        log_warning "リポジトリ $REPOSITORY_NAME は既に存在します"
    else
        gcloud artifacts repositories create $REPOSITORY_NAME \
            --repository-format=$REPOSITORY_FORMAT \
            --location=$LOCATION \
            --description="$DESCRIPTION"
        log_success "リポジトリ $REPOSITORY_NAME を作成しました"
    fi
}

# Docker認証設定
setup_docker_auth() {
    log_info "Docker認証設定中..."
    
    gcloud auth configure-docker ${LOCATION}-docker.pkg.dev --quiet
    log_success "Docker認証を設定しました"
}

# Dockerイメージのビルドとプッシュ
build_and_push_image() {
    log_info "Dockerイメージのビルドとプッシュ中..."
    
    local image_uri="${LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/${IMAGE_NAME}:latest"
    
    # イメージビルド
    log_info "Dockerイメージをビルド中..."
    docker build ./ -t "$image_uri" -f "$DOCKERFILE_PATH"
    log_success "Dockerイメージをビルドしました"
    
    # イメージプッシュ
    log_info "Dockerイメージをプッシュ中..."
    docker push "$image_uri"
    log_success "Dockerイメージをプッシュしました: $image_uri"
    
    # グローバル変数に保存
    IMAGE_URI="$image_uri"
}

# Cloud SQL インスタンス作成
create_cloud_sql() {
    log_info "Cloud SQL インスタンス作成中: $SQL_INSTANCE_NAME"
    
    # インスタンスの存在確認
    if gcloud sql instances describe $SQL_INSTANCE_NAME &> /dev/null; then
        log_warning "Cloud SQL インスタンス $SQL_INSTANCE_NAME は既に存在します"
    else
        gcloud sql instances create $SQL_INSTANCE_NAME \
            --database-version=POSTGRES_13 \
            --tier=$SQL_TIER \
            --region=$SQL_REGION \
            --root-password="$SQL_PASSWORD"
        log_success "Cloud SQL インスタンスを作成しました"
    fi
    
    # データベース作成
    log_info "データベース作成中: $SQL_DATABASE_NAME"
    if ! gcloud sql databases describe $SQL_DATABASE_NAME --instance=$SQL_INSTANCE_NAME &> /dev/null; then
        gcloud sql databases create $SQL_DATABASE_NAME --instance=$SQL_INSTANCE_NAME
        log_success "データベースを作成しました"
    fi
    
    # ユーザー作成
    log_info "ユーザー作成中: $SQL_USER"
    if ! gcloud sql users describe $SQL_USER --instance=$SQL_INSTANCE_NAME &> /dev/null; then
        gcloud sql users create $SQL_USER \
            --instance=$SQL_INSTANCE_NAME \
            --password="$SQL_PASSWORD"
        log_success "ユーザーを作成しました"
    fi
}

# Cloud Run サービスデプロイ
deploy_to_cloud_run() {
    log_info "Cloud Run サービスデプロイ中: $SERVICE_NAME"
    
    # Cloud SQL接続用の環境変数を設定
    local connection_name="${PROJECT_ID}:${SQL_REGION}:${SQL_INSTANCE_NAME}"
    
    gcloud run deploy $SERVICE_NAME \
        --image="$IMAGE_URI" \
        --platform=managed \
        --region=$CLOUD_RUN_REGION \
        --allow-unauthenticated \
        --set-env-vars="DB_HOST=/cloudsql/$connection_name,DB_NAME=$SQL_DATABASE_NAME,DB_USER=$SQL_USER,DB_PASSWORD=$SQL_PASSWORD" \
        --add-cloudsql-instances="$connection_name" \
        --port=8080 \
        --memory=512Mi \
        --cpu=1
    
    log_success "Cloud Run サービスをデプロイしました"
    
    # サービスURLを取得
    local service_url=$(gcloud run services describe $SERVICE_NAME --region=$CLOUD_RUN_REGION --format="value(status.url)")
    log_success "サービスURL: $service_url"
    
    # グローバル変数に保存
    SERVICE_URL="$service_url"
}

# Cloud SQL接続テスト
test_sql_connection() {
    log_info "Cloud SQL接続テスト中..."
    
    # Cloud SQL Proxyを使用した接続テスト
    log_info "Cloud SQL Proxyをダウンロード中..."
    
    # Cloud SQL Proxyのダウンロード（Linux x86_64用）
    if [ ! -f "./cloud_sql_proxy" ]; then
        curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64
        chmod +x cloud_sql_proxy
    fi
    
    local connection_name="${PROJECT_ID}:${SQL_REGION}:${SQL_INSTANCE_NAME}"
    
    log_info "Cloud SQL接続情報:"
    echo "  インスタンス名: $SQL_INSTANCE_NAME"
    echo "  データベース名: $SQL_DATABASE_NAME"
    echo "  ユーザー名: $SQL_USER"
    echo "  パスワード: $SQL_PASSWORD"
    echo "  接続名: $connection_name"
    echo ""
    echo "Cloud SQL Proxyを使用した接続方法:"
    echo "  1. 別のターミナルで以下を実行:"
    echo "     ./cloud_sql_proxy -instances=$connection_name=tcp:5432"
    echo "  2. 別のターミナルで以下を実行:"
    echo "     psql -h 127.0.0.1 -p 5432 -U $SQL_USER -d $SQL_DATABASE_NAME"
    echo "     パスワード: $SQL_PASSWORD"
    echo ""
    echo "または、gcloud sql connectを使用:"
    echo "  gcloud sql connect $SQL_INSTANCE_NAME --user=$SQL_USER --database=$SQL_DATABASE_NAME"
}

# 最終結果表示
show_final_results() {
    echo ""
    echo "==========================================="
    log_success "フルスタックセットアップ完了！"
    echo "==========================================="
    echo ""
    echo "📋 セットアップ結果:"
    echo "  プロジェクト ID: $PROJECT_ID"
    echo "  リポジトリ名: $REPOSITORY_NAME"
    echo "  イメージ URI: $IMAGE_URI"
    echo "  Cloud Run サービス: $SERVICE_NAME"
    echo "  サービス URL: $SERVICE_URL"
    echo "  Cloud SQL インスタンス: $SQL_INSTANCE_NAME"
    echo ""
    echo "🐳 Docker関連:"
    echo "  リポジトリ: ${LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}"
    echo "  イメージ: $IMAGE_NAME:latest"
    echo ""
    echo "🗄️ データベース関連:"
    echo "  インスタンス: $SQL_INSTANCE_NAME"
    echo "  データベース: $SQL_DATABASE_NAME"
    echo "  ユーザー: $SQL_USER"
    echo "  パスワード: $SQL_PASSWORD"
    echo ""
    echo "🔧 便利なコマンド:"
    echo "  # Cloud Run ログ確認"
    echo "  gcloud run services logs read $SERVICE_NAME --region=$CLOUD_RUN_REGION"
    echo ""
    echo "  # Cloud SQL接続"
    echo "  gcloud sql connect $SQL_INSTANCE_NAME --user=$SQL_USER --database=$SQL_DATABASE_NAME"
    echo ""
    echo "  # 新しいイメージデプロイ"
    echo "  docker build ./ -t ${IMAGE_URI} -f $DOCKERFILE_PATH"
    echo "  docker push ${IMAGE_URI}"
    echo "  gcloud run deploy $SERVICE_NAME --image=${IMAGE_URI} --region=$CLOUD_RUN_REGION"
    echo ""
    echo "🌐 アプリケーションアクセス:"
    echo "  $SERVICE_URL"
    echo ""
}

# 認証情報をファイルに保存
save_credentials() {
    local creds_file="gcp_credentials_${PROJECT_ID}.txt"
    
    cat > "$creds_file" << EOF
# GCP プロジェクト認証情報
# 生成日時: $(date)

PROJECT_ID="$PROJECT_ID"
REPOSITORY_NAME="$REPOSITORY_NAME"
IMAGE_URI="$IMAGE_URI"
SERVICE_NAME="$SERVICE_NAME"
SERVICE_URL="$SERVICE_URL"
SQL_INSTANCE_NAME="$SQL_INSTANCE_NAME"
SQL_DATABASE_NAME="$SQL_DATABASE_NAME"
SQL_USER="$SQL_USER"
SQL_PASSWORD="$SQL_PASSWORD"

# 接続コマンド
# Cloud SQL接続:
gcloud sql connect $SQL_INSTANCE_NAME --user=$SQL_USER --database=$SQL_DATABASE_NAME

# Cloud Run ログ:
gcloud run services logs read $SERVICE_NAME --region=$CLOUD_RUN_REGION

# 新しいイメージのデプロイ:
docker build ./ -t ${IMAGE_URI} -f $DOCKERFILE_PATH
docker push ${IMAGE_URI}
gcloud run deploy $SERVICE_NAME --image=${IMAGE_URI} --region=$CLOUD_RUN_REGION
EOF
    
    log_success "認証情報を保存しました: $creds_file"
}

# クリーンアップ関数
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_warning "エラーが発生しました（終了コード: $exit_code）"
        echo ""
        echo "デバッグ情報:"
        echo "  プロジェクト: $(gcloud config get-value project 2>/dev/null)"
        echo "  アカウント: $(gcloud config get-value account 2>/dev/null)"
        echo ""
        echo "手動実行コマンド:"
        echo "  gcloud projects delete $PROJECT_ID  # プロジェクト削除"
    fi
}

# メイン処理
main() {
    echo "==========================================="
    echo "🚀 GCP フルスタック セットアップスクリプト"
    echo "==========================================="
    echo ""
    echo "このスクリプトは以下を実行します:"
    echo "  1. ✅ プロジェクト作成"
    echo "  2. ✅ Artifact Registry リポジトリ作成"
    echo "  3. 🐳 Docker認証設定"
    echo "  4. 🐳 Dockerイメージビルド・プッシュ"
    echo "  5. ☁️ Cloud Run デプロイ"
    echo "  6. 🗄️ Cloud SQL インスタンス作成"
    echo "  7. 🔗 Cloud SQL接続テスト"
    echo ""
    
    # トラップでクリーンアップ関数を設定
    trap cleanup EXIT
    
    # 各処理を実行
    check_prerequisites
    setup_billing
    create_project
    set_project
    link_billing
    enable_apis
    create_repository
    setup_docker_auth
    build_and_push_image
    create_cloud_sql
    deploy_to_cloud_run
    test_sql_connection
    show_final_results
    save_credentials
    
    log_success "🎉 すべての処理が完了しました！"
}

# ヘルプ表示
show_help() {
    echo "使用方法: $0 [OPTIONS]"
    echo ""
    echo "オプション:"
    echo "  -h, --help              このヘルプを表示"
    echo "  -p, --project PROJECT   プロジェクトIDを指定"
    echo "  -n, --name NAME         リポジトリ名を指定"
    echo "  -s, --service SERVICE   Cloud Runサービス名を指定"
    echo "  -i, --image IMAGE       イメージ名を指定"
    echo "  -f, --dockerfile FILE   Dockerfileパスを指定"
    echo "  -b, --billing BILLING   課金アカウントIDを指定"
    echo ""
    echo "例:"
    echo "  $0"
    echo "  $0 -p my-project -n my-repo -s my-service"
    echo "  $0 -f Dockerfile.prod -i my-custom-app"
    echo ""
}

# コマンドライン引数の処理
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        -n|--name)
            REPOSITORY_NAME="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE_NAME="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -f|--dockerfile)
            DOCKERFILE_PATH="$2"
            shift 2
            ;;
        -b|--billing)
            BILLING_ACCOUNT_ID="$2"
            shift 2
            ;;
        *)
            log_error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# メイン処理実行
main
