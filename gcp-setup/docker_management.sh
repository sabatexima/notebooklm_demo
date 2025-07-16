#!/bin/bash

# GCP フルスタック セットアップ - Docker管理

# Docker認証設定
setup_docker_auth() {
    log_info "Docker認証設定中..."
    
    if gcloud auth configure-docker ${LOCATION}-docker.pkg.dev --quiet; then
        log_success "Docker認証を設定しました"
    else
        log_error "Docker認証の設定に失敗しました"
        exit 1
    fi
}

# Dockerイメージのビルドとプッシュ
build_and_push_image() {
    log_info "Dockerイメージのビルドとプッシュ中..."
    
    local image_uri="${LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/${IMAGE_NAME}:latest"
    
    # イメージビルド
    log_info "Dockerイメージをビルド中..."
    if ${DOCKER_CMD} build ./ -t "$image_uri" -f "$DOCKERFILE_PATH"; then
        log_success "Dockerイメージをビルドしました"
    else
        log_error "Dockerイメージのビルドに失敗しました"
        exit 1
    fi
    
    # イメージプッシュ
    log_info "Dockerイメージをプッシュ中..."
    if ${DOCKER_CMD} push "$image_uri"; then
        log_success "Dockerイメージをプッシュしました: $image_uri"
    else
        log_error "Dockerイメージのプッシュに失敗しました"
        exit 1
    fi
    
    # グローバル変数に保存
    IMAGE_URI="$image_uri"
}