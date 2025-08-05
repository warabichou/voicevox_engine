FROM python:3.10-slim

# 必要な依存
RUN apt-get update && apt-get install -y \
    git curl unzip ffmpeg libsndfile1-dev build-essential && \
    apt-get clean

WORKDIR /app

# リポジトリ取得（release-0.24）
RUN git clone --depth 1 --branch release-0.24 https://github.com/VOICEVOX/voicevox_engine.git .

# resources フォルダを除いて voicevox_engine のみ install 対象にする
RUN sed -i "s/find_packages()/['voicevox_engine']/g" setup.py

# Pythonライブラリインストール
RUN pip install --upgrade pip && \
    pip install -e .

# モデルファイルのダウンロード
RUN python3 -m voicevox_engine.dev.download_resource --download-dir /root/.cache/voicevox_engine

EXPOSE 50021

CMD ["python3", "-m", "voicevox_engine", "--host", "0.0.0.0"]
