FROM python:3.10-slim

# 必要な依存
RUN apt-get update && apt-get install -y \
    git curl unzip ffmpeg libsndfile1-dev build-essential python3-dev && \
    apt-get clean

WORKDIR /app

# VOICEVOXエンジンのrelease-0.24をclone
RUN git clone --depth 1 --branch release-0.24 https://github.com/VOICEVOX/voicevox_engine.git .

# pyproject.tomlビルド対応のパッケージを事前にインストール
RUN pip install --upgrade pip setuptools wheel build

# ライブラリインストール
RUN pip install .

# モデルファイルをダウンロード
RUN python3 -m voicevox_engine.dev.download_resource --download-dir /root/.cache/voicevox_engine

EXPOSE 50021

CMD ["python3", "-m", "voicevox_engine", "--host", "0.0.0.0"]
