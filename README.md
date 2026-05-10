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

O sistema de validação permite testar o modelo treinado em clips de cirurgias ginecológicas e comparar diferentes versões do modelo de forma reproduzível.

#### 4.1. Gerar Validation Set Fixo (uma única vez)

```bash
# Cria arquivos com lista fixa de clips para validação reproduzível
./scripts/generate-validation-set.sh /path/to/GynSurg_Action_3sec

# Opcionalmente, especifique o número de clips (default: 10)
./scripts/generate-validation-set.sh /path/to/GynSurg_Action_3sec 20
```

Arquivos gerados em `GynSurg_Action_3sec/validation_sets/`:
- `validation_set_bleeding.txt` - Lista de clips com sangramento
- `validation_set_non_bleeding.txt` - Lista de clips sem sangramento

#### 4.2. Executar Validação

```bash
# Validação reproduzível com tag de versão do modelo
./scripts/validate-gynsurg.sh /path/to/GynSurg_Action_3sec --fixed --version v1_baseline

# Com upload para S3
./scripts/validate-gynsurg.sh /path/to/GynSurg_Action_3sec --fixed --version v1_baseline --upload
```

**Opções disponíveis:**

| Opção | Descrição |
|-------|-----------|
| `--fixed` | Usa o validation set fixo gerado anteriormente |
| `--seed` | Usa shuf com seed 42 (reproduzível, mas não usa arquivo) |
| `--version TAG` | Tag de versão do modelo (ex: v1_baseline, v2_classweight) |
| `--upload` | Faz upload dos resultados para S3 |

Os resultados são salvos em `~/surgical-training/validation_gynsurg_TIMESTAMP/` com:
- `validation_report.json` - Métricas e versão do modelo
- `bleeding_results/` - Detecções em clips com sangramento
- `non_bleeding_results/` - Detecções em clips sem sangramento

#### 4.3. Comparar Validações

```bash
# Comparar TODAS as validações existentes
./scripts/compare-validations.sh

# Comparar duas validações específicas
./scripts/compare-validations.sh validation_gynsurg_20260510_120000 validation_gynsurg_20260510_140000
```

#### 4.4. Fluxo Recomendado para Iteração do Modelo

1. **Baseline:** `--fixed --version v1_baseline`
2. **Após ajuste de class weights:** `--fixed --version v2_classweight`
3. **Após fine-tuning:** `--fixed --version v3_finetuned`
4. **Comparar progresso:** `./scripts/compare-validations.sh`

#### 4.5. Métricas de Avaliação

| Métrica | Descrição | Baseline v1 | Meta |
|---------|-----------|-------------|------|
| **Taxa de Detecção** | % de frames com sangramento detectado em clips de bleeding | 7.17% | > 60% |
| **Taxa de Falso Positivo** | % de frames com detecção em clips sem bleeding | 76.20% | < 20% |

> **Nota**: O baseline v1 apresenta domain shift severo entre CholecSeg8k (treino) e GynSurg (validação), resultando em alta taxa de falsos positivos devido à diferença de coloração entre tecido abdominal e pélvico.

### 5. Baixar Modelo Treinado

Após o treinamento, baixe o modelo para a pasta `web/models/`:

```bash
# Opção 1: Do S3 (recomendado)
aws s3 cp s3://surgical-detection-models-dev/trained/best.pt web/models/

# Opção 2: Direto do servidor de treinamento
scp usuario@servidor:~/surgical-training/results/surgical_detection/weights/best.pt web/models/
```

### 6. Interface Web

```bash
cd web

# Com GPU NVIDIA (requer nvidia-docker)
docker-compose up -d

# Sem GPU (apenas CPU - mais lento, mas funcional)
docker-compose -f docker-compose.cpu.yml up -d

# Acessar: http://localhost:8100
```

**Quando usar cada opção:**
- **GPU**: Processamento em tempo real, demonstrações ao vivo
- **CPU**: Testes, desenvolvimento local, ambientes sem GPU dedicada

## Interface Web

A interface web permite demonstrar o sistema de detecção de forma interativa.

### Funcionalidades

| Recurso | Descrição |
|---------|-----------|
| **Upload de Vídeo** | Envie vídeos do seu computador para análise |
| **URL de Vídeo** | Cole uma URL (YouTube, etc.) para processar |
| **Galeria de Exemplos** | Selecione clips do dataset GynSurg pré-carregados no S3 |
| **Visualização** | Veja detecções em tempo real com bounding boxes |
| **Download** | Baixe o vídeo anotado e relatório JSON |
| **Informações** | Dados sobre o modelo, datasets e estratégia |

### Endpoints da API

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/` | GET | Interface web |
| `/health` | GET | Health check |
| `/api/video/upload` | POST | Upload de vídeo |
| `/api/video/url` | POST | Processar URL |
| `/api/video/status/{job_id}` | GET | Status do processamento |
| `/api/video/result/{job_id}/video` | GET | Baixar vídeo anotado |
| `/api/samples/list` | GET | Listar clips de exemplo |
| `/api/samples/process/{category}/{filename}` | POST | Processar clip |
| `/api/info/model` | GET | Informações do modelo |

### Estrutura Web

```
web/
├── app/
│   ├── main.py              # FastAPI app
│   ├── routers/
│   │   ├── video.py         # Processamento de vídeo
│   │   ├── samples.py       # Galeria de exemplos
│   │   └── info.py          # Informações
│   ├── services/
│   │   └── detector.py      # Serviço YOLOv8
│   └── static/              # Frontend (HTML/CSS/JS)
├── models/                  # Modelo best.pt
├── Dockerfile
├── docker-compose.yml       # Deploy com GPU
├── docker-compose.cpu.yml   # Deploy sem GPU
└── requirements.txt
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

Para detalhes sobre a implementação do Sistema de Análise de Vídeo, consulte o relatório técnico:

📄 [docs/relatorio_.pdf](docs/relatorio_.pdf)

▶️ [Vídeo demonstrativo]()

## Equipe

- Adriana Martins de Souza - RM 368050
- Diego Oliveira da Silva - RM 367964
- Eduardo Nicola F. Zagari - RM 368021
- Renan de Assis Torres - RM 368513

## Licença

Este projeto é desenvolvido para fins acadêmicos como parte do Tech Challenge da FIAP.

---

**Aviso**: Este sistema é um protótipo acadêmico e não deve ser usado para decisões médicas reais.
