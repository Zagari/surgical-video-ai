# Surgical Video AI

Sistema de análise de vídeos cirúrgicos utilizando YOLOv8 customizado para detecção de **sangramento anômalo** e **instrumentos cirúrgicos** em procedimentos ginecológicos.

## FIAP - Pós-Graduação em Inteligência Artificial para Devs
**Tech Challenge - Fase 4**

---

## Objetivo

Desenvolver um sistema de visão computacional para:
- Detectar sangramento anômalo durante cirurgias ginecológicas
- Identificar instrumentos cirúrgicos em tempo real
- Gerar alertas automáticos para a equipe médica
- Produzir relatórios de análise de procedimentos

## Tecnologias

| Componente | Tecnologia |
|------------|------------|
| Detecção de Objetos | YOLOv8 (Ultralytics) |
| Cloud | AWS (SageMaker, S3, Lambda) |
| IaC | Terraform |
| Linguagem | Python 3.10+ |

## Estrutura do Projeto

```
surgical-video-ai/
├── src/                    # Código-fonte Python
│   ├── data/              # Preparação de datasets
│   ├── models/            # Treinamento YOLOv8
│   ├── video/             # Processamento de vídeo
│   ├── reports/           # Geração de relatórios
│   ├── cloud/             # Integração AWS
│   └── demo/              # Scripts de demonstração
├── terraform/             # Infraestrutura como Código
│   ├── modules/           # Módulos reutilizáveis
│   └── environments/      # Ambientes (training/inference)
├── scripts/               # Scripts de automação
├── notebooks/             # Jupyter notebooks
├── data/                  # Datasets (não versionado)
├── models/                # Modelos treinados (não versionado)
├── docs/                  # Documentação
└── tests/                 # Testes automatizados
```

## Quick Start

### 1. Pré-requisitos

```bash
# Python 3.10+
python --version

# Terraform
terraform version

# AWS CLI configurado
aws sts get-caller-identity
```

### 2. Instalação

```bash
# Clonar repositório
git clone https://github.com/SEU_USUARIO/surgical-video-ai.git
cd surgical-video-ai

# Criar ambiente virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou: venv\Scripts\activate  # Windows

# Instalar dependências
pip install -r requirements.txt
```

### 3. Preparar Dataset

```bash
# Extrair CholecSeg8k (se disponível)
unzip cholecseg8k.zip -d data/raw/

# Preparar para YOLOv8
python src/data/prepare_cholecseg8k.py \
    --input data/raw/cholecseg8k \
    --output data/yolo_format \
    --classes blood
```

### 4. Treinamento (AWS)

```bash
# Ligar infraestrutura de treinamento
./scripts/infra-up-training.sh

# SSH na instância e treinar
ssh -i your-key.pem ubuntu@<IP>
cd /home/ubuntu/training && ./train.sh

# Após treino, DESTRUIR infraestrutura
./scripts/infra-down-training.sh
```

### 5. Inferência (AWS)

```bash
# Ligar endpoint de inferência
./scripts/infra-up-inference.sh

# Testar
python src/demo/run_demo.py --video videos/input/test.mp4

# Após demo, DESTRUIR endpoint
./scripts/infra-down-inference.sh
```

## Custos AWS Estimados

| Recurso | Custo/hora | Uso típico | Total |
|---------|------------|------------|-------|
| EC2 p3.2xlarge (treino) | $3.06 | ~6 horas | ~$18 |
| SageMaker g4dn.xlarge (inferência) | $0.53 | ~2 horas/demo | ~$1 |
| S3 Storage | $0.023/GB/mês | - | ~$0.50 |

**IMPORTANTE**: Sempre execute `terraform destroy` após o uso para evitar custos!

## Datasets

| Dataset | Status | Descrição |
|---------|--------|-----------|
| [CholecSeg8k](https://www.kaggle.com/datasets/newslab/cholecseg8k) | Disponível | 8.080 frames com segmentação de sangue e instrumentos |
| [GynSurg](https://github.com/Sahar-Nasiri/GynSurg) | Aguardando acesso | 152 vídeos de cirurgias ginecológicas |

## Documentação

- [Plano de Implementação](docs/plano-implementacao-video-analysis.md)
- [Relatório Técnico](docs/RELATORIO_TECNICO.md) *(em desenvolvimento)*

## Equipe

FIAP - Pós-Graduação em IA para Devs - Turma XXXX

## Licença

Este projeto é desenvolvido para fins acadêmicos como parte do Tech Challenge da FIAP.

---

**Aviso**: Este sistema é um protótipo acadêmico e não deve ser usado para decisões médicas reais.
