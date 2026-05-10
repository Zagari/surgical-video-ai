"""
Endpoints de informações sobre o modelo e dataset.
"""
from fastapi import APIRouter
from typing import Dict, Any, List
from pydantic import BaseModel

router = APIRouter()


class ClassInfo(BaseModel):
    id: int
    name: str
    description: str


MODEL_INFO = {
    "name": "YOLOv8m - Surgical Detection",
    "version": "1.0",
    "architecture": "YOLOv8m (Ultralytics)",
    "input_size": 640,
    "training_dataset": "CholecSeg8k",
    "validation_dataset": "GynSurg Action Recognition",
    "classes": [
        {"id": 0, "name": "grasper", "description": "Pinça de apreensão cirúrgica"},
        {"id": 1, "name": "blood", "description": "Sangramento detectado"},
    ],
}

DATASET_INFO = {
    "training": {
        "name": "CholecSeg8k",
        "description": "Dataset de colecistectomia laparoscópica com máscaras de segmentação",
        "total_images": 8080,
        "train_images": 6464,
        "val_images": 1616,
        "classes": {
            "grasper": {"instances": 13680, "description": "Pinça de apreensão"},
            "blood": {"instances": 2545, "description": "Áreas de sangramento"}
        },
        "resolution": "Variable",
        "source": "Kaggle - CholecSeg8k",
        "purpose": "Treinamento do modelo de detecção"
    },
    "validation": {
        "name": "GynSurg Action Recognition",
        "description": "Clips de cirurgias ginecológicas laparoscópicas",
        "bleeding_clips": 977,
        "non_bleeding_clips": 1064,
        "sample_clips": {
            "bleeding": 50,
            "non_bleeding": 54
        },
        "resolution": "3840x2160 (4K)",
        "fps": 30,
        "clip_duration_seconds": 3,
        "source": "Medical University of Vienna / Toronto",
        "purpose": "Validação cross-dataset e demonstração",
        "license": "CC BY-NC-ND 4.0"
    }
}

TRAINING_METRICS = {
    "model": "YOLOv8m",
    "epochs": 100,
    "batch_size": 16,
    "image_size": 640,
    "optimizer": "AdamW",
    "metrics": {
        "mAP50": None,  # Será atualizado após treinamento
        "mAP50-95": None,
        "precision": None,
        "recall": None
    },
    "training_time": "~3-4 hours (NVIDIA RTX A5000)",
    "note": "Métricas serão atualizadas após conclusão do treinamento"
}

PROJECT_INFO = {
    "name": "Surgical Video AI",
    "description": "Sistema de análise de vídeos cirúrgicos para detecção de sangramento e instrumentos",
    "challenge": "FIAP Tech Challenge - Fase 4: Análise de Dados",
    "objective": "Monitoramento de saúde da mulher através de análise de vídeos de cirurgias ginecológicas",
    "features": [
        "Detecção de sangramento anômalo em tempo real",
        "Identificação de instrumentos cirúrgicos",
        "Processamento de vídeos via upload ou URL",
        "Galeria de clips de exemplo para demonstração",
        "Relatórios automáticos de detecção"
    ],
    "tech_stack": {
        "ml": "YOLOv8 (Ultralytics), PyTorch",
        "backend": "FastAPI, Python 3.10+",
        "frontend": "HTML, CSS, JavaScript",
        "infrastructure": "Docker, AWS S3, Terraform"
    },
    "repository": "https://github.com/Zagari/surgical-video-ai"
}


@router.get("/model")
async def get_model_info() -> Dict[str, Any]:
    """Informações sobre o modelo."""
    return MODEL_INFO


@router.get("/dataset")
async def get_dataset_info() -> Dict[str, Any]:
    """Informações sobre os datasets usados."""
    return DATASET_INFO


@router.get("/metrics")
async def get_training_metrics() -> Dict[str, Any]:
    """Métricas de treinamento."""
    return TRAINING_METRICS


@router.get("/classes")
async def get_classes() -> List[ClassInfo]:
    """Lista de classes detectadas."""
    return [ClassInfo(**c) for c in MODEL_INFO["classes"]]


@router.get("/project")
async def get_project_info() -> Dict[str, Any]:
    """Informações sobre o projeto."""
    return PROJECT_INFO


@router.get("/strategy")
async def get_strategy() -> Dict[str, Any]:
    """Explica a estratégia cross-dataset utilizada."""
    return {
        "title": "Estratégia Cross-Dataset",
        "description": "Validação da capacidade de generalização do modelo",
        "approach": {
            "training": {
                "dataset": "CholecSeg8k",
                "type": "Colecistectomia laparoscópica",
                "annotations": "Máscaras de segmentação pixel-level",
                "rationale": "Anotações precisas para treinar detecção de objetos"
            },
            "validation": {
                "dataset": "GynSurg",
                "type": "Cirurgias ginecológicas laparoscópicas",
                "annotations": "Labels de vídeo (bleeding/non-bleeding)",
                "rationale": "Validar generalização em procedimentos ginecológicos reais"
            }
        },
        "benefits": [
            "Demonstra que o modelo aprende padrões universais de sangramento",
            "Valida aplicabilidade em diferentes tipos de cirurgia laparoscópica",
            "Simula cenário real onde modelo é usado em dados não vistos durante treino"
        ]
    }
