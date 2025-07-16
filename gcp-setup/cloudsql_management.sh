#!/bin/bash

#!/bin/bash

# GCP フルスタック セットアップ - Cloud SQL管理（MySQL対応・タイムアウト解決版）

# 進捗表示用のアニメーション関数
show_progress_animation() {
    local message="$1"
    local duration="$2"
    local chars="/-\|"
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        for (( i=0; i<${#chars}; i++ )); do
            echo -ne "\r${BLUE}[INFO]${NC} $message ${chars:$i:1}"
            sleep 0.1
        done
    done
    echo -ne "\r${BLUE}[INFO]${NC} $message 完了\n"
}

# Cloud SQL インスタンス作成（MySQL 8.0版・タイムアウト解決版）
create_cloud_sql() {
    log_info "Cloud SQL インスタンス作成開始: $SQL_INSTANCE_NAME (MySQL 8.0)"
    
    if gcloud sql instances describe $SQL_INSTANCE_NAME &> /dev/null; then
        log_warning "Cloud SQL インスタンス $SQL_INSTANCE_NAME は既に存在します"
        return 0
    fi
    
    log_info "新しいCloud SQLインスタンス（MySQL）を作成します..."
    echo ""
    echo "🔧 インスタンス作成パラメータ："
    echo "  📋 インスタンス名: $SQL_INSTANCE_NAME"
    echo "  🗄️ データベース: MySQL 8.0"
    echo "  💾 ティア: $SQL_TIER"
    echo "  🌏 リージョン: $SQL_REGION"
    echo "  🔐 パスワード: [自動生成済み]"
    echo "  📈 ストレージ: 自動拡張有効"
    echo "  🔄 バックアップ: 03:00 (JST)"
    echo "  🛠️ メンテナンス: 日曜日 04:00"
    echo ""
    
    # 作成開始時刻を記録
    local start_time=$(date +%s)
    log_info "インスタンス作成を開始します（通常5 ~ 15分程度かかります）..."
    
    # Cloud SQLインスタンスを作成（非同期ではなく同期で実行）
    log_info "🚀 Cloud SQL インスタンス作成コマンドを実行中..."
    
    if gcloud sql instances create $SQL_INSTANCE_NAME \
        --database-version=MYSQL_8_0 \
        --tier=$SQL_TIER \
        --region=$SQL_REGION \
        --root-password="$SQL_PASSWORD" \
        --storage-auto-increase \
        --backup-start-time=03:00 \
        --maintenance-window-day=SUN \
        --maintenance-window-hour=04; then
        
        local total_time=$(($(date +%s) - start_time))
        local total_minutes=$((total_time / 60))
        local total_seconds=$((total_time % 60))
        
        log_success "✅ Cloud SQL インスタンス作成が完了しました (${total_minutes}分${total_seconds}秒)"
    else
        log_error "❌ Cloud SQL インスタンス作成に失敗しました"
        return 1
    fi
    
    # 最終的な状態確認と情報表示
    show_instance_info "$SQL_INSTANCE_NAME"
    
    # データベースとユーザーの作成
    create_database_and_user
    
    log_success "✅ Cloud SQL インスタンス（MySQL 8.0）のセットアップが完了しました"
}

# インスタンス作成の進捗チェック（手動確認用）
check_instance_creation_progress() {
    local instance_name="$1"
    
    # 現在のオペレーション状態を取得
    local operations=$(gcloud sql operations list --instance="$instance_name" --limit=1 --format="value(name,operationType,status,startTime)" 2>/dev/null)
    
    if [ -n "$operations" ]; then
        local operation_name=$(echo "$operations" | cut -d$'\t' -f1)
        local operation_type=$(echo "$operations" | cut -d$'\t' -f2)
        local operation_status=$(echo "$operations" | cut -d$'\t' -f3)
        local start_time=$(echo "$operations" | cut -d$'\t' -f4)
        
        log_info "📊 現在のオペレーション状況："
        echo "  🔄 オペレーション: $operation_type"
        echo "  📈 状態: $operation_status"
        echo "  ⏰ 開始時刻: $start_time"
        
        # 状態に応じたメッセージ
        case $operation_status in
            "PENDING")
                echo "  💭 待機中 - リソースの準備をしています..."
                ;;
            "RUNNING")
                echo "  🏃 実行中 - インスタンスを構築しています..."
                ;;
            "DONE")
                echo "  ✅ 完了 - インスタンスの作成が完了しました"
                ;;
            *)
                echo "  ❓ 不明な状態: $operation_status"
                ;;
        esac
    else
        log_info "📊 オペレーション情報を取得中..."
    fi
    
    # インスタンスの基本情報も確認
    local instance_info=$(gcloud sql instances describe "$instance_name" --format="value(state,gceZone)" 2>/dev/null)
    if [ -n "$instance_info" ]; then
        local instance_state=$(echo "$instance_info" | cut -d$'\t' -f1)
        local instance_zone=$(echo "$instance_info" | cut -d$'\t' -f2)
        
        echo "  🏠 インスタンス状態: $instance_state"
        echo "  🌍 配置ゾーン: $instance_zone"
    fi
    
    echo ""
}

# インスタンスの準備完了を確認（タイムアウトなし版）
wait_for_instance_ready() {
    local instance_name="$1"
    local check_interval=15
    local elapsed=0
    
    log_info "インスタンスの準備完了を確認中..."
    
    while true; do
        local instance_state=$(gcloud sql instances describe "$instance_name" --format="value(state)" 2>/dev/null)
        
        case $instance_state in
            "RUNNABLE")
                echo ""
                log_success "✅ インスタンスの準備が完了しました！"
                return 0
                ;;
            "PENDING_CREATE")
                echo -ne "\r${YELLOW}[待機中]${NC} インスタンス作成中... 🔄 (${elapsed}秒経過)"
                ;;
            "MAINTENANCE")
                echo -ne "\r${YELLOW}[メンテナンス]${NC} 初期設定中... 🛠️ (${elapsed}秒経過)"
                ;;
            "FAILED")
                echo ""
                log_error "❌ インスタンスの作成に失敗しました"
                return 1
                ;;
            *)
                echo -ne "\r${BLUE}[INFO]${NC} 状態: $instance_state ⏳ (${elapsed}秒経過)"
                ;;
        esac
        
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        
        # 30秒ごとに詳細情報を表示
        if [ $((elapsed % 30)) -eq 0 ]; then
            echo ""
            log_info "📊 ${elapsed}秒経過 - 詳細状況を確認中..."
            check_instance_creation_progress "$instance_name"
            
            # 長時間経過時のメッセージ
            if [ $elapsed -ge 600 ]; then  # 5分経過
                local minutes=$((elapsed / 60))
                log_info "⏰ ${minutes}分経過しました。Cloud SQLの作成には時間がかかることがあります。"
                echo "   💡 Google Cloud Console でも進捗を確認できます："
                echo "   🌐 https://console.cloud.google.com/sql/instances"
            fi
            
            if [ $elapsed -ge 1800 ]; then  # 30分経過
                local minutes=$((elapsed / 60))
                log_info "⏰ ${minutes}分経過しました。通常より時間がかかっています。"
                echo ""
                read -p "🤔 このまま待機を続けますか？ (y/n): " continue_wait
                if [ "$continue_wait" != "y" ] && [ "$continue_wait" != "Y" ]; then
                    log_warning "⚠️ ユーザーによって待機がキャンセルされました"
                    echo ""
                    echo "📋 手動確認方法："
                    echo "  gcloud sql instances describe $instance_name"
                    echo "  gcloud sql operations list --instance=$instance_name"
                    return 1
                fi
            fi
        fi
    done
}

# インスタンス情報の表示
show_instance_info() {
    local instance_name="$1"
    
    log_info "📋 インスタンス情報を取得中..."
    
    local instance_info=$(gcloud sql instances describe "$instance_name" --format="value(state,databaseVersion,settings.tier,region,ipAddresses[0].ipAddress)" 2>/dev/null)
    
    if [ -n "$instance_info" ]; then
        local state=$(echo "$instance_info" | cut -d$'\t' -f1)
        local db_version=$(echo "$instance_info" | cut -d$'\t' -f2)
        local tier=$(echo "$instance_info" | cut -d$'\t' -f3)
        local region=$(echo "$instance_info" | cut -d$'\t' -f4)
        local ip_address=$(echo "$instance_info" | cut -d$'\t' -f5)
        
        echo ""
        echo "🎉 ====== インスタンス作成完了 ======"
        echo "  📋 インスタンス名: $instance_name"
        echo "  📊 状態: $state"
        echo "  🗄️ データベース: $db_version"
        echo "  💾 ティア: $tier"
        echo "  🌏 リージョン: $region"
        echo "  🌐 IPアドレス: $ip_address"
        echo "  🔐 rootパスワード: [設定済み]"
        echo "=========================================="
        echo ""
    fi
}

# データベースとユーザーの作成
create_database_and_user() {
    log_info "データベースとユーザーの作成中..."
    
    # データベース作成
    log_info "📊 データベース作成中: $SQL_DATABASE_NAME"
    if ! gcloud sql databases describe $SQL_DATABASE_NAME --instance=$SQL_INSTANCE_NAME &> /dev/null; then
        if gcloud sql databases create $SQL_DATABASE_NAME --instance=$SQL_INSTANCE_NAME; then
            log_success "✅ データベースを作成しました"
        else
            log_error "❌ データベースの作成に失敗しました"
            return 1
        fi
    else
        log_warning "⚠️ データベース $SQL_DATABASE_NAME は既に存在します"
    fi
    
    # ユーザー作成
    log_info "👤 ユーザー作成中: $SQL_USER"
    if ! gcloud sql users describe $SQL_USER --instance=$SQL_INSTANCE_NAME &> /dev/null; then
        if gcloud sql users create $SQL_USER \
            --instance=$SQL_INSTANCE_NAME \
            --password="$SQL_PASSWORD"; then
            log_success "✅ ユーザーを作成しました"
        else
            log_error "❌ ユーザーの作成に失敗しました"
            return 1
        fi
    else
        log_warning "⚠️ ユーザー $SQL_USER は既に存在します"
    fi
    
    # 接続情報の表示
    log_info "🔗 Cloud SQL接続情報（MySQL 8.0）:"
    echo "  📋 インスタンス名: $SQL_INSTANCE_NAME"
    echo "  🗄️ データベース: $SQL_DATABASE_NAME"
    echo "  👤 ユーザー: $SQL_USER"
    echo "  🔐 パスワード: $SQL_PASSWORD"
    echo "  🌏 リージョン: $SQL_REGION"
    echo "  🔗 接続名: ${PROJECT_ID}:${SQL_REGION}:${SQL_INSTANCE_NAME}"
    echo ""
}

# Cloud SQL Proxyの状態チェック（MySQL用・タイムアウト解決版）
check_cloud_sql_proxy_status() {
    local max_attempts=60  # 2分間に延長
    local attempt=0
    
    log_info "Cloud SQL Proxyの起動確認中..."
    
    while [ $attempt -lt $max_attempts ]; do
        if check_port_connection 3306; then
            log_success "✅ Cloud SQL Proxyが起動しました"
            return 0
        fi
        
        # プロセスが実行中かチェック
        if ! pgrep -f "cloud_sql_proxy" &> /dev/null; then
            log_error "❌ Cloud SQL Proxyプロセスが終了しました"
            return 1
        fi
        
        echo -ne "\r${YELLOW}[待機中]${NC} Cloud SQL Proxyの起動を待機中... 🔄 (${attempt}/${max_attempts})"
        sleep 2
        ((attempt++))
    done
    
    echo ""
    log_error "⏰ Cloud SQL Proxyの起動がタイムアウトしました"
    return 1
}

# データベース接続テスト（MySQL版・タイムアウト解決版）
test_database_connection() {
    local max_attempts=20  # 試行回数を増加
    local attempt=0
    
    log_info "データベース接続テスト中..."
    
    while [ $attempt -lt $max_attempts ]; do
        echo -ne "\r${BLUE}[INFO]${NC} 接続試行中... 🔄 (${attempt}/${max_attempts})"
        
        # MySQL接続テスト（タイムアウトを60秒に延長）
        if timeout 60 mysql -h 127.0.0.1 -P 3306 -u "$SQL_USER" -p"$SQL_PASSWORD" "$SQL_DATABASE_NAME" -e "SELECT VERSION();" &> /dev/null; then
            echo ""
            log_success "✅ データベース接続テスト成功"
            
            # 接続確認情報を表示
            mysql -h 127.0.0.1 -P 3306 -u "$SQL_USER" -p"$SQL_PASSWORD" "$SQL_DATABASE_NAME" -e "SELECT CONCAT('MySQL バージョン: ', VERSION()) as info;"
            return 0
        else
            sleep 10  # 待機時間を10秒に延長
            ((attempt++))
        fi
    done
    
    echo ""
    log_error "❌ データベース接続テストに失敗しました"
    return 1
}

# SQLファイル実行機能（MySQL版・タイムアウト解決版）
execute_sql_file() {
    log_info "SQLファイル実行を開始します: $SQL_FILE_PATH"
    
    if [ ! -f "$SQL_FILE_PATH" ]; then
        log_warning "⚠️ SQLファイルが見つかりません: $SQL_FILE_PATH"
        log_info "データベース初期化をスキップします"
        return 0
    fi
    
    local connection_name="${PROJECT_ID}:${SQL_REGION}:${SQL_INSTANCE_NAME}"
    
    # Cloud SQL Proxyをダウンロード・起動
    log_info "🔄 Cloud SQL Proxyの準備中..."
    if ! download_and_start_cloud_sql_proxy "$connection_name"; then
        log_error "❌ Cloud SQL Proxyの起動に失敗しました"
        
        # 代替手段：gcloud sql connectを試す
        log_info "🔄 代替手段：gcloud sql connectを試行します..."
        if test_gcloud_sql_connect; then
            if execute_sql_with_gcloud; then
                return 0
            fi
        fi
        
        return 1
    fi
    
    # 起動待機（十分な時間を確保）
    log_info "⏳ Cloud SQL Proxyの起動を待機中..."
    sleep 30  # 30秒に延長
    
    # Proxyが起動しているか確認
    if ! check_cloud_sql_proxy_status; then
        log_error "❌ Cloud SQL Proxyの起動確認に失敗しました"
        pkill -f cloud_sql_proxy 2>/dev/null || true
        
        # 代替手段：gcloud sql connectを試す
        log_info "🔄 代替手段：gcloud sql connectを試行します..."
        if test_gcloud_sql_connect; then
            if execute_sql_with_gcloud; then
                return 0
            fi
        fi
        
        return 1
    fi
    
    # データベース接続テスト（MySQL版）
    if ! test_database_connection; then
        log_error "❌ データベース接続に失敗しました"
        
        # 詳細なトラブルシューティング情報
        echo ""
        echo "🔍 ====== トラブルシューティング情報 ======"
        echo "1. Cloud SQLインスタンスの状態確認:"
        gcloud sql instances describe $SQL_INSTANCE_NAME --format="table(name,state,ipAddresses[0].ipAddress)"
        
        echo ""
        echo "2. データベース一覧:"
        gcloud sql databases list --instance=$SQL_INSTANCE_NAME --format="table(name)"
        
        echo ""
        echo "3. ユーザー一覧:"
        gcloud sql users list --instance=$SQL_INSTANCE_NAME --format="table(name)"
        echo "================================================="
        
        pkill -f cloud_sql_proxy 2>/dev/null || true
        
        # 代替手段：gcloud sql connectを試す
        log_info "🔄 代替手段：gcloud sql connectを試行します..."
        if test_gcloud_sql_connect; then
            if execute_sql_with_gcloud; then
                return 0
            fi
        fi
        
        return 1
    fi
    
    # SQLファイルを実行（MySQL版）
    log_info "📝 SQLファイルを実行中..."
    local sql_start_time=$(date +%s)
    
    if mysql -h 127.0.0.1 -P 3306 -u "$SQL_USER" -p"$SQL_PASSWORD" "$SQL_DATABASE_NAME" < "$SQL_FILE_PATH"; then
        local sql_end_time=$(date +%s)
        local sql_duration=$((sql_end_time - sql_start_time))
        log_success "✅ SQLファイルの実行が完了しました (${sql_duration}秒)"
    else
        log_error "❌ SQLファイルの実行に失敗しました"
        pkill -f cloud_sql_proxy 2>/dev/null || true
        return 1
    fi
    
    # 実行結果の確認（MySQL版）
    log_info "📊 データベース状態を確認中..."
    mysql -h 127.0.0.1 -P 3306 -u "$SQL_USER" -p"$SQL_PASSWORD" "$SQL_DATABASE_NAME" -e "
        SELECT CONCAT('テーブル数: ', COUNT(*)) AS table_count 
        FROM information_schema.tables 
        WHERE table_schema = '$SQL_DATABASE_NAME';
        
        SELECT CONCAT('📋 作成されたテーブル:') as info;
        SELECT CONCAT('  - ', table_name) as tables
        FROM information_schema.tables 
        WHERE table_schema = '$SQL_DATABASE_NAME' 
        ORDER BY table_name;
    "
    
    # Cloud SQL Proxyを終了
    log_info "🔄 Cloud SQL Proxyを終了中..."
    pkill -f cloud_sql_proxy 2>/dev/null || true
    
    # プロセスが完全に終了するまで待機
    sleep 5
    
    log_success "✅ データベース初期化が完了しました"
}

# Cloud SQL Proxyのダウンロードと起動（MySQL用・進捗表示改善版）
download_and_start_cloud_sql_proxy() {
    local connection_name="$1"
    
    # 既存のCloud SQL Proxyプロセスを終了
    log_info "🔄 既存のCloud SQL Proxyプロセスを終了中..."
    pkill -f cloud_sql_proxy 2>/dev/null || true
    sleep 3
    
    # Cloud SQL Proxyのダウンロード
    if [ ! -f "./cloud_sql_proxy" ]; then
        log_info "📥 Cloud SQL Proxy v1.33をダウンロード中..."
        
        # システムアーキテクチャを判定
        local arch=$(uname -m)
        local os=$(uname -s | tr '[:upper:]' '[:lower:]')
        
        case $arch in
            x86_64)
                arch="amd64"
                ;;
            aarch64|arm64)
                arch="arm64"
                ;;
            *)
                log_warning "⚠️ 未対応のアーキテクチャ: $arch, amd64を使用します"
                arch="amd64"
                ;;
        esac
        
        # Cloud SQL Proxy v1の安定版をダウンロード
        local download_url="https://dl.google.com/cloudsql/cloud_sql_proxy.${os}.${arch}"
        
        echo "📡 ダウンロードURL: $download_url"
        
        if curl -L --progress-bar -o cloud_sql_proxy "$download_url"; then
            chmod +x cloud_sql_proxy
            log_success "✅ Cloud SQL Proxy v1をダウンロードしました"
        else
            log_error "❌ Cloud SQL Proxyのダウンロードに失敗しました"
            return 1
        fi
    else
        log_info "✅ Cloud SQL Proxyは既にダウンロード済みです"
    fi
    
    # Cloud SQL Proxyのバージョン確認
    log_info "🔍 Cloud SQL Proxyのバージョン確認..."
    local version_output=$(./cloud_sql_proxy -version 2>&1 || echo "unknown")
    log_info "📋 Cloud SQL Proxyバージョン: $version_output"
    
    # Cloud SQL Proxy v1でMySQLポート3306を使用
    log_info "🚀 Cloud SQL Proxy v1を起動中（MySQL用）..."
    log_info "🔗 接続先: $connection_name"
    log_info "🌐 ポート: 3306 (MySQL)"
    
    # MySQL用の正しい構文で起動
    ./cloud_sql_proxy -instances="${connection_name}=tcp:3306" &
    local proxy_pid=$!
    
    log_info "🆔 Cloud SQL Proxy PID: $proxy_pid"
    
    # プロセスが正常に起動したか確認
    log_info "⏳ プロセス起動確認中..."
    sleep 5
    
    if ! kill -0 $proxy_pid 2>/dev/null; then
        log_error "❌ Cloud SQL Proxyプロセスが起動直後に終了しました"
        
        # より詳細なエラー情報を取得
        log_info "🔍 Cloud SQL Proxyを詳細モードで再起動してエラーを確認します..."
        echo "📋 デバッグ情報:"
        ./cloud_sql_proxy -instances="${connection_name}=tcp:3306" -verbose &
        local debug_pid=$!
        sleep 3
        kill $debug_pid 2>/dev/null || true
        
        return 1
    fi
    
    log_success "✅ Cloud SQL Proxyプロセスが起動しました"
    return 0
}

# gcloud sql connectのテスト（MySQL版・進捗表示改善）
test_gcloud_sql_connect() {
    log_info "🔍 gcloud sql connectの動作確認中..."
    
    # 簡単な接続テスト
    log_info "⏳ 接続テスト実行中..."
    if timeout 10 gcloud sql connect $SQL_INSTANCE_NAME --user=root --quiet < /dev/null 2>/dev/null; then
        log_success "✅ gcloud sql connectが利用可能です"
        return 0
    else
        log_warning "⚠️ gcloud sql connectが利用できません"
        return 1
    fi
}

# gcloud sql connectを使用したSQL実行（MySQL版・進捗表示改善）
execute_sql_with_gcloud() {
    log_info "🔄 gcloud sql connectを使用してSQLファイルを実行中..."
    
    # 一時的な実行用スクリプトを作成
    local temp_script=$(mktemp)
    log_info "📄 一時スクリプトを作成: $temp_script"
    
    cat > "$temp_script" << EOF
USE $SQL_DATABASE_NAME;
SOURCE $SQL_FILE_PATH;
SELECT CONCAT('テーブル数: ', COUNT(*)) AS table_count 
FROM information_schema.tables 
WHERE table_schema = '$SQL_DATABASE_NAME';
EOF
    
    log_info "📝 SQLスクリプト内容:"
    echo "  - データベース選択: $SQL_DATABASE_NAME"
    echo "  - SQLファイル実行: $SQL_FILE_PATH"
    echo "  - 結果確認: テーブル数カウント"
    
    # gcloud sql connectでMySQLに接続してSQLファイルを実行
    log_info "🔄 SQL実行中..."
    if gcloud sql connect $SQL_INSTANCE_NAME --user=$SQL_USER --database=$SQL_DATABASE_NAME < "$temp_script"; then
        log_success "✅ gcloud sql connectを使用してSQLファイルを実行しました"
        rm -f "$temp_script"
        return 0
    else
        log_error "❌ gcloud sql connectを使用したSQL実行に失敗しました"
        rm -f "$temp_script"
        return 1
    fi
}

# Cloud SQL接続テスト関数（MySQL版・進捗表示改善）
test_sql_connection() {
    log_info "🔍 Cloud SQL接続テスト中..."
    
    local connection_name="${PROJECT_ID}:${SQL_REGION}:${SQL_INSTANCE_NAME}"
    
    echo ""
    echo "🔗 ====== Cloud SQL接続情報（MySQL） ======"
    echo "  📋 プロジェクト: $PROJECT_ID"
    echo "  🏠 インスタンス名: $SQL_INSTANCE_NAME"
    echo "  🗄️ データベース名: $SQL_DATABASE_NAME"
    echo "  👤 ユーザー名: $SQL_USER"
    echo "  🔐 パスワード: $SQL_PASSWORD"
    echo "  🔗 接続名: $connection_name"
    echo "============================================="
    echo ""
    echo "🛠️ Cloud SQL Proxyを使用した接続方法（MySQL用）:"
    echo "  1. 別のターミナルで以下を実行:"
    echo "     ./cloud_sql_proxy -instances='${connection_name}=tcp:3306'"
    echo "  2. 別のターミナルで以下を実行:"
    echo "     mysql -h 127.0.0.1 -P 3306 -u $SQL_USER -p$SQL_PASSWORD $SQL_DATABASE_NAME"
    echo ""
    echo "🔄 または、gcloud sql connectを使用:"
    echo "  gcloud sql connect $SQL_INSTANCE_NAME --user=$SQL_USER --database=$SQL_DATABASE_NAME"
    echo ""
}

# ポート接続チェック関数（MySQL用・進捗表示改善）
check_port_connection() {
    local port=${1:-3306}
    local host=${2:-127.0.0.1}
    
    # 方法1: ss コマンドを使用
    if command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":${port} "; then
            return 0
        fi
    fi
    
    # 方法2: netstat コマンドを使用
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":${port} "; then
            return 0
        fi
    fi
    
    # 方法3: lsof コマンドを使用
    if command -v lsof &> /dev/null; then
        if lsof -i :${port} &> /dev/null; then
            return 0
        fi
    fi
    
    # 方法4: nc (netcat) を使用した接続テスト
    if command -v nc &> /dev/null; then
        if nc -z ${host} ${port} &> /dev/null; then
            return 0
        fi
    fi
    
    # 方法5: timeout + bash内蔵機能を使用
    if timeout 1 bash -c "</dev/tcp/${host}/${port}" &> /dev/null; then
        return 0
    fi
    
    return 1
}