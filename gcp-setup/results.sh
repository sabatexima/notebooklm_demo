#!/bin/bash

# GCP フルスタック セットアップ - 結果表示

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
DOCKERFILE_PATH="$DOCKERFILE_PATH"
SQL_FILE_PATH="$SQL_FILE_PATH"
EOF
    
    log_success "認証情報を保存しました: $creds_file"
}