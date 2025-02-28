#!/bin/bash

# 引数チェック
if [ "$#" -lt 1 ]; then
    echo "使用方法: $0 <モデル名> [バッチサイズ] [エポック数]"
    exit 1
fi

MODEL_NAME=$1
BATCH_SIZE=${2:-4}  # デフォルト値4
EPOCHS=${3:-100}    # デフォルト値100

# 環境変数の設定
export CUDA_VISIBLE_DEVICES=0

echo "=== 学習開始 ==="
echo "モデル名: $MODEL_NAME"
echo "バッチサイズ: $BATCH_SIZE"
echo "エポック数: $EPOCHS"

# 処理ステップの選択
echo "実行するステップを選択してください:"
echo "1: すべて実行（データ準備から学習まで）"
echo "2: 書き起こしからやり直し"
echo "3: 前処理からやり直し"
echo "4: 学習のみ実行"
read -p "選択 (1-4): " step_choice

case $step_choice in
   1)
     # スライス処理
     echo "=== 音声スライス処理開始 ==="
     python slice.py --model_name "$MODEL_NAME"

     # 書き起こし処理
     echo "=== 音声書き起こし処理開始 ==="
     python transcribe.py --model_name "$MODEL_NAME" --language ja --use_hf_whisper

     # 前処理
     echo "=== 前処理開始 ==="
     python preprocess_all.py -m "$MODEL_NAME" --use_jp_extra -b "$BATCH_SIZE" -e "$EPOCHS" --yomi_error skip

     # 学習実行
     echo "=== モデル学習開始 ==="
     python train_ms_jp_extra.py -m "$MODEL_NAME" 
     ;;

   2)
     # 書き起こし処理
     echo "=== 音声書き起こし処理開始 ==="
     python transcribe.py --model_name "$MODEL_NAME" --language ja --use_hf_whisper

     # 前処理
     echo "=== 前処理開始 ==="
     python preprocess_all.py -m "$MODEL_NAME" --use_jp_extra -b "$BATCH_SIZE" -e "$EPOCHS" --yomi_error skip

     # 学習実行
     echo "=== モデル学習開始 ==="
     python train_ms_jp_extra.py -m "$MODEL_NAME"
     ;;

   3)
     # 前処理
     echo "=== 前処理開始 ==="
     python preprocess_all.py -m "$MODEL_NAME" --use_jp_extra -b "$BATCH_SIZE" -e "$EPOCHS" --yomi_error skip

     # 学習実行
     echo "=== モデル学習開始 ==="
     python train_ms_jp_extra.py
     ;;

   4)
     # 学習実行
     echo "=== モデル学習開始 ==="
     python train_ms_jp_extra.py
     ;;

   *)
     echo "無効な選択です"
     exit 1
     ;;
esac

# 学習結果の評価
echo "=== 学習結果の評価開始 ==="
python speech_mos.py -m "$MODEL_NAME"

echo "=== 処理完了 ===" 