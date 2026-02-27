# TechChallenge 🔧🚀

> Instruções e setup para execução local com Docker Compose.

---

## 🧩 Visão Geral do Projeto

Este repositório descreve uma **arquitetura de microsserviços** composta por cinco componentes principais:

| Serviço            | Linguagem | Papel principal                    |
|-------------------|-----------|------------------------------------|
| `auth-service`    | Go        | Autenticação e gestão de usuários |
| `flag-service`    | Python    | Gestão de flags/desafios          |
| `targeting-service`| Python   | Direcionamento de conteúdo        |
| `evaluation-service`| Go      | Avaliação de soluções (fila SQS)  |
| `analytics-service`| Python   | Análise de eventos                |

### 🛠 Infraestrutura de Suporte

- **PostgreSQL**: instâncias dedicadas para cada serviço (auth, flag, targeting)
- **Redis**: cache para avaliações
- **LocalStack**: simulação de serviços AWS (SQS, DynamoDB) para desenvolvimento

---

## 🚀 Como Começar

### 1. Pré-requisitos

- Docker & Docker Compose instalados
- (Opcional) AWS CLI para configurar o LocalStack

### 2. Preparando o repositório

```bash
git clone <url-do-repo>
cd challenge
```

### 3. Build das imagens (opcional)

O `docker-compose` já faz o build automático, mas você pode executar manualmente:

```bash
make build-all
# ou

docker build -t auth-service:local ./auth-service
docker build -t flag-service:local ./flag-service
docker build -t targeting-service:local ./targeting-service
docker build -t evaluation-service:local ./evaluation-service
docker build -t analytics-service:local ./analytics-service
```

### 4. Iniciando a arquitetura

```bash
docker-compose up -d
```

Isso criará as redes, volumes e conterá todos os serviços.

### 5. Verificando o estado

```bash
docker-compose ps
```

Deve retornar algo como:

```
auth-service (UP)
flag-service (UP)
targeting-service (UP)
evaluation-service (UP)
analytics-service (UP)
redis (UP)
localstack (UP)
auth-db (UP)
flag-db (UP)
target-db (UP)
```

---

## 🌐 Endpoints dos Serviços (dev)

| Serviço            | URL local                |
|-------------------|--------------------------|
| Auth              | `http://localhost:8001`  |
| Flag              | `http://localhost:8002`  |
| Targeting         | `http://localhost:8003`  |
| Evaluation        | `http://localhost:8004`  |
| Analytics         | `http://localhost:8005`  |

---

## 🧪 Setup do LocalStack (SQS + DynamoDB)

O `evaluation-service` depende de uma fila SQS e de uma tabela DynamoDB. Use o script automatizado:

```bash
bash setup-localstack.sh
```

Ou configure manualmente:

```bash
# checar saúde
curl http://localhost:4566/_localstack/health

# criar fila
aws sqs create-queue --queue-name queue --region us-east-1 \
  --endpoint-url http://localhost:4566

# criar tabela DynamoDB
aws dynamodb create-table --table-name analytics \
  --attribute-definitions AttributeName=event_id,AttributeType=S \
  --key-schema AttributeName=event_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1 \
  --endpoint-url http://localhost:4566
```

---

## 📌 Comandos Úteis

- Ver logs de todos os serviços:
  ```bash
docker-compose logs -f
```

- Logs de um serviço específico:
  ```bash
docker-compose logs -f auth-service
```

- Parar todos os serviços:
  ```bash
docker-compose down
```

- Parar e remover volumes (atenção: perde dados):
  ```bash
docker-compose down -v
```

- Reiniciar um serviço:
  ```bash
docker-compose restart auth-service
```

- Acessar um shell dentro de um container:
  ```bash
docker-compose exec auth-service bash
```

- Reconstruir imagem direta:
  ```bash
docker-compose build auth-service --no-cache
```

- Atualizar após alterações de código:
  ```bash
docker-compose down
  docker-compose up -d
```

---

## 🔐 Variáveis de Ambiente

As configurações estão declaradas no `docker-compose.yml` de cada serviço.

**Auth-service**

- `PORT=8000`
- `DATABASE_URL=postgres://auth:auth@auth-db:5432/authdb`
- `MASTER_KEY=admin-secreto-123`

**Flag-service**

- `PORT=8000`
- `DATABASE_URL=postgres://flag:flag@flag-db:5432/flagdb`
- `AUTH_SERVICE_URL=http://auth-service:8000`

**Targeting-service**

- `PORT=8000`
- `DATABASE_URL=postgres://target:target@target-db:5432/targetdb`
- `AUTH_SERVICE_URL=http://auth-service:8000`

**Evaluation-service**

- `PORT=8000`
- `REDIS_URL=redis://redis:6379`
- `AWS_SQS_URL=http://localstack:4566/000000000000/queue`
- `AWS_REGION=us-east-1`
- `AWS_ACCESS_KEY_ID=test`
- `AWS_SECRET_ACCESS_KEY=test`
- `FLAG_SERVICE_URL=http://flag-service:8000`
- `TARGETING_SERVICE_URL=http://targeting-service:8000`

**Analytics-service**

- `PORT=8000`
- `AWS_ACCESS_KEY_ID=test`
- `AWS_SECRET_ACCESS_KEY=test`
- `AWS_DYNAMODB_TABLE=analytics`
- `AWS_SQS_URL=http://localstack:4566/000000000000/queue`
- `AWS_REGION=us-east-1`

---

## 🗄️ Acesso aos Bancos de Dados

**PostgreSQL (Auth DB)**

```bash
psql -h localhost -U auth -d authdb
```

**PostgreSQL (Flag DB)**

```bash
psql -h localhost -U flag -d flagdb
```

**PostgreSQL (Target DB)**

```bash
psql -h localhost -U target -d targetdb
```

**Redis**

```bash
redis-cli -h localhost -p 6379
```

**LocalStack**

Endpoint principal: `http://localhost:4566`

---

## 📄 Licença

Este projeto é fornecido "como está" sem garantia. Use-o conforme necessário.

---

_Sinta-se à vontade para editar este README e manter a documentação atualizada!_
