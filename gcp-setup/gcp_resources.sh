#!/bin/bash

# GCP フルスタック セットアップ - GCPリソース管理

# 課金アカウント設定
setup_billing() {
    log_info "課金アカウント設定中..."
    
    local billing_accounts=$(gcloud billing accounts list --format="value(name,displayName)" --filter="open:true")
    
    if [ -z "$billing_accounts" ]; then
        log_error "利用可能な課金アカウントが見つかりません。"
        echo "Google Cloud Console で課金アカウントを作成してください。"
        exit 1
    fi
    
    if [ -z "$BILLING_ACCOUNT_ID" ]; then
        echo ""
        echo "==========================================="
        echo "🏦 課金アカウントの選択"
        echo "==========================================="
        echo ""
        echo "利用可能な課金アカウント:"
        echo "$billing_accounts" | nl -w2 -s'. '
        echo ""
        
        while true; do
            read -p "課金アカウントを選択してください (番号を入力): " selection
            
            if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
                echo "❌ 数値を入力してください"
                continue
            fi
            
            BILLING_ACCOUNT_ID=$(echo "$billing_accounts" | sed -n "${selection}p" | cut -d$'\t' -f1)
            
            if [ -z "$BILLING_ACCOUNT_ID" ]; then
                echo "❌ 無効な選択です。1-$(echo "$billing_accounts" | wc -l) の範囲で入力してください"
                continue
            fi
            
            local display_name=$(echo "$billing_accounts" | sed -n "${selection}p" | cut -d$'\t' -f2)
            echo ""
            echo "選択された課金アカウント: ID: $BILLING_ACCOUNT_ID, 名前: $display_name"
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
    
    if gcloud projects describe $PROJECT_ID &> /dev/null; then
        log_warning "プロジェクト $PROJECT_ID は既に存在します"
        read -p "既存のプロジェクトを使用しますか？ (y/n): " use_existing
        if [ "$use_existing" != "y" ]; then
            PROJECT_ID="project-$(date +%Y%m%d%H%M)-$(openssl rand -hex 3)"
            log_info "新しいプロジェクトIDを生成しました: $PROJECT_ID"
            gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"
        fi
    else
        gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"
    fi
    
    gcloud config set project $PROJECT_ID
    log_success "プロジェクト $PROJECT_ID を設定しました"
}

# 課金アカウントをプロジェクトに紐付け
link_billing() {
    log_info "課金アカウントをプロジェクトに紐付け中..."
    
    local current_billing=$(gcloud billing projects describe $PROJECT_ID --format="value(billingAccountName)" 2>/dev/null || echo "")
    
    if [ -z "$current_billing" ]; then
        gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID
        log_success "課金アカウントを紐付けました"
    else
        log_warning "課金アカウントは既に設定されています"
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