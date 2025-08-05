FROM python:3.10-slim

# 必要なパッケージ
RUN apt-get update && apt-get install -y \
    git curl unzip ffmpeg libsndfile1-dev && \
    pip install --upgrade pip

# Pythonライブラリ
RUN pip install fastapi uvicorn numpy scipy librosa soundfile aiofiles

# 作業ディレクトリ
WORKDIR /app

# ✅ release-0.24 ブランチをクローン
RUN git clone --depth 1 --branch release-0.24 https://github.com/VOICEVOX/voicevox_engine.git .

# ✅ モデルファイルを公式スクリプトで取得
RUN python3 -m voicevox_engine.dev.download_resource --download-dir /root/.cache/voicevox_engine

# ポート開放（デフォルト）
EXPOSE 50021

# 起動コマンド
CMD ["uvicorn", "voicevox_engine.dev.core:app", "--host", "0.0.0.0", "--port", "50021"]

