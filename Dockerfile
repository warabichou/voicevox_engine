FROM python:3.10-slim

# 必要な依存
RUN apt-get update && apt-get install -y \
    git curl unzip ffmpeg libsndfile1-dev build-essential && \
    apt-get clean

WORKDIR /app

# VOICEVOX masterブランチを clone
RUN git clone https://github.com/VOICEVOX/voicevox_engine.git .

# resources を除外（インストール対象外にするため）
RUN rm -rf resources test tools docs

# setup.py を追加（← voicevox_engine だけを対象にする）
COPY setup.py ./setup.py

# Pythonライブラリインストール
RUN pip install --upgrade pip && \
    pip install .

# モデルファイルダウンロード
RUN python3 -m voicevox_engine.dev.download_resource --download-dir /root/.cache/voicevox_engine

EXPOSE 50021

CMD ["python3", "-m", "voicevox_engine", "--host", "0.0.0.0"]
