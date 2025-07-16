#!/bin/bash

set -e

# 必要なファイルの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/prerequisites.sh"
source "$SCRIPT_DIR/gcp_resources.sh"
source "$SCRIPT_DIR/docker_management.sh"
source "$SCRIPT_DIR/cloudsql_management.sh"
source "$SCRIPT_DIR/cloudrun_management.sh"
source "$SCRIPT_DIR/results.sh"

# メイン処理（設定ファイルセットアップ追加版）
main() {
    echo "==========================================="
    echo "🚀 セットアップ実行"
    echo "==========================================="
    echo ""
    echo "📅 生成されるプロジェクトID: $PROJECT_ID"
    echo "🐳 Dockerfile パス: $DOCKERFILE_PATH"
    echo "🗄️ SQLファイル パス: $SQL_FILE_PATH"
    echo "⚙️ 設定ファイル パス: ../src/default_config.json"
    echo ""
    
    # 全体の進捗を表示
    local total_steps=12
    local current_step=0
    
    echo "📋 実行予定のステップ (${total_steps}ステップ):"
    echo "  1. ⚙️ 設定ファイル作成・APIキー設定"
    echo "  2. ✅ 前提条件チェック"
    echo "  3. ✅ 課金アカウント選択"
    echo "  4. ✅ プロジェクト作成"
    echo "  5. ✅ API有効化"
    echo "  6. ✅ Artifact Registry リポジトリ作成"
    echo "  7. 🗄️ Cloud SQL インスタンス作成 ⏰ (3-5分)"
    echo "  8. 🗄️ データベース初期化（SQLファイル実行）"
    echo "  9. 🐳 Docker認証設定"
    echo "  10. 🐳 Dockerイメージビルド・プッシュ"
    echo "  11. ☁️ Cloud Run デプロイ"
    echo "  12. 📋 結果表示"
    echo ""
    
    # 全体の開始時刻を記録
    local overall_start_time=$(date +%s)
    
    # トラップでクリーンアップ関数を設定
    trap cleanup EXIT
    
    # 各ステップの実行
    echo "🎬 セットアップを開始します..."
    echo ""
    
    # ステップ 1: 設定ファイルのセットアップ
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: 設定ファイル作成・APIキー設定"
    if [ "$SKIP_CONFIG_SETUP" != "true" ]; then
        setup_default_config
        if ! verify_config_file; then
            log_error "❌ 設定ファイルの確認に失敗しました"
            exit 1
        fi
    else
        log_info "⏭️ 設定ファイルのセットアップをスキップしました"
    fi
    echo ""
    
    # ステップ 2: 前提条件チェック
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: 前提条件チェック"
    check_prerequisites
    echo ""
    
    # ステップ 3: 課金アカウント選択
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: 課金アカウント選択"
    setup_billing
    echo ""
    
    # ステップ 4: プロジェクト作成
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: プロジェクト作成"
    create_project
    echo ""
    
    # ステップ 5: 課金アカウント紐付け
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: 課金アカウント紐付け"
    link_billing
    echo ""
    
    # ステップ 6: API有効化
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: API有効化"
    enable_apis
    echo ""
    
    # ステップ 7: Artifact Registry リポジトリ作成
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: Artifact Registry リポジトリ作成"
    create_repository
    echo ""
    
    # ステップ 8: Cloud SQL インスタンス作成 (最も時間がかかるステップ)
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: Cloud SQL インスタンス作成 ⏰"
    echo "   ⚠️ このステップは通常3-5分かかります。しばらくお待ちください..."
    local sql_start_time=$(date +%s)
    create_cloud_sql
    local sql_end_time=$(date +%s)
    local sql_duration=$((sql_end_time - sql_start_time))
    echo "   ✅ Cloud SQL作成完了 (${sql_duration}秒)"
    echo ""
    
    # ステップ 9: データベース初期化
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: データベース初期化"
    execute_sql_file
    echo ""
    
    # ステップ 10: Docker認証設定
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: Docker認証設定"
    setup_docker_auth
    echo ""
    
    # ステップ 11: Dockerイメージビルド・プッシュ
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: Dockerイメージビルド・プッシュ"
    build_and_push_image
    echo ""
    
    # ステップ 12: Cloud Run デプロイ
    current_step=$((current_step + 1))
    echo "🔄 ステップ ${current_step}/${total_steps}: Cloud Run デプロイ"
    deploy_to_cloud_run
    echo ""
    
    # 全体の完了時刻を計算
    local overall_end_time=$(date +%s)
    local overall_duration=$((overall_end_time - overall_start_time))
    local overall_minutes=$((overall_duration / 60))
    local overall_seconds=$((overall_duration % 60))
    
    show_final_results
    save_credentials
    
    echo ""
    echo "🎉 ====== 全体完了報告 ======"
    echo "  ⏱️ 総実行時間: ${overall_minutes}分${overall_seconds}秒"
    echo "  📊 完了ステップ: ${current_step}/${total_steps}"
    echo "  🎯 成功率: 100%"
    echo "  ⚙️ 設定ファイル: ../src/default_config.json"
    echo "=========================="
    echo ""
    
    log_success "🎉 すべての処理が完了しました！"
}

# コマンドライン引数を処理
process_args "$@"

# メイン処理実行
main
