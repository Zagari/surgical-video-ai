# =============================================================================
# Training Module - EC2 Instance com GPU para Treinamento YOLOv8
# =============================================================================

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "surgical-detection"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.xlarge"  # Temporário para teste - trocar por g4dn.xlarge depois
}

variable "key_name" {
  description = "Nome da key pair SSH"
  type        = string
}

variable "datasets_bucket_arn" {
  description = "ARN do bucket de datasets"
  type        = string
}

variable "models_bucket_arn" {
  description = "ARN do bucket de modelos"
  type        = string
}

variable "results_bucket_arn" {
  description = "ARN do bucket de resultados"
  type        = string
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "aws_region" "current" {}

data "aws_ami" "deep_learning" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning OSS Nvidia Driver AMI GPU PyTorch*Ubuntu*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "training" {
  name        = "${var.project_name}-training-sg-${var.environment}"
  description = "Security group for training instance"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Saída total
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name        = "${var.project_name}-training-sg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# IAM Role para EC2
# -----------------------------------------------------------------------------
resource "aws_iam_role" "training" {
  name = "${var.project_name}-training-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
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
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          var.datasets_bucket_arn,
          "${var.datasets_bucket_arn}/*",
          var.models_bucket_arn,
          "${var.models_bucket_arn}/*",
          var.results_bucket_arn,
          "${var.results_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "training" {
  name = "${var.project_name}-training-profile-${var.environment}"
  role = aws_iam_role.training.name
}

# -----------------------------------------------------------------------------
# EC2 Instance
# -----------------------------------------------------------------------------
resource "aws_instance" "training" {
  ami                    = data.aws_ami.deep_learning.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.training.id]
  iam_instance_profile   = aws_iam_instance_profile.training.name

  root_block_device {
    volume_size = 200
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Criar diretório de trabalho
    mkdir -p /home/ubuntu/training
    cd /home/ubuntu/training

    # Criar script de treinamento
    cat > train.sh << 'TRAIN_SCRIPT'
    #!/bin/bash
    set -e

    # Ativar ambiente conda
    source /opt/conda/etc/profile.d/conda.sh
    conda activate pytorch

    # Instalar dependências
    pip install ultralytics boto3

    # Baixar dataset do S3
    echo "Baixando dataset do S3..."
    aws s3 sync s3://surgical-detection-datasets-dev/yolo_format/ ./data/

    # Treinar modelo
    echo "Iniciando treinamento..."
    yolo detect train \
      data=./data/data.yaml \
      model=yolov8m.pt \
      epochs=100 \
      imgsz=640 \
      batch=16 \
      name=surgical_detection \
      project=./results

    # Upload do modelo para S3
    echo "Fazendo upload do modelo..."
    aws s3 cp ./results/surgical_detection/weights/best.pt s3://surgical-detection-models-dev/trained/

    # Criar model.tar.gz para SageMaker
    cd ./results/surgical_detection/weights/
    tar -czvf model.tar.gz best.pt
    aws s3 cp model.tar.gz s3://surgical-detection-models-dev/trained/model.tar.gz

    echo "Treinamento concluído!"
    TRAIN_SCRIPT

    chmod +x train.sh
    chown -R ubuntu:ubuntu /home/ubuntu/training

    echo "Setup concluído. Execute: cd /home/ubuntu/training && ./train.sh"
  EOF

  tags = {
    Name        = "${var.project_name}-training-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "instance_id" {
  value = aws_instance.training.id
}

output "instance_public_ip" {
  value = aws_instance.training.public_ip
}

output "ssh_command" {
  value = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.training.public_ip}"
}
