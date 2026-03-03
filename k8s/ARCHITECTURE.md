# 🏗️ Arquitetura Kubernetes - Tech Challenge

## 📐 Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                    INTERNET / EXTERNALLY                            │
│                         EXPOSED                                      │
└────────────────────┬────────────────────────────────────────────────┘
                     │
                     │ (HTTP/HTTPS)
                     ▼
        ┌────────────────────────────┐
        │    Nginx Ingress Controller │
        │  (NodePort / LoadBalancer)  │
        └────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
    /auth  /flags  /targets  /analytics  /evaluations
        │            │            │            │
        │            │            │            │
   ┌────▼─┐     ┌────▼─┐    ┌────▼─────┐  ┌────▼──────┐
   │ auth │     │ flag │    │ targeting │  │evaluation │
   │service      │service    │ service   │  │ service   │
   └────┬─┘     └────┬─┘    └────┬─────┘  └────┬──────┘
        │            │            │             │
        │ ┌──────────┼────────────┤             │
        │ │          │            │             │
        │ ▼          ▼            ▼             ▼
        ▼ (int)  (int)       (int)      ┌─────────────┐
   ┌─────────────────────────────┐     │ analytics   │
   │ PostgreSQL Databases        │     │ service     │
   ├─────────────────────────────┤     └─────────────┘
   │ auth-db    flag-db   target-db│         │
   │ (5432)     (5432)    (5432)   │         │
   └─────────────────────────────┘         │
                                            ▼
   ┌─────────────────────────────┐    ┌──────────────┐
   │    Redis Cache              │    │ AWS Services │
   │ (evaluation-service)        │    │ SQS / DynamoDB
   └─────────────────────────────┘    └──────────────┘
```

## 🔌 Conectividade

### Comunicação Intra-Cluster (DNS Kubernetes)
```
flag-service → auth-service
  http://auth-service.tech-challenge.svc.cluster.local:8000

evaluation-service → flag-service & targeting-service
  http://flag-service.tech-challenge.svc.cluster.local:8000
  http://targeting-service.tech-challenge.svc.cluster.local:8000

analytics-service → AWS (SQS / DynamoDB)
  http://localstack:4566  (desenvolvimento)
  AWS SDK com credenciais (produção)
```

### Comunicação com Databases
```
auth-service → auth-db
  postgres://auth:pass@auth-db.tech-challenge-db.svc.cluster.local:5432/authdb

flag-service → flag-db
  postgres://flag:pass@flag-db.tech-challenge-db.svc.cluster.local:5432/flagdb

targeting-service → target-db
  postgres://target:pass@target-db.tech-challenge-db.svc.cluster.local:5432/targetdb

evaluation-service → redis
  redis://redis.tech-challenge.svc.cluster.local:6379
```

## 📦 Estrutura de Recursos Kubernetes

### 1. Namespaces
```yaml
tech-challenge/           # Microsserviços
├── auth-service
├── flag-service
├── targeting-service
├── evaluation-service
├── analytics-service
└── redis

tech-challenge-db/        # Bancos de Dados
├── auth-db
├── flag-db
└── target-db
```

### 2. Deployments (5 Microsserviços)

```yaml
Deployment: auth-service
├── Replicas: 2
├── Containers: 1 (auth-service)
├── Ports: 8000
├── Resources: 100m CPU, 128Mi RAM (req) | 500m CPU, 512Mi RAM (lim)
├── Probes: Liveness + Readiness
└── ConfigMaps/Secrets: auth-service-config, auth-service-secret

Deployment: flag-service
├── Replicas: 2
├── Containers: 1 (flag-service Python)
├── Ports: 8000
├── Resources: 100m CPU, 128Mi RAM (req) | 500m CPU, 512Mi RAM (lim)
├── Probes: Liveness + Readiness
├── Env: AUTH_SERVICE_URL (ConfigMap)
└── ConfigMaps/Secrets: flag-service-config, flag-service-secret

Deployment: targeting-service
├── Replicas: 2
├── Containers: 1 (targeting-service Python)
├── Ports: 8000
├── Resources: 100m CPU, 128Mi RAM (req) | 500m CPU, 512Mi RAM (lim)
├── Probes: Liveness + Readiness
├── Env: AUTH_SERVICE_URL (ConfigMap)
└── ConfigMaps/Secrets: targeting-service-config, targeting-service-secret

Deployment: evaluation-service
├── Replicas: 2
├── Containers: 1 (evaluation-service Go)
├── Ports: 8000
├── Resources: 100m CPU, 256Mi RAM (req) | 500m CPU, 512Mi RAM (lim)
├── Probes: Liveness + Readiness
├── Env: REDIS_URL, FLAG_SERVICE_URL, TARGETING_SERVICE_URL, AWS_* (Secret/ConfigMap)
└── ConfigMaps/Secrets: evaluation-service-config, evaluation-service-secret

Deployment: analytics-service
├── Replicas: 2
├── Containers: 1 (analytics-service Python)
├── Ports: 8000
├── Resources: 100m CPU, 256Mi RAM (req) | 500m CPU, 512Mi RAM (lim)
├── Probes: Liveness + Readiness
├── Env: AWS_*, AWS_DYNAMODB_TABLE, AWS_SQS_URL (Secret/ConfigMap)
└── ConfigMaps/Secrets: analytics-service-config, analytics-service-secret
```

### 3. Deployments (Databases & Cache)

```yaml
Deployment: auth-db (PostgreSQL)
├── Replicas: 1
├── Containers: postgres:15
├── Ports: 5432
├── Resources: 100m CPU, 256Mi RAM (req) | 500m CPU, 512Mi RAM (lim)
├── Probes: Liveness + Readiness (pg_isready)
├── Storage: emptyDir (desenvolvimento)
└── SecretRef: auth-db-secret (username/password)

Deployment: flag-db (PostgreSQL)
├── Replicas: 1
├── Containers: postgres:15
├── Ports: 5432
├── Resources: 100m CPU, 256Mi RAM (req) | 500m CPU, 512Mi RAM (lim)
├── Probes: Liveness + Readiness (pg_isready)
├── Storage: emptyDir (desenvolvimento)
└── SecretRef: flag-db-secret (username/password)

Deployment: target-db (PostgreSQL)
├── Replicas: 1
├── Containers: postgres:15
├── Ports: 5432
├── Resources: 100m CPU, 256Mi RAM (req) | 500m CPU, 512Mi RAM (lim)
├── Probes: Liveness + Readiness (pg_isready)
├── Storage: emptyDir (desenvolvimento)
└── SecretRef: target-db-secret (username/password)

Deployment: redis (Redis)
├── Replicas: 1
├── Containers: redis:7-alpine
├── Ports: 6379
├── Resources: 50m CPU, 64Mi RAM (req) | 250m CPU, 256Mi RAM (lim)
├── Probes: Liveness + Readiness (redis-cli ping)
└── Storage: emptyDir (desenvolvimento)
```

### 4. Services (ClusterIP)

```yaml
Service: auth-service
├── Type: ClusterIP
├── Port: 8000
├── Selector: app=auth-service
└── DNS: auth-service.tech-challenge.svc.cluster.local

Service: flag-service
├── Type: ClusterIP
├── Port: 8000
├── Selector: app=flag-service
└── DNS: flag-service.tech-challenge.svc.cluster.local

Service: targeting-service
├── Type: ClusterIP
├── Port: 8000
├── Selector: app=targeting-service
└── DNS: targeting-service.tech-challenge.svc.cluster.local

Service: evaluation-service
├── Type: ClusterIP
├── Port: 8000
├── Selector: app=evaluation-service
└── DNS: evaluation-service.tech-challenge.svc.cluster.local

Service: analytics-service
├── Type: ClusterIP
├── Port: 8000
├── Selector: app=analytics-service
└── DNS: analytics-service.tech-challenge.svc.cluster.local

Service: redis
├── Type: ClusterIP
├── Port: 6379
├── Selector: app=redis
└── DNS: redis.tech-challenge.svc.cluster.local

Service: auth-db
├── Type: ClusterIP
├── Port: 5432
├── Selector: app=auth-db
└── DNS: auth-db.tech-challenge-db.svc.cluster.local

Service: flag-db
├── Type: ClusterIP
├── Port: 5432
├── Selector: app=flag-db
└── DNS: flag-db.tech-challenge-db.svc.cluster.local

Service: target-db
├── Type: ClusterIP
├── Port: 5432
├── Selector: app=target-db
└── DNS: target-db.tech-challenge-db.svc.cluster.local
```

### 5. Ingress

```yaml
Ingress: api-gateway
├── Class: nginx
├── Host: api.techChallenge.local
├── Rules:
│   ├── /auth → auth-service:8000
│   ├── /flags, /flag → flag-service:8000
│   ├── /targets, /targeting → targeting-service:8000
│   ├── /evaluations, /evaluate → evaluation-service:8000
│   └── /analytics → analytics-service:8000
├── Annotations:
│   ├── Rate Limit: 100 req/min
│   ├── CORS: Habilitado
│   └── TLS: Cert-manager
└── TLS: api-tls-secret (HTTPS)
```

### 6. Secrets (Base64 Encoded)

```yaml
Secret: auth-service-secret
├── master-key: YWRtaW4tc2VjcmV0by0xMjM=
└── database-url: cG9zdGdyZXM6Ly9hdXRoOmF1dGhAYXV0aC1kYi4u

Secret: flag-service-secret
└── database-url: cG9zdGdyZXM6Ly9mbGFnOmZsYWdAZmxhZy1kYi4u

Secret: targeting-service-secret
└── database-url: cG9zdGdyZXM6Ly90YXJnZXQ6dGFyZ2V0QHRhcmdldC1kYi4u

Secret: evaluation-service-secret
├── redis-url: cmVkaXM6Ly9yZWRpcy50ZWNoLWNoYWxsZW5nZS4u
├── aws-access-key-id: dGVzdA==
├── aws-secret-access-key: dGVzdA==
└── service-api-key: dG1fa2V5Xy4u

Secret: analytics-service-secret
├── aws-access-key-id: dGVzdA==
└── aws-secret-access-key: dGVzdA==

Secret: auth-db-secret / flag-db-secret / target-db-secret
├── username: <base64>
└── password: <base64>
```

### 7. ConfigMaps

```yaml
ConfigMap: auth-service-config
├── PORT=8000
└── LOG_LEVEL=info

ConfigMap: flag-service-config
├── PORT=8000
├── LOG_LEVEL=info
└── AUTH_SERVICE_URL=http://auth-service.tech-challenge.svc.cluster.local:8000

ConfigMap: targeting-service-config
├── PORT=8000
├── LOG_LEVEL=info
└── AUTH_SERVICE_URL=http://auth-service.tech-challenge.svc.cluster.local:8000

ConfigMap: evaluation-service-config
├── PORT=8000
├── LOG_LEVEL=info
├── AWS_REGION=us-east-1
├── AWS_SQS_URL=http://localstack:4566/000000000000/queue
├── FLAG_SERVICE_URL=http://flag-service.tech-challenge.svc.cluster.local:8000
└── TARGETING_SERVICE_URL=http://targeting-service.tech-challenge.svc.cluster.local:8000

ConfigMap: analytics-service-config
├── PORT=8000
├── LOG_LEVEL=info
├── AWS_REGION=us-east-1
├── AWS_DYNAMODB_TABLE=analytics
└── AWS_SQS_URL=http://localstack:4566/000000000000/queue
```

## 🎯 Dependências de Inicialização

```
namespace.yaml
    ↓
[Paralelo]
├─→ databases/*.yaml (auth-db, flag-db, target-db, redis)
│   └─→ Esperar por: Ready status
└─→ [Esperar]
    ├─→ auth-service/* (sem dependência)
    │   └─→ Esperar por: Ready status
    ├─→ flag-service/* (depende de: auth-db, auth-service)
    ├─→ targeting-service/* (depende de: target-db, auth-service)
    ├─→ evaluation-service/* (depende de: redis, flag, targeting)
    └─→ analytics-service/* (depende de: localstack)
        ↓
    ingress.yaml
```

## 📊 Resumo de Recursos

### Total por Namespace

**tech-challenge:**
- 🎯 Pods: 12 (5 serviços × 2 replicas + redis)
- 🔌 Services: 6 (5 serviços + redis)
- 📦 Deployments: 6 (5 serviços + redis)
- 🔑 Secrets: 5
- ⚙️ ConfigMaps: 5
- 🌐 Ingress: 1

**tech-challenge-db:**
- 🎯 Pods: 3 (postgres × 3)
- 🔌 Services: 3
- 📦 Deployments: 3
- 🔑 Secrets: 3
- ⚙️ ConfigMaps: 3 (init scripts)

**Total Geral:**
- 🎯 Pods: 15
- 🔌 Services: 9
- 📦 Deployments: 9
- 🔑 Secrets: 8
- ⚙️ ConfigMaps: 8
- 🌐 Ingress: 1

## 💾 Recursos de Cluster Necessários

```
CPU Total Solicitado:     0.95 cores (950m)
Memory Total Solicitado:  2.4 GiB

CPU Total Máximo:         5.5 cores (5500m)
Memory Total Máximo:      5 GiB

Recomendado:
- 1 Master node com no mínimo 2 cores e 2GiB RAM
- 2+ Worker nodes com no mínimo 2 cores e 4GiB RAM cada
```

## 🔄 Fluxo de Dados

```
1. User/Client Request
   ↓
2. Nginx Ingress (Route matching)
   ↓
3. Target Service (ClusterIP)
   ↓
4. Load Balancer (2 replicas)
   ↓
5. Application Pod
   ├─→ If Auth Required: Call auth-service
   ├─→ If Flag Check: Call flag-service
   ├─→ If Targeting: Call targeting-service
   ├─→ If Caching: Call redis
   └─→ If Data Needed: Call respective database
   ↓
6. Response back to Admin/Client
```

## 🚀 Ciclo de Vida de um Pod

```
1. Pending
   ↓
2. Init Containers (se houver)
   ↓
3. Container Start
   ↓
4. Startup Probe (se houver)
   ↓
5. Running (e Readiness Probe)
   ↓
6. Liveness Probe (contínuo)
   ↓
7. Terminating (SIGTERM) → Timeout → SIGKILL
   ↓
8. Terminated
```

---

**Última atualização:** 2024
**Versão:** 1.0
**Ambiente:** Kubernetes 1.24+
