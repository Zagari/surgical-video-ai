#!/bin/bash
# =============================================================================
# Validação do modelo com dataset GynSurg
# Testa o modelo treinado em CholecSeg8k nos clips de cirurgia ginecológica
# =============================================================================

set -e

# Configurações
S3_MODELS_BUCKET="surgical-detection-models-dev"
S3_RESULTS_BUCKET="surgical-detection-results-dev"
WORK_DIR="$HOME/surgical-training"
VENV_DIR="$HOME/surgical-venv"
MODEL_PATH="$WORK_DIR/models/best.pt"

# Verificar argumentos
if [ -z "$1" ]; then
    echo "Uso: $0 <caminho_gynsurg_action_3sec> [--upload]"
    echo ""
    echo "Exemplo:"
    echo "  $0 /path/to/GynSurg_Action_3sec"
    echo "  $0 /path/to/GynSurg_Action_3sec --upload"
    exit 1
fi

GYNSURG_PATH="$1"
UPLOAD_TO_S3=false
if [ "$2" == "--upload" ]; then
    UPLOAD_TO_S3=true
fi

# Verificar se diretório existe
if [ ! -d "$GYNSURG_PATH/GynSurg_bleeding_dataset" ]; then
    echo "❌ Dataset de bleeding não encontrado em: $GYNSURG_PATH/GynSurg_bleeding_dataset"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="$WORK_DIR/validation_gynsurg_$TIMESTAMP"

echo "========================================"
echo "  VALIDAÇÃO GYNSURG - SURGICAL VIDEO AI"
echo "========================================"
echo ""
echo "Dataset: $GYNSURG_PATH"
echo "Saída: $OUTPUT_DIR"

# Criar diretórios
mkdir -p "$OUTPUT_DIR"
mkdir -p "$WORK_DIR/models"

# Baixar modelo do S3 se necessário
echo ""
echo "[1/5] Verificando modelo..."
if [ ! -f "$MODEL_PATH" ]; then
    echo "   Baixando modelo do S3..."
    aws s3 cp "s3://$S3_MODELS_BUCKET/trained/best.pt" "$MODEL_PATH"
fi

if [ ! -f "$MODEL_PATH" ]; then
    echo "❌ Modelo não encontrado. Execute o treinamento primeiro."
    exit 1
fi
echo "✅ Modelo: $MODEL_PATH"

# Ativar ambiente virtual
source "$VENV_DIR/bin/activate"

# Processar clips de bleeding
echo ""
echo "[2/5] Processando clips de BLEEDING..."
BLEEDING_DIR="$GYNSURG_PATH/GynSurg_bleeding_dataset/Bleeding"
BLEEDING_OUTPUT="$OUTPUT_DIR/bleeding_results"
mkdir -p "$BLEEDING_OUTPUT"

# Selecionar 10 clips aleatórios para validação rápida
BLEEDING_CLIPS=$(ls "$BLEEDING_DIR"/*.mp4 | shuf | head -10)

for clip in $BLEEDING_CLIPS; do
    clip_name=$(basename "$clip" .mp4)
    echo "   Processando: $clip_name"

    yolo detect predict \
        model="$MODEL_PATH" \
        source="$clip" \
        project="$BLEEDING_OUTPUT" \
        name="$clip_name" \
        exist_ok=True \
        save=True \
        save_txt=True \
        save_conf=True \
        conf=0.3 \
        verbose=False
done

# Processar clips de non-bleeding
echo ""
echo "[3/5] Processando clips de NON-BLEEDING..."
NON_BLEEDING_DIR="$GYNSURG_PATH/GynSurg_bleeding_dataset/Non_bleeding"
NON_BLEEDING_OUTPUT="$OUTPUT_DIR/non_bleeding_results"
mkdir -p "$NON_BLEEDING_OUTPUT"

NON_BLEEDING_CLIPS=$(ls "$NON_BLEEDING_DIR"/*.mp4 | shuf | head -10)

for clip in $NON_BLEEDING_CLIPS; do
    clip_name=$(basename "$clip" .mp4)
    echo "   Processando: $clip_name"

    yolo detect predict \
        model="$MODEL_PATH" \
        source="$clip" \
        project="$NON_BLEEDING_OUTPUT" \
        name="$clip_name" \
        exist_ok=True \
        save=True \
        save_txt=True \
        save_conf=True \
        conf=0.3 \
        verbose=False
done

# Gerar relatório de validação
echo ""
echo "[4/5] Gerando relatório de validação..."

python3 << EOF
import os
import json
from pathlib import Path
from datetime import datetime

output_dir = Path("$OUTPUT_DIR")
bleeding_dir = output_dir / "bleeding_results"
non_bleeding_dir = output_dir / "non_bleeding_results"

def count_detections(results_dir, class_names=["grasper", "blood"]):
    """Conta detecções nos arquivos de labels."""
    stats = {name: 0 for name in class_names}
    stats["total_frames"] = 0
    stats["frames_with_blood"] = 0
    stats["frames_with_grasper"] = 0

    for clip_dir in results_dir.iterdir():
        if not clip_dir.is_dir():
            continue
        labels_dir = clip_dir / "labels"
        if not labels_dir.exists():
            continue

        for label_file in labels_dir.glob("*.txt"):
            stats["total_frames"] += 1
            has_blood = False
            has_grasper = False

            with open(label_file) as f:
                for line in f:
                    parts = line.strip().split()
                    if parts:
                        class_id = int(parts[0])
                        if class_id == 0:
                            stats["grasper"] += 1
                            has_grasper = True
                        elif class_id == 1:
                            stats["blood"] += 1
                            has_blood = True

            if has_blood:
                stats["frames_with_blood"] += 1
            if has_grasper:
                stats["frames_with_grasper"] += 1

    return stats

# Coletar estatísticas
bleeding_stats = count_detections(bleeding_dir)
non_bleeding_stats = count_detections(non_bleeding_dir)

# Calcular métricas
report = {
    "validation_date": datetime.now().isoformat(),
    "model": "$MODEL_PATH",
    "dataset": "GynSurg Action Recognition (Bleeding subset)",
    "bleeding_clips": {
        "clips_processed": 10,
        "total_frames": bleeding_stats["total_frames"],
        "blood_detections": bleeding_stats["blood"],
        "grasper_detections": bleeding_stats["grasper"],
        "frames_with_blood": bleeding_stats["frames_with_blood"],
        "blood_detection_rate": round(bleeding_stats["frames_with_blood"] / max(bleeding_stats["total_frames"], 1) * 100, 2)
    },
    "non_bleeding_clips": {
        "clips_processed": 10,
        "total_frames": non_bleeding_stats["total_frames"],
        "blood_detections": non_bleeding_stats["blood"],
        "grasper_detections": non_bleeding_stats["grasper"],
        "frames_with_blood": non_bleeding_stats["frames_with_blood"],
        "false_positive_rate": round(non_bleeding_stats["frames_with_blood"] / max(non_bleeding_stats["total_frames"], 1) * 100, 2)
    }
}

# Salvar relatório
report_path = output_dir / "validation_report.json"
with open(report_path, "w") as f:
    json.dump(report, f, indent=2)

# Imprimir resumo
print("\n" + "="*50)
print("RELATÓRIO DE VALIDAÇÃO CROSS-DATASET")
print("="*50)
print(f"\nModelo treinado em: CholecSeg8k")
print(f"Validado em: GynSurg (Cirurgias Ginecológicas)")
print(f"\n--- CLIPS COM BLEEDING ---")
print(f"Frames analisados: {bleeding_stats['total_frames']}")
print(f"Detecções de blood: {bleeding_stats['blood']}")
print(f"Detecções de grasper: {bleeding_stats['grasper']}")
print(f"Taxa de detecção de blood: {report['bleeding_clips']['blood_detection_rate']}%")
print(f"\n--- CLIPS SEM BLEEDING ---")
print(f"Frames analisados: {non_bleeding_stats['total_frames']}")
print(f"Detecções de blood (falso positivo): {non_bleeding_stats['blood']}")
print(f"Detecções de grasper: {non_bleeding_stats['grasper']}")
print(f"Taxa de falso positivo: {report['non_bleeding_clips']['false_positive_rate']}%")
print(f"\nRelatório salvo em: {report_path}")
EOF

# Upload para S3 (opcional)
echo ""
if [ "$UPLOAD_TO_S3" = true ]; then
    echo "[5/5] Fazendo upload para S3..."
    aws s3 sync "$OUTPUT_DIR/" "s3://$S3_RESULTS_BUCKET/validation_gynsurg_$TIMESTAMP/" --only-show-errors
    echo "✅ Resultados enviados para S3"
else
    echo "[5/5] Upload para S3 pulado (use --upload para enviar)"
fi

echo ""
echo "========================================"
echo "  VALIDAÇÃO CONCLUÍDA!"
echo "========================================"
echo ""
echo "Resultados em: $OUTPUT_DIR"
echo ""
