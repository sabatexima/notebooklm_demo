# Cloud Run サービスデプロイ（MySQL版）
deploy_to_cloud_run() {
    log_info "Cloud Run サービスデプロイ中: $SERVICE_NAME"
    
    local connection_name="${PROJECT_ID}:${SQL_REGION}:${SQL_INSTANCE_NAME}"
    
    gcloud run deploy $SERVICE_NAME \
        --image="$IMAGE_URI" \
        --platform=managed \
        --region=$CLOUD_RUN_REGION \
        --allow-unauthenticated \
        --set-env-vars="PROJECT_ID=$PROJECT_ID,DB_HOST=/cloudsql/$connection_name,DB_NAME=$SQL_DATABASE_NAME,DB_USER=$SQL_USER,DB_PASSWORD=$SQL_PASSWORD,DB_PORT=3306" \
        --add-cloudsql-instances="$connection_name" \
        --port=8080 \
        --memory=512Mi \
        --cpu=1
    
    log_success "Cloud Run サービスをデプロイしました"
    
    # サービスURLを取得
    local service_url=$(gcloud run services describe $SERVICE_NAME --region=$CLOUD_RUN_REGION --format="value(status.url)")
    log_success "サービスURL: $service_url"
    
    # 健全性チェック
    log_info "デプロイされたサービスの健全性をチェック中..."
    sleep 10  # サービスが起動するまで待機
    
    local max_attempts=5
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -f -s "$service_url" > /dev/null; then
            log_success "サービスが正常に動作しています"
            
            # DB接続状態も確認
            local db_status=$(curl -s "$service_url" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            log_info "データベース接続状態: $db_status"
            break
        fi
        
        log_info "健全性チェック中... (${attempt}/${max_attempts})"
        sleep 5
        ((attempt++))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        log_warning "健全性チェックに失敗しました。手動で確認してください。"
    fi
    
    SERVICE_URL="$service_url"
}
