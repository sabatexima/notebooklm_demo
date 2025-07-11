# web上のGCPでartifact registryでリポジトリ作成する（リージョンはasia-northeast1(東京)、それ以外はそのまま）

# googleのアカウントにログインする
# gcloud auth login

# dockerでgcpとpull、pushwpできるように
# gcloud auth configure-docker asia-northeast1-docker.pkg.dev

# ビルドとプッシュ(リージョン/GCPプロジェクトのID/リポジトリ名/イメージ名(ここだけは任意))
docker build ./ -t asia-northeast1-docker.pkg.dev/august-bot-462013-g2/notebooklm-demo/notelm -f Dockerfile_gcp
docker push asia-northeast1-docker.pkg.dev/august-bot-462013-g2/notebooklm-demo/notelm