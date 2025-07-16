#!/bin/bash

# GCP フルスタック セットアップ - 前提条件チェック

# Docker設定チェック
check_docker_setup() {
    log_info "Docker設定をチェック中..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Dockerコマンドが見つかりません。"
        echo ""
        echo "🐳 Docker設定方法:"
        echo "1. Docker Desktop for Windows を使用する場合:"
        echo "   - Docker Desktop を起動"
        echo "   - Settings > Resources > WSL Integration を開く"
        echo "   - 'Enable integration with my default WSL distro' をチェック"
        echo "   - Apply & Restart をクリック"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker デーモンが起動していません。"
        echo "Docker Desktop を起動してください。"
        read -p "Docker Desktop を起動しましたか？ (y/n): " docker_ready
        if [ "$docker_ready" != "y" ]; then
            exit 1
        fi
    fi
    
    if ! docker ps &> /dev/null; then
        log_error "Docker権限がありません。"
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
}

# MySQLクライアントのインストール
install_mysql_client() {
    log_info "MySQLクライアントをインストール中..."
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y mysql-client
    elif command -v yum &> /dev/null; then
        sudo yum install -y mysql
    elif command -v brew &> /dev/null; then
        brew install mysql-client
    else
        log_error "MySQLクライアントを自動インストールできません。"
        echo "手動でインストールしてください:"
        echo "  Ubuntu/Debian: sudo apt-get install mysql-client"
        echo "  CentOS/RHEL: sudo yum install mysql"
        echo "  macOS: brew install mysql-client"
        exit 1
    fi
    
    log_success "MySQLクライアントをインストールしました"
}

# ネットワークチェックツールのインストール
install_network_tools() {
    log_info "ネットワークチェックツールを確認中..."
    
    # ss コマンドがない場合はインストール
    if ! command -v ss &> /dev/null; then
        log_info "iproute2パッケージをインストール中..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y iproute2
        elif command -v yum &> /dev/null; then
            sudo yum install -y iproute
        fi
    fi
    
    log_success "ネットワークチェックツールの確認完了"
}

# 前提条件チェック（MySQL版）
check_prerequisites() {
    log_info "前提条件をチェック中..."
    
    # gcloud コマンドの存在確認
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud コマンドが見つかりません。"
        exit 1
    fi
    
    # Docker設定チェック
    check_docker_setup
    
    # ネットワークチェックツールのインストール
    install_network_tools
    
    # mysql コマンドの存在確認
    if ! command -v mysql &> /dev/null; then
        log_warning "mysql コマンドが見つかりません。MySQLクライアントをインストールします。"
        install_mysql_client
    fi
    
    # ディレクトリとファイルの確認
    for path in "$DOCKERFILE_PATH" "$SQL_FILE_PATH"; do
        local dir=$(dirname "$path")
        if [ ! -d "$dir" ]; then
            log_info "ディレクトリが存在しません。作成します: $dir"
            mkdir -p "$dir"
        fi
    done
    
    # gcloud認証の確認
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "gcloud認証が必要です。以下のコマンドを実行してください:"
        echo "  gcloud auth login"
        exit 1
    fi
    
    log_success "前提条件チェック完了"
}
