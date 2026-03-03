# 📑 Índice - Tech Challenge Kubernetes Manifests

## 📁 Estrutura de Diretórios

```
k8s/
├── README.md                    # 📖 Guia completo de deployment
├── ARCHITECTURE.md              # 🏗️  Visão geral da arquitetura
├── BEST_PRACTICES.md           # 🔐 Segurança e melhores práticas
├── TESTING.md                  # 🧪 Testes de API e integração
├── CHEATSHEET.md               # 📖 Referência rápida de comandos
├── INDEX.md                    # 📑 Este arquivo
├── Makefile                    # 🔧 Automação de comandos
├── deploy.sh                   # 🚀 Script de deployment
├── validate.sh                 # 🔍 Validador de YAML
├── cleanup.sh                  # 🗑️  Script de limpeza
├── troubleshoot.sh             # 🛠️  Ferramentas de debug
│
├── namespace.yaml              # 🏷️  Namespaces base
├── ingress.yaml                # 🌐 Ingress com roteamento
│
├── auth-service/
│   ├── secret.yaml            # 🔐 Master key + database URL
│   ├── configmap.yaml         # ⚙️  PORT e LOG_LEVEL
│   ├── deployment.yaml        # 📦 2 replicas, probes, recursos
│   └── service.yaml           # 🔌 ClusterIP service
│
├── flag-service/
│   ├── secret.yaml            # 🔐 Database URL
│   ├── configmap.yaml         # ⚙️  CONFIG + AUTH_SERVICE_URL
│   ├── deployment.yaml        # 📦 2 replicas, probes, recursos
│   └── service.yaml           # 🔌 ClusterIP service
│
├── targeting-service/
│   ├── secret.yaml            # 🔐 Database URL
│   ├── configmap.yaml         # ⚙️  CONFIG + AUTH_SERVICE_URL
│   ├── deployment.yaml        # 📦 2 replicas, probes, recursos
│   └── service.yaml           # 🔌 ClusterIP service
│
├── evaluation-service/
│   ├── secret.yaml            # 🔐 Redis, AWS credentials
│   ├── configmap.yaml         # ⚙️  AWS_*, SERVICE URLs
│   ├── deployment.yaml        # 📦 2 replicas, probes, recursos
│   └── service.yaml           # 🔌 ClusterIP service
│
├── analytics-service/
│   ├── secret.yaml            # 🔐 AWS credentials
│   ├── configmap.yaml         # ⚙️  AWS_*, SQS, DynamoDB
│   ├── deployment.yaml        # 📦 2 replicas, probes, recursos
│   └── service.yaml           # 🔌 ClusterIP service
│
└── databases/
    ├── auth-db.yaml           # 🐘 PostgreSQL + Secret + Service
    ├── flag-db.yaml           # 🐘 PostgreSQL + Secret + Service
    ├── target-db.yaml         # 🐘 PostgreSQL + Secret + Service
    └── redis.yaml             # 🔴 Redis + Service
```

---

## 📚 Guias por Tópico

### 🚀 Começar
1. Ler [README.md](README.md) - Visão geral e pré-requisitos
2. Ler [ARCHITECTURE.md](ARCHITECTURE.md) - Entender a arquitetura
3. Executar `./validate.sh` - Validar manifestos
4. Executar `./deploy.sh 123456789012` - Deploy

### 🔧 Operações Diárias
- Ver [CHEATSHEET.md](CHEATSHEET.md) para comandos úteis
- Usar `make` para automação (ver [Makefile](Makefile))
- Usar `./troubleshoot.sh` para debugging

### 🧪 Testes
- [TESTING.md](TESTING.md) - Testes de API, carga, integração

### 🔐 Produção
- [BEST_PRACTICES.md](BEST_PRACTICES.md) - Segurança, RBAC, Network Policies

---

## 🎯 Tarefas Comuns

### Deploy
```bash
cd k8s

# Validar antes
./validate.sh

# Fazer deploy
./deploy.sh 123456789012  # Seu ECR Account ID

# Ou usar Make
make deploy ECR_ID=123456789012
```

### Monitorar
```bash
# Status geral
kubectl get pods -n tech-challenge

# Logs
kubectl logs -f deployment/auth-service -n tech-challenge

# Ou usar scripts/make
./troubleshoot.sh status
make status

# Port-forward
make forward SERVICE=auth-service PORT=8001
```

### Testar Conectividade
```bash
./troubleshoot.sh connectivity

# Ou
make test-connectivity
```

### Teste de Banco de Dados
```bash
./troubleshoot.sh dbtest auth
make test-db DB=auth
```

### Cleanup
```bash
./cleanup.sh

# Ou
make clean
```

---

## 📋 Checklist de Deployment

- [ ] Atualizar ECR Account ID em todos os deployments
- [ ] Validar YAML com `./validate.sh`
- [ ] Aplicar namespaces: `kubectl apply -f namespace.yaml`
- [ ] Deploy bancos de dados: `kubectl apply -f databases/`
- [ ] Deploy microsserviços: `kubectl apply -f *-service/`
- [ ] Deploy ingress: `kubectl apply -f ingress.yaml`
- [ ] Verificar status: `kubectl get pods -n tech-challenge`
- [ ] Testar endpoints com curl ou Postman
- [ ] Configurar DNS/hosts para `api.techChallenge.local`
- [ ] Setup monitoring (Prometheus/Grafana) - opcional
- [ ] Setup logging (ELK/CloudWatch) - opcional

---

## 🔍 Estrutura dos Recursos Kubernetes

### Por Namespace

#### tech-challenge (Microsserviços)
```
Deployments:     5 (auth, flag, targeting, evaluation, analytics) + 1 (redis)
Services:        6 (1 por serviço) + 1 (redis)
Pods:           12 (2 replicas por deployment)
Secrets:         5 (1 por serviço)
ConfigMaps:      5 (1 por serviço)
Ingress:         1 (api-gateway)
```

#### tech-challenge-db (Bancos de Dados)
```
Deployments:     3 (auth-db, flag-db, target-db)
Services:        3 (1 por database)
Pods:            3 (1 pod por database)
Secrets:         3 (credenciais)
ConfigMaps:      3 (init scripts)
```

---

## 💾 Recursos de Cluster

```
Minimum Required:
- 4 CPU cores total
- 8 GB RAM total
- 20 GB disk space

Recommended:
- 1 Master Node (2 CPU, 4 GB RAM)
- 2+ Worker Nodes (2+ CPU, 4+ GB RAM each)
```

---

## 📖 Formato dos Arquivos

### secret.yaml
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <service>-secret
  namespace: tech-challenge
type: Opaque
data:
  key: <base64-encoded-value>
```

### configmap.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: <service>-config
  namespace: tech-challenge
data:
  KEY: "value"
  URL: "http://service.namespace.svc.cluster.local:port"
```

### deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <service>
  namespace: tech-challenge
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: <service>
  template:
    metadata:
      labels:
        app: <service>
    spec:
      containers:
        - name: <service>
          image: ECR_URL:tag
          ports:
            - containerPort: 8000
          env:
            - name: KEY
              valueFrom:
                configMapKeyRef: ...
                secretKeyRef: ...
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /health
              port: 8000
          readinessProbe:
            httpGet:
              path: /health
              port: 8000
```

### service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <service>
  namespace: tech-challenge
spec:
  type: ClusterIP
  selector:
    app: <service>
  ports:
    - port: 8000
      targetPort: 8000
```

---

## 🔐 Valores de Secrets (Base64)

### auth-service-secret
```
master-key: admin-secreto-123
database-url: postgres://auth:auth@auth-db.tech-challenge-db.svc.cluster.local:5432/authdb
```

### flag-service-secret
```
database-url: postgres://flag:flag@flag-db.tech-challenge-db.svc.cluster.local:5432/flagdb
```

### targeting-service-secret
```
database-url: postgres://target:target@target-db.tech-challenge-db.svc.cluster.local:5432/targetdb
```

### evaluation-service-secret
```
redis-url: redis://redis.tech-challenge.svc.cluster.local:6379
aws-access-key-id: test
aws-secret-access-key: test
service-api-key: tm_key_9babda464b5cc9ce83c368c30a4e048eafc0c10e19f2cd240f66e3b85176a164
```

### analytics-service-secret
```
aws-access-key-id: test
aws-secret-access-key: test
```

---

## 🛠️ Scripts Disponíveis

### deploy.sh
Automatiza todo o processo de deployment com validações.
```bash
./deploy.sh <ECR_ACCOUNT_ID> [ECR_REGION]
```

### validate.sh
Valida todos os manifestos YAML.
```bash
./validate.sh
```

### cleanup.sh
Remove todos os recursos do cluster.
```bash
./cleanup.sh
```

### troubleshoot.sh
Ferramentas interativas para debugging.
```bash
./troubleshoot.sh [comando] [argumentos]
./troubleshoot.sh status
./troubleshoot.sh logs <service>
./troubleshoot.sh connectivity
```

---

## 🔗 Ingress Rules

```
/auth         → auth-service:8000
/flags        → flag-service:8000
/flag         → flag-service:8000
/targets      → targeting-service:8000
/targeting    → targeting-service:8000
/evaluations  → evaluation-service:8000
/evaluate     → evaluation-service:8000
/analytics    → analytics-service:8000
```

---

## 📞 Suporte

Para resolver problemas, consulte:
1. [README.md](README.md#troubleshooting) - Troubleshooting básico
2. [BEST_PRACTICES.md](BEST_PRACTICES.md) - Segurança e otimização
3. [CHEATSHEET.md](CHEATSHEET.md#troubleshooting) - Comandos de debug

---

**Versão:** 1.0
**Atualizado:** 2024
**Documentação:** Complete
