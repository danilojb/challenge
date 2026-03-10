# Ambiente Real em EKS (IRSA + KEDA) — Tópico 5

Este diretório contém os manifestos para o ambiente real na AWS (EKS), com escalabilidade profissional:
- **analytics-service** escalando por **SQS** via **KEDA** (de 0 a N pods).
- **evaluation-service** escalando por **CPU** via **HPA**.

## Pré-requisitos no computador
- AWS CLI configurado (`aws configure`)
- kubectl
- eksctl
- Helm

## Pré-requisitos na AWS
- Conta AWS com permissões para criar EKS, IAM, SQS, RDS, ElastiCache, DynamoDB, ECR.
- Cluster EKS criado com IRSA habilitado (ex.: `eksctl create cluster --with-oidc ...`).
- Repositórios ECR e serviços (RDS/Redis/DynamoDB/SQS) criados e com endpoints/ARN anotados.

## Passos essenciais antes de aplicar
1. **Instalar o Metrics Server**  
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
