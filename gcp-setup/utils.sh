#!/bin/bash

# default_config.json の作成と API キー設定
setup_default_config() {
    local config_file="../src/default_config.json"
    local config_dir="../src"
    
    log_info "default_config.json の設定を開始します..."
    
    # srcディレクトリが存在しない場合は作成
    if [ ! -d "$config_dir" ]; then
        log_info "📁 ディレクトリを作成します: $config_dir"
        mkdir -p "$config_dir"
        log_success "✅ ディレクトリを作成しました"
    fi
    
    # default_config.json が存在しない場合は作成
    if [ ! -f "$config_file" ]; then
        log_info "📄 default_config.json を作成中..."
        
        # デフォルト設定ファイルを作成
        cat > "$config_file" << 'EOF'
{
  "googleApiKey": ""
}
EOF
        
        log_success "✅ default_config.json を作成しました: $config_file"
    else
        log_info "✅ default_config.json は既に存在します: $config_file"
    fi
    
    # 現在の設定を確認
    if [ -f "$config_file" ]; then
        local current_api_key=$(grep -o '"googleApiKey": *"[^"]*"' "$config_file" | sed 's/"googleApiKey": *"//; s/"//')
        
        if [ -z "$current_api_key" ]; then
            log_warning "⚠️ Google API キーが設定されていません"
            prompt_for_api_key "$config_file"
        else
            log_info "✅ Google API キーが設定済みです"
            echo "  🔑 現在のAPIキー: ${current_api_key:0:10}...${current_api_key: -6}"
            echo ""
            
            read -p "🔄 APIキーを変更しますか？ (y/n): " change_api_key
            if [ "$change_api_key" = "y" ] || [ "$change_api_key" = "Y" ]; then
                prompt_for_api_key "$config_file"
            else
                log_info "📋 既存のAPIキーを使用します"
            fi
        fi
    fi
    
    echo ""
}

# APIキー入力プロンプト
prompt_for_api_key() {
    local config_file="$1"
    
    echo ""
    echo "🔑 ====== Google API キーの設定 ======"
    echo ""
    echo "📋 Google API キーが必要です。"
    echo "以下の手順でAPIキーを取得してください："
    echo ""
    echo "1. 🌐 Google Cloud Console にアクセス"
    echo "   https://console.cloud.google.com/"
    echo ""
    echo "2. 📋 プロジェクトを選択"
    echo "   (作成予定のプロジェクト: $PROJECT_ID)"
    echo ""
    echo "3. 🔍 「APIs & Services」> 「Credentials」に移動"
    echo ""
    echo "4. ➕ 「+ CREATE CREDENTIALS」> 「API key」を選択"
    echo ""
    echo "5. 🔑 作成されたAPIキーをコピー"
    echo ""
    echo "6. ⚙️ 必要に応じてAPIキーを制限"
    echo "   - Application restrictions"
    echo "   - API restrictions"
    echo ""
    echo "=================================================="
    echo ""
    
    while true; do
        echo "🔑 Google API キーを入力してください："
        echo "   (入力中は文字が表示されません)"
        read -s api_key
        echo ""
        
        # APIキーの基本的な検証
        if [ -z "$api_key" ]; then
            log_error "❌ APIキーが入力されていません"
            echo ""
            read -p "🔄 再試行しますか？ (y/n): " retry
            if [ "$retry" != "y" ] && [ "$retry" != "Y" ]; then
                log_warning "⚠️ APIキーの設定をスキップしました"
                return 1
            fi
            continue
        fi
        
        # APIキーの長さチェック（Google API キーは通常39文字）
        if [ ${#api_key} -lt 30 ]; then
            log_error "❌ APIキーが短すぎます（30文字以上である必要があります）"
            echo "   入力されたAPIキーの長さ: ${#api_key}文字"
            echo ""
            read -p "🔄 再試行しますか？ (y/n): " retry
            if [ "$retry" != "y" ] && [ "$retry" != "Y" ]; then
                log_warning "⚠️ APIキーの設定をスキップしました"
                return 1
            fi
            continue
        fi
        
        # APIキーの形式チェック（英数字とハイフンのみ）
        if [[ ! "$api_key" =~ ^[A-Za-z0-9_-]+$ ]]; then
            log_error "❌ 無効なAPIキー形式です（英数字、アンダースコア、ハイフンのみ使用可能）"
            echo ""
            read -p "🔄 再試行しますか？ (y/n): " retry
            if [ "$retry" != "y" ] && [ "$retry" != "Y" ]; then
                log_warning "⚠️ APIキーの設定をスキップしました"
                return 1
            fi
            continue
        fi
        
        # 確認表示
        echo ""
        echo "🔍 入力されたAPIキー:"
        echo "  📏 長さ: ${#api_key}文字"
        echo "  🔑 キー: ${api_key:0:10}...${api_key: -6}"
        echo ""
        
        read -p "✅ このAPIキーを使用しますか？ (y/n): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            break
        else
            echo ""
            log_info "🔄 APIキーを再入力してください"
            echo ""
        fi
    done
    
    # APIキーをJSONファイルに保存
    log_info "💾 APIキーをファイルに保存中..."
    
    # 一時ファイルを作成してJSONを更新
    local temp_file=$(mktemp)
    
    # jq コマンドがある場合は使用
    if command -v jq &> /dev/null; then
        jq --arg key "$api_key" '.googleApiKey = $key' "$config_file" > "$temp_file"
        mv "$temp_file" "$config_file"
    else
        # jqがない場合は sed を使用
        sed "s/\"googleApiKey\": *\"[^\"]*\"/\"googleApiKey\": \"$api_key\"/" "$config_file" > "$temp_file"
        mv "$temp_file" "$config_file"
    fi
    
    # ファイルの権限を設定（APIキーが含まれるため）
    chmod 600 "$config_file"
    
    log_success "✅ Google API キーを設定しました"
    echo "  📄 保存先: $config_file"
    echo "  🔒 ファイル権限: 600 (所有者のみ読み書き可能)"
    echo ""
    
    # 設定確認
    log_info "🔍 設定確認:"
    echo "  🔑 APIキー: ${api_key:0:10}...${api_key: -6}"
    echo "  📏 長さ: ${#api_key}文字"
    echo ""
    
    # セキュリティ注意事項
    echo "🔐 ====== セキュリティ注意事項 ======"
    echo "  ⚠️ APIキーは機密情報です"
    echo "  ⚠️ バージョン管理システムにコミットしないでください"
    echo "  ⚠️ 他の人と共有しないでください"
    echo "  ⚠️ 定期的にAPIキーをローテーションしてください"
    echo "=================================="
    echo ""
    
    return 0
}

# 設定ファイルの確認
verify_config_file() {
    local config_file="../src/default_config.json"
    
    if [ ! -f "$config_file" ]; then
        log_error "❌ 設定ファイルが見つかりません: $config_file"
        return 1
    fi
    
    # JSON形式の確認
    if command -v jq &> /dev/null; then
        if ! jq empty "$config_file" 2>/dev/null; then
            log_error "❌ 設定ファイルのJSON形式が無効です"
            return 1
        fi
    fi
    
    local api_key=$(grep -o '"googleApiKey": *"[^"]*"' "$config_file" | sed 's/"googleApiKey": *"//; s/"//')
    
    if [ -z "$api_key" ]; then
        log_warning "⚠️ APIキーが設定されていません"
        return 1
    fi
    
    log_success "✅ 設定ファイルの確認完了"
    echo "  📄 ファイル: $config_file"
    echo "  🔑 APIキー: ${api_key:0:10}...${api_key: -6}"
    
    return 0
}

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

# コマンドライン引数の処理
process_args() {
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
            -q|--sql-file)
                SQL_FILE_PATH="$2"
                shift 2
                ;;
            --skip-config)
                SKIP_CONFIG_SETUP=true
                shift
                ;;
            *)
                log_error "不明なオプション: $1"
                show_help
                exit 1
                ;;
        esac
    done
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
    echo "  -q, --sql-file FILE     SQLファイルパスを指定"
    echo "  --skip-config           設定ファイルのセットアップをスキップ"
    echo ""
    echo "例:"
    echo "  $0                                    # 対話式で実行"
    echo "  $0 -p my-project-202501             # プロジェクトIDを指定"
    echo "  $0 -f ./docker_gcp/Dockerfile_gcp -q ./src/DB.sql  # パスを指定"
    echo "  $0 --skip-config                     # 設定ファイルのセットアップをスキップ"
    echo ""
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
        echo "  Dockerfile: $DOCKERFILE_PATH"
        echo "  SQLファイル: $SQL_FILE_PATH"
        echo ""
        echo "手動実行コマンド:"
        echo "  gcloud projects delete $PROJECT_ID  # プロジェクト削除"
        echo "  pkill -f cloud_sql_proxy  # Cloud SQL Proxy終了"
    fi
    
    # 一時ファイルの削除
    rm -f /tmp/default_config_*.json 2>/dev/null || true
}