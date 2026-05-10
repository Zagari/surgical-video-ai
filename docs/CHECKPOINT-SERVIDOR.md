# Checkpoint: Configuração do Servidor para Treinamento

**Data:** 2026-05-09
**Status:** Pronto para executar no servidor

---

## Resumo do Progresso

### ✅ Concluído
1. Repositório criado: https://github.com/Zagari/surgical-video-ai
2. Dataset CholecSeg8k preparado (8.080 imagens → formato YOLO)
3. AWS S3 configurado (3 buckets criados via Terraform)
4. Dataset enviado para S3 (726 MB, 16.161 arquivos)
5. Scripts para servidor criados

### ⏳ Próximo Passo
Executar treinamento no servidor Ubuntu com GPU

---

## O que fazer no servidor

### Pré-requisitos
- Servidor Ubuntu com GPU NVIDIA
- Drivers NVIDIA instalados (`nvidia-smi` deve funcionar)
- Acesso SSH ao servidor

### Passo a Passo

```bash
# 1. Copiar scripts para o servidor (do seu Mac)
scp -r ~/Dropbox/Cursos/Pos\ FIAP/Fase\ 4/Desafio/surgical-video-ai/scripts/ usuario@servidor:~/

# 2. Conectar ao servidor
ssh usuario@servidor

# 3. Tornar scripts executáveis
chmod +x ~/scripts/server-*.sh

# 4. Executar setup (instala Python, PyTorch, YOLO)
cd ~/scripts
./server-setup.sh

# 5. Configurar AWS CLI
aws configure
# Access Key ID: [pegar no AWS Console]
# Secret Access Key: [pegar no AWS Console]
# Default region: us-east-1
# Default output format: json

# 6. Iniciar treinamento (~2-4 horas)
./server-train.sh

# 7. Após treino, testar inferência
./server-inference.sh video_teste.mp4
```

---

## Recursos AWS Ativos

| Recurso | Nome | Conteúdo |
|---------|------|----------|
| S3 | surgical-detection-datasets-dev | Dataset YOLO (726 MB) |
| S3 | surgical-detection-models-dev | (vazio, receberá modelo treinado) |
| S3 | surgical-detection-results-dev | (vazio, receberá resultados) |

**Custo atual:** < $0.05/mês (apenas S3)

---

## Arquivos Importantes

```
surgical-video-ai/
├── scripts/
│   ├── server-setup.sh      # Setup do ambiente
│   ├── server-train.sh      # Treinamento YOLOv8
│   └── server-inference.sh  # Inferência em vídeos
├── data/yolo_format/        # Dataset local (backup)
│   ├── train/               # 6.464 imagens
│   └── val/                 # 1.616 imagens
└── src/                     # Código Python
```

---

## Estatísticas do Dataset

| Classe | Treino | Validação |
|--------|--------|-----------|
| Grasper | 10.962 | 2.718 |
| Blood | 2.044 | 501 |

---

## Após o Treinamento

O modelo treinado será salvo em:
- **S3:** `s3://surgical-detection-models-dev/trained/best.pt`
- **Local no servidor:** `~/surgical-training/results/surgical_detection/weights/best.pt`

Para baixar o modelo treinado para seu Mac:
```bash
aws s3 cp s3://surgical-detection-models-dev/trained/best.pt ./models/
```
