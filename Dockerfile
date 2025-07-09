FROM python:3.12.4

# ロケール・タイムゾーン設定用のパッケージをインストール
RUN apt-get update && \
    apt-get install -y locales tzdata && \
    echo "ja_JP.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=ja_JP.UTF-8 && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    apt-get clean

# GCPに上げるときはコメント外す
# WORKDIR /app
# ADD . /app

# GCPに上げるときはコメントつける
COPY requirements.txt .

RUN pip install -r requirements.txt

# タイムゾーンとロケール設定
ENV TZ=Asia/Tokyo \
    LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja \
    LC_ALL=ja_JP.UTF-8


# GCPに上げるときはコメント外す

# # Python / Flask 設定
# ENV FLASK_APP=/app/app.py \
#     PYTHONPATH=/app

# ENV PORT=8080
# EXPOSE 8080

# CMD ["python", "app.py"]
