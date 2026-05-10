# Surgical Video AI

Sistema de análise de vídeos cirúrgicos utilizando YOLOv8 customizado para detecção de **sangramento anômalo** e **instrumentos cirúrgicos** em procedimentos ginecológicos.

## FIAP - Pós-Graduação em Inteligência Artificial para Devs
**Tech Challenge - Fase 4: Análise de Dados**

---

## Objetivo

Desenvolver um sistema de visão computacional para monitoramento de saúde da mulher:
- Detectar sangramento anômalo durante cirurgias ginecológicas
- Identificar instrumentos cirúrgicos em tempo real
- Gerar alertas automáticos para a equipe médica
- Produzir relatórios de análise de procedimentos

## Estratégia de Datasets

Este projeto utiliza uma abordagem de **validação cross-dataset** para garantir a generalização do modelo:

| Dataset | Uso | Descrição |
|---------|-----|-----------|
| **CholecSeg8k** | Treinamento | 8.080 frames de colecistectomia com máscaras de segmentação pixel-level para sangramento e instrumentos |
| **GynSurg** | Validação/Demo | Clips de 3 segundos de cirurgias ginecológicas laparoscópicas com labels de bleeding/non-bleeding |

### Por que dois datasets?

1. **CholecSeg8k** fornece anotações precisas (máscaras de segmentação) ideais para treinar o modelo de detecção
2. **GynSurg** permite validar a capacidade de generalização do modelo em cirurgias ginecológicas reais
3. Esta abordagem demonstra que o modelo aprende padrões universais de sangramento e instrumentos cirúrgicos

### Estatísticas dos Datasets

**CholecSeg8k (Treinamento)**
- Total: 8.080 imagens
- Train: 6.464 imagens | Val: 1.616 imagens
- Classes: grasper (13.680 instâncias), blood (2.545 instâncias)

**GynSurg Action Recognition (Validação)**
- Bleeding: 977 clips (3s cada, 4K)
- Non-bleeding: 1.064 clips
- Resolução: 3840x2160 @ 30fps

## Tecnologias

| Componente | Tecnologia |
|------------|------------|
| Detecção de Objetos | YOLOv8m (Ultralytics) |
| Backend API | FastAPI |
| Frontend | HTML/CSS/JavaScript |
| Container | Docker |
| Cloud Storage | AWS S3 |
| IaC | Terraform |
| Linguagem | Python 3.10+ |

## Estrutura do Projeto

```
surgical-video-ai/
├── src/                    # Código-fonte Python
│   ├── data/              # Preparação de datasets
│   ├── models/            # Treinamento YOLOv8
│   ├── video/             # Processamento de vídeo
│   ├── evaluation/        # Avaliação e métricas
│   └── reports/           # Geração de relatórios
├── web/                    # Interface Web (FastAPI + Frontend)
│   ├── app/               # Backend FastAPI
│   └── Dockerfile         # Container da aplicação
├── scripts/               # Scripts de automação
│   ├── server-setup.sh    # Setup do servidor GPU
│   ├── server-train.sh    # Treinamento YOLOv8
│   └── server-inference.sh # Inferência em vídeos
├── terraform/             # Infraestrutura como Código
│   ├── modules/           # Módulos reutilizáveis (S3, etc)
│   └── environments/      # Configurações por ambiente
├── data/                  # Datasets (não versionado)
├── models/                # Modelos treinados (não versionado)
└── docs/                  # Documentação
```

## Quick Start

### 1. Pré-requisitos

- Python 3.10+
- AWS CLI configurado
- Docker (para interface web)
- **Para treinamento**: Servidor com GPU NVIDIA **OU** conta AWS com acesso a instâncias GPU

### 2. Preparar Dataset CholecSeg8k

```bash
# Preparar para formato YOLO
python src/data/prepare_cholecseg8k.py \
    --input ./CholecSeg8k \
    --output data/yolo_format
```

### 3. Treinamento

#### Opção A: Servidor Local com GPU (Recomendado)

```bash
# Copiar scripts para o servidor
scp -r scripts/ usuario@servidor:~/

# No servidor
./scripts/server-setup.sh      # Configurar ambiente
./scripts/server-train.sh      # Treinar modelo (~3-4 horas)
```

#### Opção B: AWS com Terraform

```bash
# Provisionar infraestrutura AWS (requer conta com acesso a instâncias GPU)
cd terraform/environments/training
terraform init
terraform apply

# Conectar à instância EC2 criada
ssh -i ~/.ssh/sua-chave.pem ubuntu@<IP_DA_INSTANCIA>

# Na instância EC2
./scripts/server-setup.sh
./scripts/server-train.sh

# IMPORTANTE: Destruir recursos após o treino para evitar custos
terraform destroy
```

### 4. Validação com GynSurg

```bash
# Testar modelo em clips de cirurgia ginecológica
./scripts/validate-gynsurg.sh /path/to/GynSurg_Action_3sec
```

### 5. Interface Web

```bash
cd web
docker-compose up -d
# Acessar: http://localhost:8000
```

## Infraestrutura Terraform

O projeto inclui módulos Terraform para provisionar a infraestrutura na AWS:

```
terraform/
├── modules/
│   ├── storage/      # S3 buckets para datasets, modelos e resultados
│   ├── training/     # EC2 com GPU para treinamento (g4dn.xlarge)
│   └── inference/    # SageMaker endpoint para inferência
└── environments/
    ├── training/     # Ambiente de treinamento
    └── inference/    # Ambiente de produção
```

### Custos Estimados AWS

| Recurso | Tipo | Custo/hora | Uso típico |
|---------|------|------------|------------|
| EC2 Training | g4dn.xlarge | ~$0.52 | 3-4 horas |
| S3 Storage | - | ~$0.023/GB/mês | Contínuo |
| SageMaker | ml.g4dn.xlarge | ~$0.74 | Por demanda |

**⚠️ IMPORTANTE**: Sempre execute `terraform destroy` após o uso para evitar custos!

## Recursos AWS (S3)

| Bucket | Descrição |
|--------|-----------|
| `surgical-detection-datasets-dev` | Dataset YOLO (726 MB) |
| `surgical-detection-models-dev` | Modelos treinados (.pt) |
| `surgical-detection-results-dev` | Resultados de inferência |

## Classes Detectadas

| ID | Classe | Descrição |
|----|--------|-----------|
| 0 | grasper | Pinça de apreensão |
| 1 | blood | Sangramento detectado |

## Documentação

- [Checkpoint do Servidor](docs/CHECKPOINT-SERVIDOR.md) - Instruções para execução no servidor
- [Plano de Implementação](docs/plano-implementacao-video-analysis.md) - Plano original

## Equipe

FIAP - Pós-Graduação em IA para Devs

## Licença

Este projeto é desenvolvido para fins acadêmicos como parte do Tech Challenge da FIAP.

---

**Aviso**: Este sistema é um protótipo acadêmico e não deve ser usado para decisões médicas reais.
