FROM python:3.11-slim

# 作業ディレクトリを設定
WORKDIR /app

# 必要なツールのインストール
RUN apt-get update && \
  apt-get install -y \
  sudo \
  build-essential \
  ca-certificates \
  wget \
  curl \
  git \
  zip \
  unzip \
  nano \
  ffmpeg \
  software-properties-common \
  gnupg \
  gcc \
  python3-dev \
  && rm -rf /var/lib/apt/lists/*

# ホストのStyle-Bert-VITS2のファイルをコピー
COPY . .

# 初期設定（initialize.pyの実行を削除）
RUN python -m venv venv && \
  . ./venv/bin/activate && \
  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
  pip install -r requirements.txt