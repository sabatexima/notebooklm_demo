#!/bin/bash

# GCP フルスタック セットアップスクリプト（PROJECT_ID・課金設定修正版）
# 使用方法: ./setup-gcp-fullstack-modified.sh

set -e  # エラーが発生した場合にスクリプトを停止

# 設定変数
PROJECT_ID="project-$(date +%Y%m%d%H%M)"
PROJECT_NAME="NoteLM-$(date +%Y%m%d%H%M)"
REPOSITORY_NAME="my-app-repo"
LOCATION="asia-northeast1"
REPOSITORY_FORMAT="docker"
DESCRIPTION="My application repository"
BILLING_ACCOUNT_ID=""  # 実行時に必ず入力を求める

# アプリケーション設定
IMAGE_NAME="my-app"
DOCKERFILE_PATH="./docker_gcp/Dockerfile_gcp"
SERVICE_NAME="my-app-service"
CLOUD_RUN_REGION="asia-northeast1"

# Cloud SQL設定
SQL_INSTANCE_NAME="my-sql-instance"
SQL_DATABASE_NAME="my_database"
SQL_USER="app_user"
SQL_PASSWORD="$(openssl rand -base64 32)"
SQL_TIER="db-f1-micro"
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

# Docker設定チェック
check_docker_setup() {
    log_info "Docker設定をチェック中..."
    
    # Dockerコマンドの存在確認
    if ! command -v docker &> /dev/null; then
        log_error "Dockerコマンドが見つかりません。"
        echo ""
        echo "🐳 Docker設定方法:"
        echo "1. Docker Desktop for Windows を使用する場合:"
        echo "   - Docker Desktop を起動"
        echo "   - Settings > Resources > WSL Integration を開く"
        echo "   - 'Enable integration with my default WSL distro' をチェック"
        echo "   - 使用しているWSL2ディストリビューションをチェック"
        echo "   - Apply & Restart をクリック"
        echo ""
        echo "2. WSL2内に直接Dockerをインストールする場合:"
        echo "   curl -fsSL https://get.docker.com | sh"
        echo "   sudo usermod -aG docker \$USER"
        echo "   newgrp docker"
        echo ""
        echo "設定完了後、再度このスクリプトを実行してください。"
        exit 1
    fi
    
    # Docker デーモンの確認
    if ! docker info &> /dev/null; then
        log_error "Docker デーモンが起動していません。"
        echo ""
        echo "🔧 Docker デーモンの起動方法:"
        echo "1. Docker Desktop を使用している場合:"
        echo "   - Docker Desktop を起動してください"
        echo ""
        echo "2. WSL2内でDockerサービスを使用している場合:"
        echo "   sudo service docker start"
        echo ""
        echo "3. systemd を使用している場合:"
        echo "   sudo systemctl start docker"
        echo ""
        read -p "Docker Desktop を起動しましたか？ (y/n): " docker_ready
        if [ "$docker_ready" != "y" ]; then
            exit 1
        fi
        
        # 再度チェック
        if ! docker info &> /dev/null; then
            log_error "Docker デーモンにアクセスできません。"
            exit 1
        fi
    fi
    
    # Docker権限の確認
    if ! docker ps &> /dev/null; then
        log_error "Docker権限がありません。"
        echo ""
        echo "🔐 Docker権限の設定:"
        echo "sudo usermod -aG docker \$USER"
        echo "newgrp docker"
        echo ""
        echo "または、一時的にsudoを使用:"
        echo "sudo docker ..."
        echo ""
        read -p "sudoを使用してDockerを実行しますか？ (y/n): " use_sudo
        if [ "$use_sudo" = "y" ]; then
            DOCKER_CMD="sudo docker"
        else
            exit 1
        fi
    else
        DOCKER_CMD="docker"
    fi
    
    log_success "Docker設定チェック完了"
    echo "Docker version: $(docker --version)"
}

# 前提条件チェック
check_prerequisites() {
    log_info "前提条件をチェック中..."
    
    # gcloud コマンドの存在確認
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud コマンドが見つかりません。"
        exit 1
    fi
    
    # Docker設定チェック
    check_docker_setup
    
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

# 簡単なHTTPサーバーを作成
RUN echo 'const http = require("http"); \
const server = http.createServer((req, res) => { \
  res.writeHead(200, {"Content-Type": "application/json"}); \
  res.end(JSON.stringify({ \
    message: "Hello from Cloud Run!", \
    timestamp: new Date().toISOString(), \
    environment: process.env.NODE_ENV || "development", \
    project: process.env.PROJECT_ID || "unknown" \
  })); \
}); \
const port = process.env.PORT || 8080; \
server.listen(port, () => { \
  console.log(`Server running on port ${port}`); \
});' > server.js

# ポート8080でリッスン（Cloud Runのデフォルト）
EXPOSE 8080

CMD ["node", "server.js"]
EOF
    
    log_success "サンプルDockerfileを作成しました: $DOCKERFILE_PATH"
}

# 課金アカウント設定（必須入力版）
setup_billing() {
    log_info "課金アカウント設定中..."
    
    # 課金アカウント一覧を取得
    local billing_accounts=$(gcloud billing accounts list --format="value(name,displayName)" --filter="open:true")
    
    if [ -z "$billing_accounts" ]; then
        log_error "利用可能な課金アカウントが見つかりません。"
        echo ""
        echo "🔧 課金アカウントの作成方法:"
        echo "1. Google Cloud Console にアクセス: https://console.cloud.google.com/billing"
        echo "2. 課金アカウントを作成"
        echo "3. 支払い方法を設定"
        echo ""
        echo "課金アカウント作成後、再度このスクリプトを実行してください。"
        exit 1
    fi
    
    # 課金アカウントが未指定の場合、必ず選択を求める
    if [ -z "$BILLING_ACCOUNT_ID" ]; then
        echo ""
        echo "==========================================="
        echo "🏦 課金アカウントの選択"
        echo "==========================================="
        echo ""
        echo "利用可能な課金アカウント:"
        echo "$billing_accounts" | nl -w2 -s'. ' | while read line; do
            echo "  $line"
        done
        echo ""
        
        while true; do
            read -p "課金アカウントを選択してください (番号を入力): " selection
            
            # 入力が数値かチェック
            if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
                echo "❌ 数値を入力してください"
                continue
            fi
            
            # 選択された課金アカウントを取得
            BILLING_ACCOUNT_ID=$(echo "$billing_accounts" | sed -n "${selection}p" | cut -d$'\t' -f1)
            
            if [ -z "$BILLING_ACCOUNT_ID" ]; then
                echo "❌ 無効な選択です。1-$(echo "$billing_accounts" | wc -l) の範囲で入力してください"
                continue
            fi
            
            # 選択された課金アカウントの表示名を取得
            local display_name=$(echo "$billing_accounts" | sed -n "${selection}p" | cut -d$'\t' -f2)
            
            echo ""
            echo "選択された課金アカウント:"
            echo "  ID: $BILLING_ACCOUNT_ID"
            echo "  名前: $display_name"
            echo ""
            read -p "この課金アカウントを使用しますか？ (y/n): " confirm
            
            if [ "$confirm" = "y" ]; then
                break
            else
                BILLING_ACCOUNT_ID=""
                continue
            fi
        done
    fi
    
    log_success "課金アカウントを設定しました: $BILLING_ACCOUNT_ID"
}

# プロジェクト作成
create_project() {
    log_info "プロジェクト作成中: $PROJECT_ID"
    
    # プロジェクトの存在確認
    if gcloud projects describe $PROJECT_ID &> /dev/null; then
        log_warning "プロジェクト $PROJECT_ID は既に存在します"
        echo ""
        read -p "既存のプロジェクトを使用しますか？ (y/n): " use_existing
        if [ "$use_existing" != "y" ]; then
            # 新しいプロジェクトIDを生成
            PROJECT_ID="project-$(date +%Y%m%d%H%M)-$(openssl rand -hex 3)"
            log_info "新しいプロジェクトIDを生成しました: $PROJECT_ID"
            gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"
            log_success "プロジェクト $PROJECT_ID を作成しました"
        fi
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
    
    # 既に課金アカウントが設定されているかチェック
    local current_billing=$(gcloud billing projects describe $PROJECT_ID --format="value(billingAccountName)" 2>/dev/null || echo "")
    
    if [ -n "$current_billing" ]; then
        log_warning "課金アカウントは既に設定されています: $current_billing"
        
        # 異なる課金アカウントが設定されている場合
        if [ "$current_billing" != "billingAccounts/$BILLING_ACCOUNT_ID" ]; then
            echo ""
            echo "現在の課金アカウント: $current_billing"
            echo "選択した課金アカウント: billingAccounts/$BILLING_ACCOUNT_ID"
            echo ""
            read -p "課金アカウントを変更しますか？ (y/n): " change_billing
            if [ "$change_billing" = "y" ]; then
                gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID
                log_success "課金アカウントを変更しました"
            fi
        fi
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
        log_info "API有効化中: $api"
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
    
    if gcloud auth configure-docker ${LOCATION}-docker.pkg.dev --quiet; then
        log_success "Docker認証を設定しました"
    else
        log_error "Docker認証の設定に失敗しました"
        echo ""
        echo "🔐 手動でDocker認証を設定:"
        echo "gcloud auth configure-docker ${LOCATION}-docker.pkg.dev"
        exit 1
    fi
}

# Dockerイメージのビルドとプッシュ
build_and_push_image() {
    log_info "Dockerイメージのビルドとプッシュ中..."
    
    local image_uri="${LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/${IMAGE_NAME}:latest"
    
    # イメージビルド
    log_info "Dockerイメージをビルド中..."
    echo "実行コマンド: ${DOCKER_CMD} build ./ -t \"$image_uri\" -f \"$DOCKERFILE_PATH\""
    
    if ${DOCKER_CMD} build ./ -t "$image_uri" -f "$DOCKERFILE_PATH"; then
        log_success "Dockerイメージをビルドしました"
    else
        log_error "Dockerイメージのビルドに失敗しました"
        exit 1
    fi
    
    # イメージプッシュ
    log_info "Dockerイメージをプッシュ中..."
    echo "実行コマンド: ${DOCKER_CMD} push \"$image_uri\""
    
    if ${DOCKER_CMD} push "$image_uri"; then
        log_success "Dockerイメージをプッシュしました: $image_uri"
    else
        log_error "Dockerイメージのプッシュに失敗しました"
        exit 1
    fi
    
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
        --set-env-vars="PROJECT_ID=$PROJECT_ID,DB_HOST=/cloudsql/$connection_name,DB_NAME=$SQL_DATABASE_NAME,DB_USER=$SQL_USER,DB_PASSWORD=$SQL_PASSWORD" \
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
    echo "  プロジェクト: $PROJECT_ID"
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
    log_success "🎉 フルスタックセットアップ完了！"
    echo "==========================================="
    echo ""
    echo "📋 セットアップ結果:"
    echo "  プロジェクト ID: $PROJECT_ID"
    echo "  課金アカウント: $BILLING_ACCOUNT_ID"
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
    echo "  ${DOCKER_CMD} build ./ -t ${IMAGE_URI} -f $DOCKERFILE_PATH"
    echo "  ${DOCKER_CMD} push ${IMAGE_URI}"
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
BILLING_ACCOUNT_ID="$BILLING_ACCOUNT_ID"
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
${DOCKER_CMD} build ./ -t ${IMAGE_URI} -f $DOCKERFILE_PATH
${DOCKER_CMD} push ${IMAGE_URI}
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
        echo "  プロジェクト: $PROJECT_ID"
        echo "  課金アカウント: $BILLING_ACCOUNT_ID"
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
    echo "📅 生成されるプロジェクトID: $PROJECT_ID"
    echo ""
    echo "このスクリプトは以下を実行します:"
    echo "  1. ✅ 課金アカウント選択"
    echo "  2. ✅ プロジェクト作成"
    echo "  3. ✅ Artifact Registry リポジトリ作成"
    echo "  4. 🐳 Docker認証設定"
    echo "  5. 🐳 Dockerイメージビルド・プッシュ"
    echo "  6. ☁️ Cloud Run デプロイ"
    echo "  7. 🗄️ Cloud SQL インスタンス作成"
    echo "  8. 🔗 Cloud SQL接続テスト"
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
    echo "  -p, --project PROJECT   プロジェクトIDを指定（デフォルト: project-YYYYMMddHHMM）"
    echo "  -n, --name NAME         リポジトリ名を指定"
    echo "  -s, --service SERVICE   Cloud Runサービス名を指定"
    echo "  -i, --image IMAGE       イメージ名を指定"
    echo "  -f, --dockerfile FILE   Dockerfileパスを指定"
    echo ""
    echo "例:"
    echo "  $0                                    # 対話式で実行"
    echo "  $0 -p my-project-202501             # プロジェクトIDを指定"
    echo "  $0 -n my-repo -s my-service         # リポジトリ・サービス名を指定"
    echo "  $0 -f Dockerfile.prod -i my-app     # Dockerfile・イメージ名を指定"
    echo ""
    echo "注意:"
    echo "  - 課金アカウントは実行時に必ず選択が必要です"
    echo "  - プロジェクトIDは自動生成されますが、-pオプションで上書き可能です"
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
        *)
            log_error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# メイン処理実行
main
