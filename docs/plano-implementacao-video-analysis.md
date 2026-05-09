# Plano de Implementação: Análise de Vídeo para Saúde da Mulher

## Overview

Sistema de análise de vídeos médicos utilizando YOLOv8 customizado para detecção de **sangramento anômalo** e **instrumentos cirúrgicos** em procedimentos ginecológicos, com integração a **AWS** (SageMaker, S3, Lambda, CloudWatch) para processamento escalável e geração de alertas em tempo real.

## Status de Decisões

| Item | Status | Decisão/Opções |
|------|--------|----------------|
| **Dataset** | ⏳ PENDENTE | GynSurg (aguardando acesso) OU CholecSeg8k (disponível) |
| **Foco principal** | ⏳ PENDENTE | Sangramento (recomendado) OU Instrumentos |
| **Cloud Provider** | ✅ DECIDIDO | **AWS** (SageMaker + S3 + Lambda) |
| **Infrastructure as Code** | ✅ DECIDIDO | **Terraform** (toda infra AWS via IaC) |
| **Gestão de Custos** | ✅ DECIDIDO | Infra liga/desliga sob demanda + separação treino/inferência |

---

## Current State Analysis

### Recursos Disponíveis
- **CholecSeg8k**: ✅ Baixado (~3.1 GB, 8.080 imagens com segmentação de sangue + instrumentos)
- **GynSurg**: ⏳ Aguardando resposta do email (152 vídeos ginecológicos)

### Estrutura do Projeto (Planejada)
```
Desafio/
├── CLAUDE.md                    # Descrição do desafio
├── cholecseg8k.zip             # Dataset backup (baixado)
├── docs/
│   └── plano-implementacao-video-analysis.md  # Este documento
├── src/                         # Código Python
│   ├── data/                    # Preparação de dados
│   ├── models/                  # Treinamento
│   ├── video/                   # Processamento de vídeo
│   ├── reports/                 # Geração de relatórios
│   └── cloud/                   # Integração AWS
├── terraform/                   # Infraestrutura como Código
│   ├── modules/
│   │   ├── storage/            # S3 buckets (persistente)
│   │   ├── training/           # EC2 GPU (temporário)
│   │   └── inference/          # SageMaker (sob demanda)
│   └── environments/
│       ├── training/           # terraform apply/destroy
│       └── inference/          # terraform apply/destroy
├── scripts/                     # Automação
│   ├── infra-up-training.sh
│   ├── infra-down-training.sh
│   ├── infra-up-inference.sh
│   └── infra-down-inference.sh
├── notebooks/                   # Jupyter/Colab
├── data/                        # Dados locais
├── models/                      # Modelos locais
└── relatorio/                   # Relatório da fase anterior
```

### Requisitos do Desafio (CLAUDE.md)
1. ✅ Análise de vídeo especializada para saúde da mulher
2. ✅ YOLOv8 customizado para detecção (sangramento OU instrumentos)
3. ✅ Relatórios automáticos especializados
4. ✅ Integração com serviços em nuvem (AWS)
5. ✅ Vídeo demonstrativo de até 15 minutos

---

## Desired End State

### Sistema Funcional
1. **Modelo YOLOv8** treinado para detectar:
   - Sangramento anômalo durante procedimentos cirúrgicos
   - E/OU instrumentos cirúrgicos ginecológicos
2. **Pipeline de processamento** de vídeo em nuvem
3. **Sistema de alertas** para anomalias detectadas
4. **Relatórios automáticos** com timestamps e screenshots

### Entregáveis Finais
- [ ] Código-fonte completo no repositório Git
- [ ] Modelo YOLOv8 treinado (.pt)
- [ ] Relatório técnico em PDF
- [ ] Vídeo demonstrativo (≤15 min) no YouTube/Vimeo

### Verificação do End State
```bash
# 1. Modelo treinado existe e funciona
python detect.py --source video_teste.mp4 --weights best.pt

# 2. Pipeline de nuvem responde
curl -X POST $ENDPOINT_URL -d @frame.jpg

# 3. Relatório gerado
ls -la reports/relatorio_*.pdf
```

---

## What We're NOT Doing

- ❌ Análise de áudio (fora do escopo deste módulo)
- ❌ Detecção de emoções faciais (privacidade)
- ❌ Sistema de produção hospitalar real (apenas PoC acadêmico)
- ❌ Treinamento com dados de pacientes reais (apenas datasets públicos)
- ❌ Deploy em tempo real 24/7 (custo proibitivo para PoC)
- ❌ Integração com Azure (decisão: usar AWS)

---

## Implementation Approach

### Estratégia Geral
1. **Preparar dados** do dataset escolhido (GynSurg ou CholecSeg8k)
2. **Provisionar infra de treinamento** via Terraform (GPU potente, temporária)
3. **Treinar YOLOv8** na AWS ou Google Colab
4. **Destruir infra de treinamento** após treino (economia)
5. **Provisionar infra de inferência** via Terraform (GPU menor, sob demanda)
6. **Criar pipeline** de processamento de vídeo
7. **Gerar relatórios** e demonstração
8. **Desligar infra** quando não estiver em uso

### Filosofia de Custos
- **Infra de Treinamento**: GPU potente (p3.2xlarge ~$3/hora), usada por ~4-6 horas, depois destruída
- **Infra de Inferência**: GPU menor (g4dn.xlarge ~$0.50/hora), ligada apenas para demos
- **Tudo via Terraform**: `terraform apply` para ligar, `terraform destroy` para desligar

### Arquitetura Proposta

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ARQUITETURA DO SISTEMA                       │
│                    (Gerenciada 100% via Terraform)                   │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────────────────┐
│   Vídeo de   │────▶│  Extração    │────▶│  Modelo YOLOv8 Custom    │
│   Entrada    │     │  de Frames   │     │  (Sangramento/Instrum.)  │
└──────────────┘     └──────────────┘     └────────────┬─────────────┘
                                                       │
                                                       ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────────────────┐
│  Relatório   │◀────│  Sistema de  │◀────│  Análise de Detecções    │
│  Automático  │     │   Alertas    │     │  (threshold, contagem)   │
└──────────────┘     └──────────────┘     └──────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    TERRAFORM - INFRA TREINAMENTO                     │
│                    (terraform apply/destroy)                         │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  EC2 p3.2xlarge (GPU V100)  │  S3 (datasets)  │  IAM Roles     │ │
│  │  ~$3.06/hora - TEMPORÁRIO   │  (persistente)  │                │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    TERRAFORM - INFRA INFERÊNCIA                      │
│                    (terraform apply/destroy)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │
│  │  Amazon S3  │  │  SageMaker  │  │   Lambda    │  │ CloudWatch │  │
│  │  (Storage)  │  │  Endpoint   │  │ (Trigger)   │  │  (Alerts)  │  │
│  │ persistente │  │ g4dn.xlarge │  │             │  │            │  │
│  │             │  │ ~$0.53/hora │  │             │  │            │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### Estrutura Terraform
```
terraform/
├── modules/
│   ├── storage/           # S3 buckets (sempre ativo)
│   ├── training/          # EC2 GPU para treinamento (temporário)
│   └── inference/         # SageMaker endpoint (sob demanda)
├── environments/
│   ├── training/          # terraform apply/destroy para treinar
│   └── inference/         # terraform apply/destroy para inferir
├── variables.tf
├── outputs.tf
└── README.md
```

---

## Phase 1: Preparação do Ambiente e Dataset

### Overview
Configurar ambiente de desenvolvimento, extrair e preparar o dataset escolhido para treinamento do YOLOv8.

### Changes Required:

#### 1.1. Estrutura de Diretórios
**Criar estrutura padrão para projeto YOLOv8 + Terraform:**

```bash
# Código Python
mkdir -p src/{data,models,utils,cloud}
mkdir -p data/{raw,processed,yolo_format}
mkdir -p models/{trained,exported}
mkdir -p notebooks
mkdir -p reports
mkdir -p videos/{input,output}

# Terraform
mkdir -p terraform/modules/{storage,training,inference}
mkdir -p terraform/environments/{training,inference}
mkdir -p scripts  # Scripts de automação
```

#### 1.2. Dependências do Sistema
**Instalar antes de começar:**

```bash
# Terraform (macOS)
brew install terraform

# Terraform (Linux)
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# AWS CLI
brew install awscli  # macOS
# ou: pip install awscli

# Configurar AWS
aws configure  # Inserir Access Key, Secret Key, Region (us-east-1)
```

#### 1.3. Arquivo de Dependências Python
**File**: `requirements.txt`

```txt
# Core ML
ultralytics>=8.0.0
torch>=2.0.0
torchvision>=0.15.0

# Data Processing
opencv-python>=4.8.0
numpy>=1.24.0
pandas>=2.0.0
Pillow>=10.0.0

# Visualization
matplotlib>=3.7.0
seaborn>=0.12.0

# AWS SDK
boto3>=1.28.0
sagemaker>=2.200.0

# Utilities
tqdm>=4.65.0
python-dotenv>=1.0.0
pyyaml>=6.0

# Reports
reportlab>=4.0.0
fpdf2>=2.7.0
```

#### 1.4. Script de Preparação do CholecSeg8k
**File**: `src/data/prepare_cholecseg8k.py`

```python
"""
Prepara o dataset CholecSeg8k para treinamento YOLOv8.
Extrai máscaras de sangue e/ou instrumentos e converte para formato YOLO.
"""

import cv2
import numpy as np
from pathlib import Path
from tqdm import tqdm
import json
import shutil

# Classes do CholecSeg8k relevantes para o projeto
CLASSES = {
    'blood': {'id': 7, 'yolo_id': 0, 'color': (36, 36, 36)},
    'grasper': {'id': 5, 'yolo_id': 1, 'color': (49, 49, 49)},
    'l_hook': {'id': 9, 'yolo_id': 2, 'color': (50, 50, 50)},
}

def mask_to_yolo_bbox(mask: np.ndarray, class_id: int) -> list:
    """Converte máscara binária para bounding boxes YOLO format."""
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    bboxes = []
    h, w = mask.shape

    for contour in contours:
        if cv2.contourArea(contour) < 100:  # Ignorar áreas muito pequenas
            continue

        x, y, bw, bh = cv2.boundingRect(contour)

        # Converter para formato YOLO (normalizado, centro)
        x_center = (x + bw / 2) / w
        y_center = (y + bh / 2) / h
        width = bw / w
        height = bh / h

        bboxes.append(f"{class_id} {x_center:.6f} {y_center:.6f} {width:.6f} {height:.6f}")

    return bboxes


def process_cholecseg8k(
    input_path: Path,
    output_path: Path,
    target_classes: list = ['blood'],
    train_ratio: float = 0.8,
    val_ratio: float = 0.15
):
    """
    Processa CholecSeg8k e gera dataset no formato YOLO.

    Args:
        input_path: Caminho para o CholecSeg8k extraído
        output_path: Caminho de saída para dataset YOLO
        target_classes: Lista de classes para extrair ('blood', 'grasper', 'l_hook')
        train_ratio: Proporção para treino
        val_ratio: Proporção para validação
    """
    input_path = Path(input_path)
    output_path = Path(output_path)

    # Criar estrutura YOLO
    for split in ['train', 'val', 'test']:
        (output_path / 'images' / split).mkdir(parents=True, exist_ok=True)
        (output_path / 'labels' / split).mkdir(parents=True, exist_ok=True)

    # Coletar todos os frames com as classes alvo
    frames_with_target = []

    print("Scanning frames for target classes...")
    for video_dir in tqdm(sorted(input_path.iterdir())):
        if not video_dir.is_dir():
            continue

        for mask_file in video_dir.glob("*_watershed_mask.png"):
            mask = cv2.imread(str(mask_file), cv2.IMREAD_GRAYSCALE)

            has_target = False
            for cls_name in target_classes:
                if cls_name in CLASSES:
                    cls_id = CLASSES[cls_name]['id']
                    if (mask == cls_id).any():
                        has_target = True
                        break

            if has_target:
                original_name = mask_file.name.replace("_watershed_mask", "")
                original_file = mask_file.parent / original_name
                if original_file.exists():
                    frames_with_target.append({
                        'image': original_file,
                        'mask': mask_file,
                        'video': video_dir.name
                    })

    print(f"Found {len(frames_with_target)} frames with target classes")

    # Shuffle e split
    np.random.seed(42)
    np.random.shuffle(frames_with_target)

    n_total = len(frames_with_target)
    n_train = int(n_total * train_ratio)
    n_val = int(n_total * val_ratio)

    splits = {
        'train': frames_with_target[:n_train],
        'val': frames_with_target[n_train:n_train + n_val],
        'test': frames_with_target[n_train + n_val:]
    }

    # Processar cada split
    stats = {split: {'images': 0, 'objects': {cls: 0 for cls in target_classes}}
             for split in splits}

    for split_name, frames in splits.items():
        print(f"\nProcessing {split_name} split ({len(frames)} frames)...")

        for frame_info in tqdm(frames):
            # Copiar imagem
            img_name = f"{frame_info['video']}_{frame_info['image'].name}"
            shutil.copy(
                frame_info['image'],
                output_path / 'images' / split_name / img_name
            )

            # Processar máscara e gerar labels
            mask = cv2.imread(str(frame_info['mask']), cv2.IMREAD_GRAYSCALE)
            labels = []

            for cls_name in target_classes:
                if cls_name not in CLASSES:
                    continue

                cls_info = CLASSES[cls_name]
                binary_mask = (mask == cls_info['id']).astype(np.uint8) * 255
                bboxes = mask_to_yolo_bbox(binary_mask, cls_info['yolo_id'])
                labels.extend(bboxes)
                stats[split_name]['objects'][cls_name] += len(bboxes)

            # Salvar labels
            label_name = img_name.replace('.png', '.txt')
            with open(output_path / 'labels' / split_name / label_name, 'w') as f:
                f.write('\n'.join(labels))

            stats[split_name]['images'] += 1

    # Criar arquivo data.yaml
    class_names = [cls for cls in target_classes if cls in CLASSES]
    data_yaml = {
        'path': str(output_path.absolute()),
        'train': 'images/train',
        'val': 'images/val',
        'test': 'images/test',
        'nc': len(class_names),
        'names': class_names
    }

    with open(output_path / 'data.yaml', 'w') as f:
        import yaml
        yaml.dump(data_yaml, f, default_flow_style=False)

    # Salvar estatísticas
    with open(output_path / 'stats.json', 'w') as f:
        json.dump(stats, f, indent=2)

    print("\n" + "="*50)
    print("Dataset preparation complete!")
    print("="*50)
    for split_name, split_stats in stats.items():
        print(f"\n{split_name.upper()}:")
        print(f"  Images: {split_stats['images']}")
        for cls_name, count in split_stats['objects'].items():
            print(f"  {cls_name}: {count} objects")

    return stats


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Prepare CholecSeg8k for YOLOv8')
    parser.add_argument('--input', type=str, required=True, help='Path to extracted CholecSeg8k')
    parser.add_argument('--output', type=str, required=True, help='Output path for YOLO dataset')
    parser.add_argument('--classes', nargs='+', default=['blood'],
                        choices=['blood', 'grasper', 'l_hook'],
                        help='Classes to extract')

    args = parser.parse_args()

    process_cholecseg8k(
        input_path=Path(args.input),
        output_path=Path(args.output),
        target_classes=args.classes
    )
```

#### 1.5. Script de Preparação do GynSurg (se disponível)
**File**: `src/data/prepare_gynsurg.py`

```python
"""
Prepara o dataset GynSurg para treinamento YOLOv8.
Usa anotações temporais de bleeding para extrair frames relevantes.
"""

import cv2
import numpy as np
from pathlib import Path
from tqdm import tqdm
import json
import pandas as pd

# TODO: Ajustar conforme estrutura real do GynSurg após acesso
GYNSURG_CLASSES = {
    'bleeding': {'yolo_id': 0},
    # Instrumentos do GynSurg (21 classes)
    'grasper': {'yolo_id': 1},
    'suture_carrier': {'yolo_id': 2},
    'scissor': {'yolo_id': 3},
    'irrigator': {'yolo_id': 4},
    'clip_applier': {'yolo_id': 5},
    'needle': {'yolo_id': 6},
    'trocar': {'yolo_id': 7},
    'needle_holder': {'yolo_id': 8},
    'bipolar_forcep': {'yolo_id': 9},
    'sealer_divider': {'yolo_id': 10},
    'hook': {'yolo_id': 11},
    # ... adicionar mais conforme documentação
}


def extract_frames_with_bleeding(
    video_path: Path,
    annotations_path: Path,
    output_path: Path,
    fps_sample: int = 1  # Extrair 1 frame por segundo
):
    """
    Extrai frames de vídeos do GynSurg onde há anotação de bleeding.

    Args:
        video_path: Caminho para o vídeo
        annotations_path: Caminho para arquivo de anotações temporais
        output_path: Caminho de saída
        fps_sample: Taxa de amostragem de frames
    """
    # TODO: Implementar após receber acesso ao GynSurg
    # A estrutura de anotações precisa ser verificada

    raise NotImplementedError(
        "Aguardando acesso ao GynSurg para implementar. "
        "Use prepare_cholecseg8k.py como alternativa."
    )


def process_gynsurg_segmentation(
    segmentation_path: Path,
    output_path: Path,
    target_classes: list = ['bleeding']
):
    """
    Processa frames com segmentação pixel-level do GynSurg.
    Similar ao processamento do CholecSeg8k.
    """
    # TODO: Implementar após receber acesso ao GynSurg
    pass


if __name__ == "__main__":
    print("Script para GynSurg - aguardando acesso ao dataset")
    print("Use prepare_cholecseg8k.py como alternativa")
```

### Success Criteria:

#### Automated Verification:
- [ ] Terraform instalado: `terraform version`
- [ ] AWS CLI configurado: `aws sts get-caller-identity`
- [ ] Estrutura de diretórios criada: `ls -la src/ terraform/ scripts/`
- [ ] Dependências instaladas: `pip install -r requirements.txt`
- [ ] Dataset extraído: `unzip cholecseg8k.zip -d data/raw/`
- [ ] Script de preparação executa: `python src/data/prepare_cholecseg8k.py --help`
- [ ] Dataset YOLO gerado: `ls data/yolo_format/`

#### Manual Verification:
- [ ] Verificar visualmente algumas imagens processadas
- [ ] Confirmar que labels YOLO estão corretos (visualizar bounding boxes)
- [ ] Validar proporções de train/val/test
- [ ] Testar `terraform init` nos módulos

**Implementation Note**: Após completar esta fase, pause para confirmar que o dataset foi preparado corretamente antes de prosseguir para o treinamento.

---

## Phase 2: Treinamento do Modelo YOLOv8

### Overview
Treinar modelo YOLOv8 customizado para detecção de sangramento e/ou instrumentos cirúrgicos usando o dataset preparado.

### Changes Required:

#### 2.1. Notebook de Treinamento (Google Colab)
**File**: `notebooks/train_yolov8_surgical.ipynb`

```python
# Célula 1: Setup
"""
# Treinamento YOLOv8 para Detecção em Vídeos Cirúrgicos
## FIAP - Pós-Graduação em IA - Fase 4

Este notebook treina um modelo YOLOv8 para detectar:
- Opção A: Sangramento anômalo
- Opção B: Instrumentos cirúrgicos
- Opção C: Ambos
"""

# Instalar dependências
!pip install ultralytics opencv-python-headless

# Verificar GPU
import torch
print(f"GPU disponível: {torch.cuda.is_available()}")
print(f"GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A'}")
```

```python
# Célula 2: Upload do Dataset
from google.colab import drive
drive.mount('/content/drive')

# OU upload direto
from google.colab import files
# uploaded = files.upload()  # Para arquivos pequenos

# Configurar paths
DATASET_PATH = "/content/dataset"  # Ajustar conforme upload
```

```python
# Célula 3: Configuração do Treinamento
from ultralytics import YOLO

# Configurações
CONFIG = {
    'model_size': 'yolov8m',  # n, s, m, l, x (m é bom equilíbrio)
    'epochs': 100,
    'imgsz': 640,
    'batch': 16,  # Reduzir se GPU memory error
    'patience': 20,  # Early stopping
    'device': 0,  # GPU

    # Data augmentation
    'augment': True,
    'mosaic': 1.0,
    'mixup': 0.1,
    'copy_paste': 0.1,

    # Otimizações
    'optimizer': 'AdamW',
    'lr0': 0.001,
    'lrf': 0.01,
    'weight_decay': 0.0005,
}

# Carregar modelo base
model = YOLO(f"{CONFIG['model_size']}.pt")
```

```python
# Célula 4: Treinamento
results = model.train(
    data=f"{DATASET_PATH}/data.yaml",
    epochs=CONFIG['epochs'],
    imgsz=CONFIG['imgsz'],
    batch=CONFIG['batch'],
    patience=CONFIG['patience'],
    device=CONFIG['device'],

    # Augmentation
    augment=CONFIG['augment'],
    mosaic=CONFIG['mosaic'],
    mixup=CONFIG['mixup'],
    copy_paste=CONFIG['copy_paste'],

    # Optimizer
    optimizer=CONFIG['optimizer'],
    lr0=CONFIG['lr0'],
    lrf=CONFIG['lrf'],
    weight_decay=CONFIG['weight_decay'],

    # Projeto
    project='surgical_detection',
    name='blood_detection_v1',  # ou 'instrument_detection_v1'

    # Callbacks
    save=True,
    save_period=10,
    plots=True,
    verbose=True,
)
```

```python
# Célula 5: Validação
# Avaliar no conjunto de teste
metrics = model.val(data=f"{DATASET_PATH}/data.yaml", split='test')

print(f"mAP50: {metrics.box.map50:.4f}")
print(f"mAP50-95: {metrics.box.map:.4f}")
print(f"Precision: {metrics.box.mp:.4f}")
print(f"Recall: {metrics.box.mr:.4f}")
```

```python
# Célula 6: Testar em Imagem
import cv2
from google.colab.patches import cv2_imshow

# Carregar melhor modelo
best_model = YOLO('surgical_detection/blood_detection_v1/weights/best.pt')

# Testar em uma imagem
test_image = f"{DATASET_PATH}/images/test/sample.png"  # Ajustar
results = best_model(test_image)

# Visualizar
annotated = results[0].plot()
cv2_imshow(annotated)
```

```python
# Célula 7: Exportar Modelo
# Exportar para diferentes formatos

# ONNX (para deploy em cloud)
best_model.export(format='onnx', dynamic=True, simplify=True)

# TorchScript (alternativa)
best_model.export(format='torchscript')

# Salvar no Drive
!cp surgical_detection/blood_detection_v1/weights/best.pt /content/drive/MyDrive/FIAP/
!cp surgical_detection/blood_detection_v1/weights/best.onnx /content/drive/MyDrive/FIAP/

print("Modelos exportados com sucesso!")
```

#### 2.2. Script de Treinamento Local (alternativa)
**File**: `src/models/train.py`

```python
"""
Script de treinamento YOLOv8 para execução local.
Requer GPU com pelo menos 8GB VRAM.
"""

from ultralytics import YOLO
from pathlib import Path
import yaml
import argparse
from datetime import datetime


def train_model(
    data_yaml: str,
    model_size: str = 'yolov8m',
    epochs: int = 100,
    batch_size: int = 16,
    img_size: int = 640,
    device: str = '0',
    project_name: str = 'surgical_detection'
):
    """
    Treina modelo YOLOv8 para detecção cirúrgica.
    """
    # Gerar nome único para o experimento
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_name = f"run_{timestamp}"

    # Carregar modelo base
    model = YOLO(f"{model_size}.pt")

    # Treinar
    results = model.train(
        data=data_yaml,
        epochs=epochs,
        imgsz=img_size,
        batch=batch_size,
        device=device,
        project=project_name,
        name=run_name,

        # Augmentation otimizada para imagens médicas
        augment=True,
        mosaic=0.8,
        mixup=0.1,
        hsv_h=0.01,  # Menos variação de cor (imagens médicas são consistentes)
        hsv_s=0.3,
        hsv_v=0.3,
        degrees=10,  # Rotação limitada
        translate=0.1,
        scale=0.3,
        flipud=0.0,  # Não inverter verticalmente (cirurgias têm orientação)
        fliplr=0.5,

        # Early stopping
        patience=20,

        # Salvar checkpoints
        save=True,
        save_period=10,

        # Logs
        plots=True,
        verbose=True,
    )

    # Avaliar
    metrics = model.val()

    print("\n" + "="*50)
    print("TRAINING COMPLETE")
    print("="*50)
    print(f"Best model: {project_name}/{run_name}/weights/best.pt")
    print(f"mAP50: {metrics.box.map50:.4f}")
    print(f"mAP50-95: {metrics.box.map:.4f}")

    return model, results, metrics


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=str, required=True, help='Path to data.yaml')
    parser.add_argument('--model', type=str, default='yolov8m', help='Model size')
    parser.add_argument('--epochs', type=int, default=100)
    parser.add_argument('--batch', type=int, default=16)
    parser.add_argument('--device', type=str, default='0')

    args = parser.parse_args()

    train_model(
        data_yaml=args.data,
        model_size=args.model,
        epochs=args.epochs,
        batch_size=args.batch,
        device=args.device
    )
```

### Success Criteria:

#### Automated Verification:
- [ ] Treinamento completa sem erros
- [ ] Modelo salvo: `ls models/trained/best.pt`
- [ ] Métricas geradas: `cat surgical_detection/*/results.csv`
- [ ] mAP50 > 0.5 (threshold mínimo aceitável)
- [ ] Modelo exportado para ONNX: `ls models/exported/best.onnx`

#### Manual Verification:
- [ ] Visualizar curvas de loss (devem convergir)
- [ ] Testar modelo em 5-10 imagens manualmente
- [ ] Verificar se detecções fazem sentido visualmente
- [ ] Confirmar que não há overfitting (val_loss próximo de train_loss)

**Implementation Note**: O treinamento pode levar 2-6 horas dependendo do dataset e GPU. Monitore as métricas de validação.

---

## Phase 3: Pipeline de Processamento de Vídeo

### Overview
Criar pipeline para processar vídeos cirúrgicos, detectar anomalias e gerar alertas.

### Changes Required:

#### 3.1. Processador de Vídeo
**File**: `src/video/processor.py`

```python
"""
Pipeline de processamento de vídeo para detecção cirúrgica.
"""

import cv2
import numpy as np
from pathlib import Path
from ultralytics import YOLO
from dataclasses import dataclass, field
from typing import List, Optional, Tuple
from datetime import timedelta
import json
from tqdm import tqdm


@dataclass
class Detection:
    """Representa uma detecção em um frame."""
    frame_number: int
    timestamp: float
    class_name: str
    confidence: float
    bbox: Tuple[int, int, int, int]  # x1, y1, x2, y2
    area: float


@dataclass
class Alert:
    """Representa um alerta gerado pelo sistema."""
    timestamp: float
    alert_type: str
    severity: str  # 'low', 'medium', 'high', 'critical'
    message: str
    detections: List[Detection] = field(default_factory=list)
    frame_path: Optional[str] = None


class SurgicalVideoProcessor:
    """
    Processa vídeos cirúrgicos para detectar sangramento e/ou instrumentos.
    """

    # Thresholds para alertas
    BLOOD_AREA_THRESHOLD_LOW = 0.01  # 1% da área do frame
    BLOOD_AREA_THRESHOLD_MEDIUM = 0.03  # 3%
    BLOOD_AREA_THRESHOLD_HIGH = 0.05  # 5%
    BLOOD_AREA_THRESHOLD_CRITICAL = 0.10  # 10%

    CONFIDENCE_THRESHOLD = 0.5

    def __init__(
        self,
        model_path: str,
        output_dir: str = "output",
        save_frames: bool = True,
        alert_callback: Optional[callable] = None
    ):
        """
        Inicializa o processador.

        Args:
            model_path: Caminho para o modelo YOLOv8 treinado
            output_dir: Diretório para salvar outputs
            save_frames: Se deve salvar frames com detecções
            alert_callback: Função chamada quando um alerta é gerado
        """
        self.model = YOLO(model_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.save_frames = save_frames
        self.alert_callback = alert_callback

        # Resultados
        self.detections: List[Detection] = []
        self.alerts: List[Alert] = []

    def process_video(
        self,
        video_path: str,
        sample_fps: int = 1,
        start_time: float = 0,
        end_time: Optional[float] = None,
        show_progress: bool = True
    ) -> dict:
        """
        Processa um vídeo e retorna estatísticas.

        Args:
            video_path: Caminho para o vídeo
            sample_fps: Frames por segundo para analisar
            start_time: Tempo inicial em segundos
            end_time: Tempo final em segundos (None = até o fim)
            show_progress: Mostrar barra de progresso
        """
        video_path = Path(video_path)
        cap = cv2.VideoCapture(str(video_path))

        if not cap.isOpened():
            raise ValueError(f"Não foi possível abrir o vídeo: {video_path}")

        # Propriedades do vídeo
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        duration = total_frames / fps
        frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        frame_area = frame_width * frame_height

        print(f"Vídeo: {video_path.name}")
        print(f"Resolução: {frame_width}x{frame_height}")
        print(f"FPS: {fps:.2f}, Duração: {duration:.2f}s, Frames: {total_frames}")

        # Calcular frames para processar
        frame_interval = int(fps / sample_fps)
        start_frame = int(start_time * fps)
        end_frame = int(end_time * fps) if end_time else total_frames

        frames_to_process = range(start_frame, end_frame, frame_interval)

        # Criar subdiretório para este vídeo
        video_output_dir = self.output_dir / video_path.stem
        video_output_dir.mkdir(exist_ok=True)

        # Processar frames
        self.detections = []
        self.alerts = []

        iterator = tqdm(frames_to_process, desc="Processando") if show_progress else frames_to_process

        for frame_idx in iterator:
            cap.set(cv2.CAP_PROP_POS_FRAMES, frame_idx)
            ret, frame = cap.read()

            if not ret:
                continue

            timestamp = frame_idx / fps

            # Executar detecção
            results = self.model(frame, verbose=False, conf=self.CONFIDENCE_THRESHOLD)

            # Processar detecções
            frame_detections = []
            total_blood_area = 0

            for result in results:
                boxes = result.boxes

                for i, box in enumerate(boxes):
                    cls_id = int(box.cls[0])
                    cls_name = self.model.names[cls_id]
                    conf = float(box.conf[0])
                    x1, y1, x2, y2 = map(int, box.xyxy[0])

                    detection_area = (x2 - x1) * (y2 - y1) / frame_area

                    detection = Detection(
                        frame_number=frame_idx,
                        timestamp=timestamp,
                        class_name=cls_name,
                        confidence=conf,
                        bbox=(x1, y1, x2, y2),
                        area=detection_area
                    )

                    frame_detections.append(detection)
                    self.detections.append(detection)

                    if cls_name == 'blood':
                        total_blood_area += detection_area

            # Verificar se deve gerar alerta
            if total_blood_area > 0:
                alert = self._generate_blood_alert(
                    timestamp, total_blood_area, frame_detections
                )
                if alert:
                    self.alerts.append(alert)

                    # Salvar frame com alerta
                    if self.save_frames:
                        annotated = results[0].plot()
                        frame_path = video_output_dir / f"alert_{frame_idx:06d}.jpg"
                        cv2.imwrite(str(frame_path), annotated)
                        alert.frame_path = str(frame_path)

                    # Callback
                    if self.alert_callback:
                        self.alert_callback(alert)

        cap.release()

        # Gerar estatísticas
        stats = self._generate_stats(video_path.name, duration)

        # Salvar resultados
        self._save_results(video_output_dir, stats)

        return stats

    def _generate_blood_alert(
        self,
        timestamp: float,
        blood_area: float,
        detections: List[Detection]
    ) -> Optional[Alert]:
        """Gera alerta baseado na área de sangramento detectada."""

        if blood_area >= self.BLOOD_AREA_THRESHOLD_CRITICAL:
            severity = 'critical'
            message = f"CRÍTICO: Sangramento extenso detectado ({blood_area*100:.1f}% da área)"
        elif blood_area >= self.BLOOD_AREA_THRESHOLD_HIGH:
            severity = 'high'
            message = f"ALTO: Sangramento significativo detectado ({blood_area*100:.1f}% da área)"
        elif blood_area >= self.BLOOD_AREA_THRESHOLD_MEDIUM:
            severity = 'medium'
            message = f"MÉDIO: Sangramento moderado detectado ({blood_area*100:.1f}% da área)"
        elif blood_area >= self.BLOOD_AREA_THRESHOLD_LOW:
            severity = 'low'
            message = f"BAIXO: Sangramento leve detectado ({blood_area*100:.1f}% da área)"
        else:
            return None

        return Alert(
            timestamp=timestamp,
            alert_type='bleeding',
            severity=severity,
            message=message,
            detections=[d for d in detections if d.class_name == 'blood']
        )

    def _generate_stats(self, video_name: str, duration: float) -> dict:
        """Gera estatísticas do processamento."""

        blood_detections = [d for d in self.detections if d.class_name == 'blood']
        instrument_detections = [d for d in self.detections if d.class_name != 'blood']

        return {
            'video': video_name,
            'duration_seconds': duration,
            'total_detections': len(self.detections),
            'blood_detections': len(blood_detections),
            'instrument_detections': len(instrument_detections),
            'alerts': {
                'total': len(self.alerts),
                'critical': len([a for a in self.alerts if a.severity == 'critical']),
                'high': len([a for a in self.alerts if a.severity == 'high']),
                'medium': len([a for a in self.alerts if a.severity == 'medium']),
                'low': len([a for a in self.alerts if a.severity == 'low']),
            },
            'blood_timeline': [
                {
                    'timestamp': d.timestamp,
                    'timestamp_formatted': str(timedelta(seconds=int(d.timestamp))),
                    'area_percent': d.area * 100,
                    'confidence': d.confidence
                }
                for d in blood_detections
            ],
            'alert_timeline': [
                {
                    'timestamp': a.timestamp,
                    'timestamp_formatted': str(timedelta(seconds=int(a.timestamp))),
                    'severity': a.severity,
                    'message': a.message,
                    'frame_path': a.frame_path
                }
                for a in self.alerts
            ]
        }

    def _save_results(self, output_dir: Path, stats: dict):
        """Salva resultados em JSON."""
        with open(output_dir / 'results.json', 'w', encoding='utf-8') as f:
            json.dump(stats, f, indent=2, ensure_ascii=False)

        print(f"\nResultados salvos em: {output_dir}")
        print(f"Total de alertas: {stats['alerts']['total']}")
        if stats['alerts']['critical'] > 0:
            print(f"  ⚠️  ALERTAS CRÍTICOS: {stats['alerts']['critical']}")


# Exemplo de uso
if __name__ == "__main__":
    processor = SurgicalVideoProcessor(
        model_path="models/trained/best.pt",
        output_dir="output/video_analysis"
    )

    stats = processor.process_video(
        video_path="videos/input/test_surgery.mp4",
        sample_fps=1  # Analisar 1 frame por segundo
    )

    print(json.dumps(stats, indent=2))
```

#### 3.2. Gerador de Relatórios
**File**: `src/reports/generator.py`

```python
"""
Gerador de relatórios automáticos para análise de vídeos cirúrgicos.
"""

from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import json

from fpdf import FPDF


class SurgicalReportGenerator:
    """Gera relatórios PDF a partir dos resultados da análise."""

    def __init__(self, output_dir: str = "reports"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def generate_report(
        self,
        stats: Dict,
        title: str = "Relatório de Análise de Vídeo Cirúrgico",
        include_frames: bool = True
    ) -> str:
        """
        Gera relatório PDF completo.

        Args:
            stats: Estatísticas geradas pelo SurgicalVideoProcessor
            title: Título do relatório
            include_frames: Incluir frames de alertas no relatório

        Returns:
            Caminho do arquivo PDF gerado
        """
        pdf = FPDF()
        pdf.set_auto_page_break(auto=True, margin=15)

        # Página de capa
        pdf.add_page()
        self._add_cover_page(pdf, title, stats)

        # Resumo executivo
        pdf.add_page()
        self._add_executive_summary(pdf, stats)

        # Timeline de alertas
        if stats['alerts']['total'] > 0:
            pdf.add_page()
            self._add_alerts_section(pdf, stats)

        # Frames de alertas (se houver)
        if include_frames and stats.get('alert_timeline'):
            self._add_alert_frames(pdf, stats)

        # Estatísticas detalhadas
        pdf.add_page()
        self._add_detailed_stats(pdf, stats)

        # Salvar
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        video_name = Path(stats['video']).stem
        output_path = self.output_dir / f"relatorio_{video_name}_{timestamp}.pdf"

        pdf.output(str(output_path))

        print(f"Relatório gerado: {output_path}")
        return str(output_path)

    def _add_cover_page(self, pdf: FPDF, title: str, stats: Dict):
        """Adiciona página de capa."""
        pdf.set_font('Helvetica', 'B', 24)
        pdf.ln(60)
        pdf.cell(0, 10, title, ln=True, align='C')

        pdf.set_font('Helvetica', '', 14)
        pdf.ln(20)
        pdf.cell(0, 10, f"Vídeo: {stats['video']}", ln=True, align='C')
        pdf.cell(0, 10, f"Duração: {timedelta(seconds=int(stats['duration_seconds']))}", ln=True, align='C')

        pdf.ln(20)
        pdf.cell(0, 10, f"Data da análise: {datetime.now().strftime('%d/%m/%Y %H:%M')}", ln=True, align='C')

        # Logo/Instituição
        pdf.ln(40)
        pdf.set_font('Helvetica', 'I', 12)
        pdf.cell(0, 10, "FIAP - Pós-Graduação em Inteligência Artificial", ln=True, align='C')
        pdf.cell(0, 10, "Tech Challenge - Fase 4", ln=True, align='C')

    def _add_executive_summary(self, pdf: FPDF, stats: Dict):
        """Adiciona resumo executivo."""
        pdf.set_font('Helvetica', 'B', 18)
        pdf.cell(0, 10, "Resumo Executivo", ln=True)
        pdf.ln(5)

        pdf.set_font('Helvetica', '', 12)

        # Box de alertas críticos
        if stats['alerts']['critical'] > 0:
            pdf.set_fill_color(255, 200, 200)
            pdf.cell(0, 10, f"⚠️ {stats['alerts']['critical']} ALERTAS CRÍTICOS DETECTADOS",
                    ln=True, fill=True, align='C')
            pdf.ln(5)

        # Estatísticas principais
        summary = [
            f"Total de detecções: {stats['total_detections']}",
            f"Detecções de sangramento: {stats['blood_detections']}",
            f"Detecções de instrumentos: {stats['instrument_detections']}",
            "",
            "Distribuição de alertas:",
            f"  • Críticos: {stats['alerts']['critical']}",
            f"  • Altos: {stats['alerts']['high']}",
            f"  • Médios: {stats['alerts']['medium']}",
            f"  • Baixos: {stats['alerts']['low']}",
        ]

        for line in summary:
            pdf.cell(0, 8, line, ln=True)

    def _add_alerts_section(self, pdf: FPDF, stats: Dict):
        """Adiciona seção de timeline de alertas."""
        pdf.set_font('Helvetica', 'B', 18)
        pdf.cell(0, 10, "Timeline de Alertas", ln=True)
        pdf.ln(5)

        pdf.set_font('Helvetica', '', 10)

        for alert in stats['alert_timeline']:
            # Cor baseada na severidade
            if alert['severity'] == 'critical':
                pdf.set_fill_color(255, 100, 100)
            elif alert['severity'] == 'high':
                pdf.set_fill_color(255, 180, 100)
            elif alert['severity'] == 'medium':
                pdf.set_fill_color(255, 255, 150)
            else:
                pdf.set_fill_color(200, 255, 200)

            pdf.cell(30, 8, alert['timestamp_formatted'], border=1)
            pdf.cell(20, 8, alert['severity'].upper(), border=1, fill=True)
            pdf.multi_cell(0, 8, alert['message'], border=1)
            pdf.ln(2)

    def _add_alert_frames(self, pdf: FPDF, stats: Dict):
        """Adiciona frames de alertas ao relatório."""
        pdf.add_page()
        pdf.set_font('Helvetica', 'B', 18)
        pdf.cell(0, 10, "Frames de Alertas", ln=True)
        pdf.ln(5)

        for alert in stats['alert_timeline']:
            if alert.get('frame_path') and Path(alert['frame_path']).exists():
                pdf.set_font('Helvetica', 'B', 10)
                pdf.cell(0, 8, f"[{alert['timestamp_formatted']}] {alert['severity'].upper()}", ln=True)

                try:
                    pdf.image(alert['frame_path'], w=180)
                except Exception as e:
                    pdf.cell(0, 8, f"Erro ao carregar imagem: {e}", ln=True)

                pdf.ln(5)

                # Nova página se necessário
                if pdf.get_y() > 230:
                    pdf.add_page()

    def _add_detailed_stats(self, pdf: FPDF, stats: Dict):
        """Adiciona estatísticas detalhadas."""
        pdf.set_font('Helvetica', 'B', 18)
        pdf.cell(0, 10, "Estatísticas Detalhadas", ln=True)
        pdf.ln(5)

        pdf.set_font('Helvetica', '', 10)

        # Tabela de sangramento por tempo
        if stats.get('blood_timeline'):
            pdf.set_font('Helvetica', 'B', 12)
            pdf.cell(0, 8, "Detecções de Sangramento", ln=True)
            pdf.set_font('Helvetica', '', 9)

            # Cabeçalho
            pdf.set_fill_color(200, 200, 200)
            pdf.cell(40, 7, "Tempo", border=1, fill=True)
            pdf.cell(40, 7, "Área (%)", border=1, fill=True)
            pdf.cell(40, 7, "Confiança", border=1, fill=True)
            pdf.ln()

            # Dados (limitar a 50 para não ficar muito longo)
            for detection in stats['blood_timeline'][:50]:
                pdf.cell(40, 6, detection['timestamp_formatted'], border=1)
                pdf.cell(40, 6, f"{detection['area_percent']:.2f}%", border=1)
                pdf.cell(40, 6, f"{detection['confidence']:.2f}", border=1)
                pdf.ln()


# Exemplo de uso
if __name__ == "__main__":
    # Carregar resultados
    with open("output/video_analysis/test_video/results.json") as f:
        stats = json.load(f)

    # Gerar relatório
    generator = SurgicalReportGenerator()
    report_path = generator.generate_report(stats)
```

### Success Criteria:

#### Automated Verification:
- [ ] Pipeline processa vídeo de teste: `python src/video/processor.py`
- [ ] JSON de resultados gerado: `cat output/video_analysis/*/results.json`
- [ ] Relatório PDF gerado: `ls reports/*.pdf`
- [ ] Frames de alertas salvos: `ls output/video_analysis/*/alert_*.jpg`

#### Manual Verification:
- [ ] Verificar se detecções de sangramento são corretas
- [ ] Confirmar que alertas são gerados nos momentos corretos
- [ ] Revisar relatório PDF para completude e clareza
- [ ] Testar com diferentes vídeos de entrada

**Implementation Note**: Teste primeiro com vídeos curtos (1-2 minutos) antes de processar vídeos completos de cirurgias.

---

## Phase 4: Infraestrutura AWS com Terraform

### Overview
Toda infraestrutura AWS será gerenciada via Terraform, permitindo ligar/desligar recursos sob demanda para economizar custos. A infraestrutura é dividida em dois ambientes independentes:

1. **Treinamento** (temporário): EC2 com GPU potente, usado por ~4-6 horas
2. **Inferência** (sob demanda): SageMaker endpoint, ligado apenas para demos

### Comparativo de Infraestrutura

| Aspecto | Treinamento | Inferência |
|---------|-------------|------------|
| **Recurso** | EC2 p3.2xlarge | SageMaker ml.g4dn.xlarge |
| **GPU** | NVIDIA V100 (16GB) | NVIDIA T4 (16GB) |
| **Custo/hora** | ~$3.06 | ~$0.53 |
| **Uso típico** | 4-6 horas (uma vez) | 1-2 horas (demos) |
| **Custo total estimado** | ~$15-20 | ~$1-2 por demo |
| **Lifecycle** | Criar → Treinar → Destruir | Criar → Demo → Destruir |

### Changes Required:

#### 4.1. Módulo Terraform - Storage (Persistente)
**File**: `terraform/modules/storage/main.tf`

```hcl
# =============================================================================
# MÓDULO: Storage (S3)
# Este módulo é PERSISTENTE - não destruir, contém dados e modelos
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "surgical-detection"
}

variable "environment" {
  description = "Ambiente (dev, prod)"
  type        = string
  default     = "dev"
}

# S3 Bucket para datasets
resource "aws_s3_bucket" "datasets" {
  bucket = "${var.project_name}-datasets-${var.environment}"

  tags = {
    Name        = "${var.project_name}-datasets"
    Environment = var.environment
    Project     = "FIAP-TechChallenge-Fase4"
  }
}

# S3 Bucket para modelos treinados
resource "aws_s3_bucket" "models" {
  bucket = "${var.project_name}-models-${var.environment}"

  tags = {
    Name        = "${var.project_name}-models"
    Environment = var.environment
    Project     = "FIAP-TechChallenge-Fase4"
  }
}

# S3 Bucket para resultados/outputs
resource "aws_s3_bucket" "results" {
  bucket = "${var.project_name}-results-${var.environment}"

  tags = {
    Name        = "${var.project_name}-results"
    Environment = var.environment
    Project     = "FIAP-TechChallenge-Fase4"
  }
}

# Versionamento para bucket de modelos (importante!)
resource "aws_s3_bucket_versioning" "models_versioning" {
  bucket = aws_s3_bucket.models.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle rule para limpar resultados antigos
resource "aws_s3_bucket_lifecycle_configuration" "results_lifecycle" {
  bucket = aws_s3_bucket.results.id

  rule {
    id     = "cleanup-old-results"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# Outputs
output "datasets_bucket" {
  value = aws_s3_bucket.datasets.bucket
}

output "models_bucket" {
  value = aws_s3_bucket.models.bucket
}

output "results_bucket" {
  value = aws_s3_bucket.results.bucket
}
```

#### 4.2. Módulo Terraform - Training (Temporário)
**File**: `terraform/modules/training/main.tf`

```hcl
# =============================================================================
# MÓDULO: Training Infrastructure
# TEMPORÁRIO - Criar para treinar, destruir após treino
# Custo: ~$3.06/hora (p3.2xlarge)
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "project_name" {
  type    = string
  default = "surgical-detection"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "instance_type" {
  description = "Tipo de instância EC2 para treinamento"
  type        = string
  default     = "p3.2xlarge"  # V100 GPU - bom para treinar YOLOv8
}

variable "datasets_bucket" {
  description = "Nome do bucket S3 com datasets"
  type        = string
}

variable "models_bucket" {
  description = "Nome do bucket S3 para salvar modelos"
  type        = string
}

# AMI com Deep Learning (PyTorch + CUDA)
data "aws_ami" "deep_learning" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning AMI GPU PyTorch*Ubuntu*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Security Group para SSH
resource "aws_security_group" "training" {
  name_prefix = "${var.project_name}-training-"
  description = "Security group for training instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Em produção, restringir ao seu IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-training-sg"
  }
}

# IAM Role para EC2 acessar S3
resource "aws_iam_role" "training" {
  name = "${var.project_name}-training-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "training_s3" {
  name = "${var.project_name}-training-s3-policy"
  role = aws_iam_role.training.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.datasets_bucket}",
          "arn:aws:s3:::${var.datasets_bucket}/*",
          "arn:aws:s3:::${var.models_bucket}",
          "arn:aws:s3:::${var.models_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "training" {
  name = "${var.project_name}-training-profile"
  role = aws_iam_role.training.name
}

# Script de inicialização
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Atualizar sistema
    apt-get update

    # Criar diretório de trabalho
    mkdir -p /home/ubuntu/training
    cd /home/ubuntu/training

    # Instalar dependências Python
    pip install ultralytics boto3 opencv-python-headless

    # Baixar dataset do S3
    aws s3 sync s3://${var.datasets_bucket}/yolo_format/ ./dataset/

    # Criar script de treinamento
    cat > train.sh << 'TRAIN_SCRIPT'
    #!/bin/bash
    cd /home/ubuntu/training

    # Treinar YOLOv8
    yolo train \
      data=./dataset/data.yaml \
      model=yolov8m.pt \
      epochs=100 \
      imgsz=640 \
      batch=16 \
      device=0 \
      project=./results \
      name=surgical_detection

    # Upload do modelo para S3
    aws s3 cp ./results/surgical_detection/weights/best.pt \
      s3://${var.models_bucket}/trained/best.pt

    aws s3 cp ./results/surgical_detection/weights/best.onnx \
      s3://${var.models_bucket}/trained/best.onnx || true

    echo "Treinamento completo! Modelo salvo em s3://${var.models_bucket}/trained/"
    TRAIN_SCRIPT

    chmod +x train.sh
    chown -R ubuntu:ubuntu /home/ubuntu/training

    echo "Setup completo. Execute: cd /home/ubuntu/training && ./train.sh"
  EOF
}

# EC2 Instance para treinamento
resource "aws_instance" "training" {
  ami                    = data.aws_ami.deep_learning.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.training.name
  vpc_security_group_ids = [aws_security_group.training.id]

  root_block_device {
    volume_size = 100  # GB - espaço para dataset e checkpoints
    volume_type = "gp3"
  }

  user_data = locals.user_data

  tags = {
    Name        = "${var.project_name}-training"
    Environment = var.environment
    Purpose     = "YOLOv8-Training"
    AutoStop    = "true"  # Tag para lembrar de destruir
  }
}

# Outputs
output "instance_id" {
  value = aws_instance.training.id
}

output "public_ip" {
  value = aws_instance.training.public_ip
}

output "ssh_command" {
  value = "ssh -i your-key.pem ubuntu@${aws_instance.training.public_ip}"
}

output "training_command" {
  value = "cd /home/ubuntu/training && ./train.sh"
}

output "estimated_cost_per_hour" {
  value = "$3.06/hora (p3.2xlarge)"
}
```

#### 4.3. Módulo Terraform - Inference (Sob Demanda)
**File**: `terraform/modules/inference/main.tf`

```hcl
# =============================================================================
# MÓDULO: Inference Infrastructure (SageMaker)
# SOB DEMANDA - Criar para demos, destruir após uso
# Custo: ~$0.53/hora (ml.g4dn.xlarge)
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "project_name" {
  type    = string
  default = "surgical-detection"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "models_bucket" {
  description = "Nome do bucket S3 com modelos"
  type        = string
}

variable "model_s3_key" {
  description = "Caminho do modelo no S3"
  type        = string
  default     = "trained/model.tar.gz"
}

variable "instance_type" {
  description = "Tipo de instância SageMaker"
  type        = string
  default     = "ml.g4dn.xlarge"  # T4 GPU - suficiente para inferência
}

# IAM Role para SageMaker
resource "aws_iam_role" "sagemaker" {
  name = "${var.project_name}-sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "sagemaker.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_full" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy" "sagemaker_s3" {
  name = "${var.project_name}-sagemaker-s3"
  role = aws_iam_role.sagemaker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.models_bucket}",
        "arn:aws:s3:::${var.models_bucket}/*"
      ]
    }]
  })
}

# SageMaker Model
resource "aws_sagemaker_model" "yolov8" {
  name               = "${var.project_name}-model"
  execution_role_arn = aws_iam_role.sagemaker.arn

  primary_container {
    image          = "763104351884.dkr.ecr.us-east-1.amazonaws.com/pytorch-inference:2.0-gpu-py310"
    model_data_url = "s3://${var.models_bucket}/${var.model_s3_key}"
    environment = {
      SAGEMAKER_PROGRAM = "inference.py"
    }
  }

  tags = {
    Name        = "${var.project_name}-model"
    Environment = var.environment
  }
}

# SageMaker Endpoint Configuration
resource "aws_sagemaker_endpoint_configuration" "yolov8" {
  name = "${var.project_name}-config"

  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.yolov8.name
    instance_type          = var.instance_type
    initial_instance_count = 1
  }

  tags = {
    Name        = "${var.project_name}-config"
    Environment = var.environment
  }
}

# SageMaker Endpoint
resource "aws_sagemaker_endpoint" "yolov8" {
  name                 = "${var.project_name}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.yolov8.name

  tags = {
    Name        = "${var.project_name}-endpoint"
    Environment = var.environment
    AutoStop    = "true"  # Lembrete para destruir após uso
  }
}

# CloudWatch Alarm para custos (opcional)
resource "aws_cloudwatch_metric_alarm" "endpoint_invocations" {
  alarm_name          = "${var.project_name}-low-usage-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 6  # 6 períodos de 10 min = 1 hora
  metric_name         = "Invocations"
  namespace           = "AWS/SageMaker"
  period              = 600  # 10 minutos
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Endpoint sem uso por 1 hora - considere destruir"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.yolov8.name
    VariantName  = "primary"
  }

  alarm_actions = []  # Adicionar SNS topic se quiser notificação

  tags = {
    Name = "${var.project_name}-usage-alarm"
  }
}

# Outputs
output "endpoint_name" {
  value = aws_sagemaker_endpoint.yolov8.name
}

output "endpoint_arn" {
  value = aws_sagemaker_endpoint.yolov8.arn
}

output "invoke_url" {
  value = "https://runtime.sagemaker.${data.aws_region.current.name}.amazonaws.com/endpoints/${aws_sagemaker_endpoint.yolov8.name}/invocations"
}

output "estimated_cost_per_hour" {
  value = "$0.53/hora (ml.g4dn.xlarge)"
}

data "aws_region" "current" {}
```

#### 4.4. Environment - Training
**File**: `terraform/environments/training/main.tf`

```hcl
# =============================================================================
# AMBIENTE: Treinamento
# Uso: terraform init && terraform apply
# Após treino: terraform destroy
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 para state (opcional, recomendado)
  # backend "s3" {
  #   bucket = "seu-bucket-tfstate"
  #   key    = "surgical-detection/training/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "FIAP-TechChallenge-Fase4"
      Environment = "training"
      ManagedBy   = "Terraform"
    }
  }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "surgical-detection"
}

# Primeiro, criar storage (se ainda não existe)
module "storage" {
  source       = "../../modules/storage"
  project_name = var.project_name
  environment  = "dev"
}

# Criar infra de treinamento
module "training" {
  source          = "../../modules/training"
  project_name    = var.project_name
  environment     = "dev"
  datasets_bucket = module.storage.datasets_bucket
  models_bucket   = module.storage.models_bucket
  instance_type   = "p3.2xlarge"  # GPU V100
}

# Outputs
output "training_instance_ip" {
  value = module.training.public_ip
}

output "ssh_command" {
  value = module.training.ssh_command
}

output "training_command" {
  value = module.training.training_command
}

output "cost_warning" {
  value = "⚠️ ATENÇÃO: Esta instância custa ${module.training.estimated_cost_per_hour}. Execute 'terraform destroy' após o treinamento!"
}
```

#### 4.5. Environment - Inference
**File**: `terraform/environments/inference/main.tf`

```hcl
# =============================================================================
# AMBIENTE: Inferência
# Uso: terraform init && terraform apply
# Após demo: terraform destroy
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "FIAP-TechChallenge-Fase4"
      Environment = "inference"
      ManagedBy   = "Terraform"
    }
  }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "surgical-detection"
}

variable "models_bucket" {
  description = "Bucket com modelos treinados"
  type        = string
}

# Criar infra de inferência
module "inference" {
  source        = "../../modules/inference"
  project_name  = var.project_name
  environment   = "dev"
  models_bucket = var.models_bucket
  model_s3_key  = "trained/model.tar.gz"
  instance_type = "ml.g4dn.xlarge"  # GPU T4 - suficiente para inferência
}

# Outputs
output "endpoint_name" {
  value = module.inference.endpoint_name
}

output "invoke_url" {
  value = module.inference.invoke_url
}

output "cost_warning" {
  value = "⚠️ ATENÇÃO: Este endpoint custa ${module.inference.estimated_cost_per_hour}. Execute 'terraform destroy' após a demonstração!"
}
```

#### 4.6. Scripts de Automação
**File**: `scripts/infra-up-training.sh`

```bash
#!/bin/bash
# =============================================================================
# Script para LIGAR infraestrutura de treinamento
# =============================================================================

set -e

echo "🚀 Iniciando infraestrutura de TREINAMENTO..."
echo "⚠️  ATENÇÃO: Custo estimado ~\$3.06/hora"
echo ""

cd terraform/environments/training

# Inicializar Terraform
terraform init

# Planejar
echo "📋 Planejando infraestrutura..."
terraform plan -out=tfplan

# Confirmar
read -p "Deseja criar a infraestrutura? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Operação cancelada."
    exit 0
fi

# Aplicar
terraform apply tfplan

echo ""
echo "✅ Infraestrutura criada!"
echo ""
terraform output

echo ""
echo "📝 Próximos passos:"
echo "   1. Conecte via SSH: $(terraform output -raw ssh_command)"
echo "   2. Execute o treinamento: $(terraform output -raw training_command)"
echo "   3. Após treino, DESTRUA a infra: ./scripts/infra-down-training.sh"
```

**File**: `scripts/infra-down-training.sh`

```bash
#!/bin/bash
# =============================================================================
# Script para DESLIGAR infraestrutura de treinamento
# =============================================================================

set -e

echo "🛑 Destruindo infraestrutura de TREINAMENTO..."
echo ""

cd terraform/environments/training

# Confirmar
read -p "Tem certeza que deseja destruir? O modelo foi salvo no S3? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Operação cancelada."
    exit 0
fi

# Destruir (exceto storage)
terraform destroy -target=module.training

echo ""
echo "✅ Infraestrutura de treinamento destruída!"
echo "💰 Custos de EC2 interrompidos."
echo "📦 Buckets S3 preservados (datasets e modelos)."
```

**File**: `scripts/infra-up-inference.sh`

```bash
#!/bin/bash
# =============================================================================
# Script para LIGAR infraestrutura de inferência
# =============================================================================

set -e

echo "🚀 Iniciando infraestrutura de INFERÊNCIA..."
echo "⚠️  ATENÇÃO: Custo estimado ~\$0.53/hora"
echo ""

# Verificar se modelo existe no S3
MODELS_BUCKET="surgical-detection-models-dev"
if ! aws s3 ls "s3://${MODELS_BUCKET}/trained/model.tar.gz" > /dev/null 2>&1; then
    echo "❌ Erro: Modelo não encontrado em s3://${MODELS_BUCKET}/trained/model.tar.gz"
    echo "   Execute o treinamento primeiro!"
    exit 1
fi

cd terraform/environments/inference

# Inicializar Terraform
terraform init

# Aplicar
terraform apply -var="models_bucket=${MODELS_BUCKET}" -auto-approve

echo ""
echo "✅ Endpoint de inferência criado!"
echo ""
terraform output

echo ""
echo "📝 Para testar:"
echo "   python src/cloud/test_endpoint.py"
echo ""
echo "⚠️  Lembre-se de destruir após uso: ./scripts/infra-down-inference.sh"
```

**File**: `scripts/infra-down-inference.sh`

```bash
#!/bin/bash
# =============================================================================
# Script para DESLIGAR infraestrutura de inferência
# =============================================================================

set -e

echo "🛑 Destruindo infraestrutura de INFERÊNCIA..."
echo ""

cd terraform/environments/inference

terraform destroy -auto-approve

echo ""
echo "✅ Endpoint de inferência destruído!"
echo "💰 Custos de SageMaker interrompidos."
```

#### 4.7. Deploy AWS SageMaker (Python)
**File**: `src/cloud/aws_deploy.py`

```python
"""
Deploy do modelo YOLOv8 no AWS SageMaker.
Baseado em: https://github.com/aws-samples/host-yolov8-on-sagemaker-endpoint
"""

import boto3
import sagemaker
from sagemaker.pytorch import PyTorchModel
from pathlib import Path
import tarfile
import os


class AWSSageMakerDeploy:
    """Deploy de modelo YOLOv8 no SageMaker."""

    def __init__(
        self,
        region: str = 'us-east-1',
        role_arn: str = None  # IAM Role com permissões SageMaker
    ):
        self.region = region
        self.session = sagemaker.Session()
        self.role = role_arn or sagemaker.get_execution_role()
        self.s3_client = boto3.client('s3', region_name=region)

    def prepare_model_artifact(
        self,
        model_path: str,
        output_path: str = "model.tar.gz"
    ) -> str:
        """
        Prepara o artifact do modelo para upload no S3.

        Args:
            model_path: Caminho para o modelo .pt
            output_path: Caminho do arquivo tar.gz de saída
        """
        model_path = Path(model_path)

        # Criar estrutura esperada pelo SageMaker
        with tarfile.open(output_path, "w:gz") as tar:
            # Adicionar modelo
            tar.add(model_path, arcname="model.pt")

            # Adicionar script de inferência
            inference_script = self._create_inference_script()
            tar.add(inference_script, arcname="code/inference.py")

            # Adicionar requirements
            requirements = self._create_requirements()
            tar.add(requirements, arcname="code/requirements.txt")

        return output_path

    def _create_inference_script(self) -> str:
        """Cria script de inferência para SageMaker."""
        script_content = '''
import json
import torch
from ultralytics import YOLO
import cv2
import numpy as np
import base64
from io import BytesIO
from PIL import Image

def model_fn(model_dir):
    """Carrega o modelo."""
    model_path = f"{model_dir}/model.pt"
    model = YOLO(model_path)
    return model

def input_fn(request_body, request_content_type):
    """Processa input da requisição."""
    if request_content_type == 'application/json':
        data = json.loads(request_body)
        # Decodificar imagem base64
        image_data = base64.b64decode(data['image'])
        image = Image.open(BytesIO(image_data))
        return np.array(image)
    elif request_content_type in ['image/jpeg', 'image/png']:
        image = Image.open(BytesIO(request_body))
        return np.array(image)
    else:
        raise ValueError(f"Unsupported content type: {request_content_type}")

def predict_fn(input_data, model):
    """Executa inferência."""
    results = model(input_data, verbose=False)
    return results

def output_fn(prediction, response_content_type):
    """Formata output da resposta."""
    results = prediction[0]

    detections = []
    for box in results.boxes:
        detections.append({
            'class': results.names[int(box.cls[0])],
            'confidence': float(box.conf[0]),
            'bbox': box.xyxy[0].tolist()
        })

    return json.dumps({
        'detections': detections,
        'num_detections': len(detections)
    })
'''
        script_path = "/tmp/inference.py"
        with open(script_path, 'w') as f:
            f.write(script_content)
        return script_path

    def _create_requirements(self) -> str:
        """Cria requirements.txt."""
        requirements = """
ultralytics>=8.0.0
opencv-python-headless>=4.8.0
Pillow>=10.0.0
"""
        req_path = "/tmp/requirements.txt"
        with open(req_path, 'w') as f:
            f.write(requirements)
        return req_path

    def upload_to_s3(
        self,
        local_path: str,
        bucket: str,
        key: str
    ) -> str:
        """Upload arquivo para S3."""
        self.s3_client.upload_file(local_path, bucket, key)
        return f"s3://{bucket}/{key}"

    def deploy_model(
        self,
        model_s3_uri: str,
        endpoint_name: str,
        instance_type: str = "ml.g4dn.xlarge",  # GPU instance
        instance_count: int = 1
    ) -> str:
        """
        Deploy do modelo no SageMaker.

        Args:
            model_s3_uri: URI S3 do model.tar.gz
            endpoint_name: Nome do endpoint
            instance_type: Tipo de instância (ml.g4dn.xlarge para GPU)
            instance_count: Número de instâncias

        Returns:
            Nome do endpoint criado
        """
        pytorch_model = PyTorchModel(
            model_data=model_s3_uri,
            role=self.role,
            framework_version="2.0",
            py_version="py310",
            entry_point="inference.py",
            source_dir="code"
        )

        predictor = pytorch_model.deploy(
            initial_instance_count=instance_count,
            instance_type=instance_type,
            endpoint_name=endpoint_name
        )

        print(f"Endpoint deployed: {endpoint_name}")
        return endpoint_name

    def invoke_endpoint(
        self,
        endpoint_name: str,
        image_path: str
    ) -> dict:
        """
        Invoca o endpoint para fazer predição.

        Args:
            endpoint_name: Nome do endpoint
            image_path: Caminho para a imagem

        Returns:
            Dicionário com detecções
        """
        runtime = boto3.client('sagemaker-runtime', region_name=self.region)

        # Ler e encodar imagem
        with open(image_path, 'rb') as f:
            image_bytes = f.read()

        response = runtime.invoke_endpoint(
            EndpointName=endpoint_name,
            ContentType='image/jpeg',
            Body=image_bytes
        )

        result = json.loads(response['Body'].read().decode())
        return result


# Exemplo de uso
if __name__ == "__main__":
    deployer = AWSSageMakerDeploy(region='us-east-1')

    # 1. Preparar artifact
    artifact_path = deployer.prepare_model_artifact("models/trained/best.pt")

    # 2. Upload para S3
    s3_uri = deployer.upload_to_s3(
        artifact_path,
        bucket="seu-bucket",
        key="models/surgical-detection/model.tar.gz"
    )

    # 3. Deploy
    endpoint = deployer.deploy_model(
        model_s3_uri=s3_uri,
        endpoint_name="surgical-detection-endpoint"
    )

    # 4. Testar
    result = deployer.invoke_endpoint(endpoint, "test_image.jpg")
    print(result)
```

#### 4.2. Script Auxiliar para Processamento em Batch
**File**: `src/cloud/aws_batch_processor.py`

```python
"""
Processamento em batch de múltiplos vídeos usando AWS S3 e SageMaker.
Otimizado para custos - processa vídeos offline em lote.
"""

import boto3
import json
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from tqdm import tqdm


class AWSBatchProcessor:
    """Processa múltiplos vídeos em batch usando SageMaker."""

    def __init__(
        self,
        region: str = 'us-east-1',
        bucket: str = None,
        endpoint_name: str = None
    ):
        self.region = region
        self.bucket = bucket
        self.endpoint_name = endpoint_name
        self.s3 = boto3.client('s3', region_name=region)
        self.sagemaker_runtime = boto3.client('sagemaker-runtime', region_name=region)

    def upload_videos(self, video_paths: list, prefix: str = "videos/input") -> list:
        """Upload múltiplos vídeos para S3."""
        s3_paths = []
        for video_path in tqdm(video_paths, desc="Uploading videos"):
            video_path = Path(video_path)
            s3_key = f"{prefix}/{video_path.name}"
            self.s3.upload_file(str(video_path), self.bucket, s3_key)
            s3_paths.append(f"s3://{self.bucket}/{s3_key}")
        return s3_paths

    def process_video_frames(
        self,
        s3_video_path: str,
        sample_fps: int = 1
    ) -> dict:
        """
        Processa frames de um vídeo do S3.

        Args:
            s3_video_path: Caminho S3 do vídeo
            sample_fps: Frames por segundo para analisar

        Returns:
            Dicionário com resultados da análise
        """
        # Baixar vídeo temporariamente, extrair frames, processar
        # (implementação simplificada para demonstração)

        import tempfile
        import cv2

        # Parse S3 path
        bucket = s3_video_path.split('/')[2]
        key = '/'.join(s3_video_path.split('/')[3:])

        # Download video
        with tempfile.NamedTemporaryFile(suffix='.mp4', delete=False) as tmp:
            self.s3.download_file(bucket, key, tmp.name)

            cap = cv2.VideoCapture(tmp.name)
            fps = cap.get(cv2.CAP_PROP_FPS)
            frame_interval = int(fps / sample_fps)

            results = []
            frame_idx = 0

            while True:
                ret, frame = cap.read()
                if not ret:
                    break

                if frame_idx % frame_interval == 0:
                    # Encode frame and send to SageMaker
                    _, buffer = cv2.imencode('.jpg', frame)
                    response = self.sagemaker_runtime.invoke_endpoint(
                        EndpointName=self.endpoint_name,
                        ContentType='image/jpeg',
                        Body=buffer.tobytes()
                    )
                    detection = json.loads(response['Body'].read().decode())
                    detection['frame'] = frame_idx
                    detection['timestamp'] = frame_idx / fps
                    results.append(detection)

                frame_idx += 1

            cap.release()

        return {
            'video': s3_video_path,
            'total_frames_analyzed': len(results),
            'detections': results
        }

    def process_batch(
        self,
        s3_video_paths: list,
        max_workers: int = 4
    ) -> list:
        """Processa múltiplos vídeos em paralelo."""
        results = []

        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = [
                executor.submit(self.process_video_frames, path)
                for path in s3_video_paths
            ]

            for future in tqdm(futures, desc="Processing videos"):
                results.append(future.result())

        return results

    def save_results_to_s3(self, results: list, prefix: str = "results"):
        """Salva resultados no S3."""
        for result in results:
            video_name = Path(result['video']).stem
            key = f"{prefix}/{video_name}_results.json"

            self.s3.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=json.dumps(result, indent=2),
                ContentType='application/json'
            )

        print(f"Results saved to s3://{self.bucket}/{prefix}/")


# Exemplo de uso
if __name__ == "__main__":
    processor = AWSBatchProcessor(
        region='us-east-1',
        bucket='seu-bucket-surgical-videos',
        endpoint_name='surgical-detection-endpoint'
    )

    # Upload e processar vídeos
    videos = ['video1.mp4', 'video2.mp4', 'video3.mp4']
    s3_paths = processor.upload_videos(videos)
    results = processor.process_batch(s3_paths)
    processor.save_results_to_s3(results)
```

### Success Criteria:

#### Automated Verification:
- [ ] Módulos Terraform validam: `terraform -chdir=terraform/modules/storage validate`
- [ ] Storage criado: `./scripts/infra-up-training.sh` (cria S3 também)
- [ ] Upload dataset para S3: `aws s3 sync data/yolo_format/ s3://surgical-detection-datasets-dev/`
- [ ] Treinamento EC2 funciona: SSH na instância e executar `./train.sh`
- [ ] Modelo salvo no S3: `aws s3 ls s3://surgical-detection-models-dev/trained/`
- [ ] Infra treinamento destruída: `./scripts/infra-down-training.sh`
- [ ] Endpoint de inferência funciona: `./scripts/infra-up-inference.sh`
- [ ] Endpoint responde: `curl -X POST $ENDPOINT_URL -d @test.jpg`
- [ ] Infra inferência destruída: `./scripts/infra-down-inference.sh`

#### Manual Verification:
- [ ] Testar endpoint com imagens reais do dataset
- [ ] Verificar custos na console AWS (deve ser ~$0 quando infra destruída)
- [ ] Confirmar que detecções são consistentes com modelo local
- [ ] Documentar processo de deploy/destroy

**Implementation Note**:
- Deploy de treinamento: ~5 minutos
- Treinamento: ~2-6 horas
- Deploy de inferência: ~10-15 minutos
- **SEMPRE destruir após uso para evitar custos!**

---

## Phase 5: Demonstração e Documentação Final

### Overview
Preparar demonstração em vídeo e documentação técnica final.

### Changes Required:

#### 5.1. Script de Demonstração
**File**: `src/demo/run_demo.py`

```python
"""
Script de demonstração do sistema completo.
Processa um vídeo de exemplo e gera relatório para apresentação.
"""

import sys
sys.path.append('.')

from src.video.processor import SurgicalVideoProcessor
from src.reports.generator import SurgicalReportGenerator
from pathlib import Path
import json


def run_full_demo(
    video_path: str,
    model_path: str,
    output_dir: str = "demo_output"
):
    """
    Executa demonstração completa do sistema.

    Args:
        video_path: Caminho para vídeo de teste
        model_path: Caminho para modelo treinado
        output_dir: Diretório de saída
    """
    print("="*60)
    print("DEMONSTRAÇÃO - Sistema de Análise de Vídeo Cirúrgico")
    print("FIAP - Pós-Graduação em IA - Tech Challenge Fase 4")
    print("="*60)

    # 1. Processar vídeo
    print("\n[1/3] Processando vídeo...")

    def alert_callback(alert):
        severity_emoji = {
            'critical': '🚨',
            'high': '⚠️',
            'medium': '⚡',
            'low': 'ℹ️'
        }
        print(f"  {severity_emoji.get(alert.severity, '•')} [{alert.severity.upper()}] "
              f"Tempo: {alert.timestamp:.1f}s - {alert.message}")

    processor = SurgicalVideoProcessor(
        model_path=model_path,
        output_dir=output_dir,
        save_frames=True,
        alert_callback=alert_callback
    )

    stats = processor.process_video(
        video_path=video_path,
        sample_fps=2  # 2 frames por segundo para demo
    )

    # 2. Gerar relatório
    print("\n[2/3] Gerando relatório PDF...")
    generator = SurgicalReportGenerator(output_dir=f"{output_dir}/reports")
    report_path = generator.generate_report(stats)

    # 3. Resumo
    print("\n[3/3] Resumo da análise:")
    print("-"*40)
    print(f"Vídeo analisado: {stats['video']}")
    print(f"Duração: {stats['duration_seconds']:.1f} segundos")
    print(f"Total de detecções: {stats['total_detections']}")
    print(f"Alertas gerados: {stats['alerts']['total']}")
    print(f"  - Críticos: {stats['alerts']['critical']}")
    print(f"  - Altos: {stats['alerts']['high']}")
    print(f"  - Médios: {stats['alerts']['medium']}")
    print(f"  - Baixos: {stats['alerts']['low']}")
    print("-"*40)
    print(f"\nRelatório salvo em: {report_path}")
    print(f"Frames de alertas em: {output_dir}/")

    return stats, report_path


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--video', type=str, required=True)
    parser.add_argument('--model', type=str, default='models/trained/best.pt')
    parser.add_argument('--output', type=str, default='demo_output')

    args = parser.parse_args()

    run_full_demo(
        video_path=args.video,
        model_path=args.model,
        output_dir=args.output
    )
```

#### 5.2. Estrutura do Relatório Técnico
**File**: `docs/RELATORIO_TECNICO.md` (template)

```markdown
# Relatório Técnico - Tech Challenge Fase 4
## Sistema de Análise de Vídeo para Saúde da Mulher

### 1. Introdução
- Contexto do desafio
- Objetivos do projeto
- Escopo da solução

### 2. Arquitetura da Solução
- Diagrama de arquitetura
- Componentes principais
- Fluxo de dados

### 3. Dataset Utilizado
- Descrição do dataset (GynSurg ou CholecSeg8k)
- Processo de preparação
- Estatísticas (train/val/test split)

### 4. Modelo de Detecção
- Arquitetura YOLOv8
- Processo de treinamento
- Hiperparâmetros utilizados
- Métricas de avaliação (mAP, Precision, Recall)

### 5. Pipeline de Processamento
- Extração de frames
- Inferência do modelo
- Sistema de alertas
- Geração de relatórios

### 6. Integração AWS Cloud
- Amazon SageMaker (endpoint de inferência)
- Amazon S3 (armazenamento de vídeos e modelos)
- AWS Lambda (processamento de eventos)
- Amazon CloudWatch (monitoramento e alertas)
- Arquitetura de deploy
- Custos estimados

### 7. Resultados
- Métricas de performance
- Exemplos de detecções
- Análise de casos

### 8. Conclusões
- Objetivos alcançados
- Limitações
- Trabalhos futuros

### 9. Referências
- Datasets
- Artigos
- Documentação técnica

### Anexos
- Código-fonte (link GitHub)
- Vídeo demonstrativo (link YouTube/Vimeo)
```

### Success Criteria:

#### Automated Verification:
- [ ] Demo executa sem erros: `python src/demo/run_demo.py --video test.mp4`
- [ ] Relatório técnico completo: `ls docs/RELATORIO_TECNICO.md`
- [ ] Código no repositório Git

#### Manual Verification:
- [ ] Gravar vídeo demonstrativo (≤15 min)
- [ ] Upload do vídeo no YouTube/Vimeo
- [ ] Revisar relatório técnico para completude
- [ ] Testar todos os scripts do repositório

---

## Testing Strategy

### Unit Tests
- Conversão de máscaras para bounding boxes YOLO
- Cálculo de área de detecção
- Geração de alertas por threshold

### Integration Tests
- Pipeline completo: vídeo → detecções → relatório
- Deploy e invocação do endpoint cloud

### Manual Testing Steps
1. Processar vídeo de 1 minuto do dataset
2. Verificar se detecções de sangramento são visualmente corretas
3. Confirmar que alertas são gerados nos momentos esperados
4. Revisar relatório PDF gerado
5. Testar endpoint cloud com latência aceitável

---

## Performance Considerations

- **Treinamento**: 2-6 horas em GPU (Colab T4 ou superior)
- **Inferência local**: ~30-50ms por frame (GPU) ou ~200-500ms (CPU)
- **Inferência cloud**: ~100-300ms por frame (incluindo latência de rede)
- **Processamento de vídeo**: ~1-2 horas para vídeo de 1 hora (1 FPS sampling)

---

## Migration Notes

### Se mudar de CholecSeg8k para GynSurg:
1. Atualizar script de preparação (`prepare_gynsurg.py`)
2. Ajustar mapeamento de classes no `data.yaml`
3. Re-treinar modelo com novo dataset
4. Atualizar thresholds de alertas se necessário

### Gestão de Custos AWS (via Terraform):
```bash
# REGRA DE OURO: Sempre destruir após uso!

# Treinamento (~$3.06/hora)
./scripts/infra-up-training.sh    # Criar
# ... treinar ...
./scripts/infra-down-training.sh  # Destruir após treino

# Inferência (~$0.53/hora)
./scripts/infra-up-inference.sh   # Criar para demo
# ... demonstrar ...
./scripts/infra-down-inference.sh # Destruir após demo
```

### Dicas adicionais de economia:
1. Usar instâncias Spot para treinamento (até 90% desconto) - adicionar `spot_price` no Terraform
2. Treinar durante horários de menor demanda
3. Monitorar CloudWatch para alertas de custos

---

## References

### Datasets
- CholecSeg8k: https://www.kaggle.com/datasets/newslab/cholecseg8k
- GynSurg: https://github.com/Sahar-Nasiri/GynSurg
- Lista de datasets cirúrgicos: https://github.com/luiscarlosgph/list-of-surgical-tool-datasets

### YOLOv8
- Documentação oficial: https://docs.ultralytics.com/
- Treinamento customizado: https://docs.ultralytics.com/modes/train/

### AWS
- SageMaker + YOLOv8: https://github.com/aws-samples/host-yolov8-on-sagemaker-endpoint
- SageMaker Pricing: https://aws.amazon.com/sagemaker/pricing/
- EC2 GPU Instances: https://aws.amazon.com/ec2/instance-types/p3/
- Deep Learning AMIs: https://aws.amazon.com/machine-learning/amis/
- AWS HIPAA Compliance: https://aws.amazon.com/compliance/hipaa-compliance/

### Terraform
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest
- SageMaker Resources: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_endpoint
- EC2 Resources: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
- Best Practices: https://www.terraform.io/docs/cloud/guides/recommended-practices/

---

## Changelog

| Data | Versão | Descrição |
|------|--------|-----------|
| 2026-05-09 | 0.1 | Plano inicial criado |
| 2026-05-09 | 0.2 | Decisão: usar AWS (removidas referências ao Azure) |
| 2026-05-09 | 0.3 | Adicionado Terraform para toda infra AWS; separação de ambientes treinamento/inferência; scripts liga/desliga |
