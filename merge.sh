#!/bin/bash

# スクリプトのディレクトリに移動
cd "$(dirname "$0")"

# 仮想環境を有効化
source venv/bin/activate

# デフォルト値の設定
MODEL_A=""
MODEL_B=""
OUTPUT=""
VOICE_WEIGHT=0.0
VOICE_PITCH_WEIGHT=0.9
SPEECH_STYLE_WEIGHT=0.3
TEMPO_WEIGHT=0.5
METHOD="usual"
USE_SLERP=False

# ヘルプメッセージ
show_help() {
    echo "Usage: $0 -a MODEL_A -b MODEL_B -o OUTPUT [-m METHOD] [-v VOICE_WEIGHT] [-p VOICE_PITCH_WEIGHT] [-s SPEECH_STYLE_WEIGHT] [-t TEMPO_WEIGHT] [--slerp]"
    echo
    echo "Required arguments:"
    echo "  -a MODEL_A           First model name (new model)"
    echo "  -b MODEL_B           Second model name (reference model)"
    echo "  -o OUTPUT            Output model name"
    echo
    echo "Optional arguments:"
    echo "  -m METHOD           Merge method (default: usual)"
    echo "                      Options: usual, add_diff, weighted_sum, add_null"
    echo "  -v VOICE_WEIGHT     Voice blending ratio (default: 0.9)"
    echo "  -p PITCH_WEIGHT     Voice pitch weight (default: 0.9)"
    echo "  -s STYLE_WEIGHT     Speech style weight (default: 0.3)"
    echo "  -t TEMPO_WEIGHT     Tempo weight (default: 0.5)"
    echo "  --slerp            Use spherical linear interpolation"
    echo "  -h                 Show this help message"
}

# コマンドライン引数の解析
while getopts "a:b:o:m:v:p:s:t:h-:" opt; do
    case "${opt}" in
        -)
            case "${OPTARG}" in
                slerp)
                    USE_SLERP=true
                    ;;
                *)
                    echo "Invalid option: --${OPTARG}" >&2
                    show_help
                    exit 1
                    ;;
            esac;;
        a) MODEL_A="$OPTARG";;
        b) MODEL_B="$OPTARG";;
        o) OUTPUT="$OPTARG";;
        m) METHOD="$OPTARG";;
        v) VOICE_WEIGHT="$OPTARG";;
        p) VOICE_PITCH_WEIGHT="$OPTARG";;
        s) SPEECH_STYLE_WEIGHT="$OPTARG";;
        t) TEMPO_WEIGHT="$OPTARG";;
        h) show_help; exit 0;;
        ?) show_help; exit 1;;
    esac
done

# 必須パラメータのチェック
if [ -z "$MODEL_A" ] || [ -z "$MODEL_B" ] || [ -z "$OUTPUT" ]; then
    echo "Error: Missing required arguments"
    show_help
    exit 1
fi

# メソッドの検証
case "$METHOD" in
    usual|add_diff|weighted_sum|add_null) ;;
    *)
        echo "Error: Invalid merge method: $METHOD"
        show_help
        exit 1
        ;;
esac

echo "Starting model merge..."
echo "Method: $METHOD"
echo "Model A: $MODEL_A"
echo "Model B: $MODEL_B"
echo "Output: $OUTPUT"
echo "Voice Weight: $VOICE_WEIGHT"
echo "Voice Pitch Weight: $VOICE_PITCH_WEIGHT"
echo "Speech Style Weight: $SPEECH_STYLE_WEIGHT"
echo "Tempo Weight: $TEMPO_WEIGHT"
echo "Use SLERP: $USE_SLERP"

# マージの実行
python -c "
from gradio_tabs.merge import merge_models_gr
from pathlib import Path

# モデルのパスを構築
model_dir = Path('model_assets')
model_a_path = str(model_dir / '$MODEL_A' / '${MODEL_A}_e5_s2990.safetensors')
model_b_path = str(model_dir / '$MODEL_B' / '${MODEL_B}.safetensors')
model_c_path = str(model_dir / 'dummy' / 'dummy.safetensors')  # ダミーパス

# 重みを計算（voice_weightを使用）
a_coeff = 1.0 - $VOICE_WEIGHT  # Bの重みを指定値に
b_coeff = $VOICE_WEIGHT        # Aの重みは残りに

result = merge_models_gr(
    model_a_path,
    model_b_path,
    model_c_path,
    a_coeff,        # model_a_coeff
    b_coeff,        # model_b_coeff
    0.0,            # model_c_coeff
    '$METHOD',
    '$OUTPUT',
    $VOICE_WEIGHT,
    $VOICE_PITCH_WEIGHT,
    $SPEECH_STYLE_WEIGHT,
    $TEMPO_WEIGHT,
    $USE_SLERP == 'true'
)
print(result[0])  # Print merge info
"

if [ $? -ne 0 ]; then
    echo "Error occurred during model merging."
    exit 1
fi

echo "Model merging completed successfully." 