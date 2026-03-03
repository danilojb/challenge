# Kubernetes Best Practices & Security Guide

## 🔐 Segurança

### 1. Secrets Management

#### ✅ O que foi implementado:
- Todos os valores sensíveis estão em `Secret` objects em base64
- Separação entre Secrets (senhas) e ConfigMaps (configurações públicas)
- Secrets referenciados via `valueFrom.secretKeyRef`

#### ❌ O que evitar:
```yaml
# ❌ ERRADO: Secret em plain text no ConfigMap
env:
  - name: DATABASE_PASSWORD
    value: "minha_senha_123"
```

#### ✅ O que fazer:
```yaml
# ✅ CORRETO: Secret em objeto separado
env:
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: password
```

### 2. RBAC (Role-Based Access Control)

```yaml
# Criar um ServiceAccount com permissões limitadas
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-reader
  namespace: tech-challenge
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-reader-role
  namespace: tech-challenge
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-reader-binding
  namespace: tech-challenge
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-reader-role
subjects:
  - kind: ServiceAccount
    name: app-reader
    namespace: tech-challenge
```

### 3. Network Policies

```yaml
# Restringir tráfego apenas entre serviços
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: tech-challenge
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
# Permitir flag-service chamar auth-service
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-flag-to-auth
  namespace: tech-challenge
spec:
  podSelector:
    matchLabels:
      app: auth-service
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: flag-service
      ports:
        - protocol: TCP
          port: 8000
```

### 4. Pod Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  seccompProfile:
    type: RuntimeDefault
```

### 5. Resource Quotas

```yaml
# Limitar recursos por namespace
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tech-challenge-quota
  namespace: tech-challenge
spec:
  hard:
    requests.cpu: "5"
    requests.memory: "5Gi"
    limits.cpu: "10"
    limits.memory: "10Gi"
    pods: "50"
```

### 6. Network Encryption (TLS)

```yaml
# Usar cert-manager para HTTPS automático
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

---

## 📊 Resource Management

### Requests vs Limits

**Requests:** Quantidade mínima garantida
**Limits:** Máximo que o pod pode usar

```yaml
resources:
  requests:
    cpu: 100m          # 0.1 CPU cores
    memory: 128Mi       # 128 Megabytes
  limits:
    cpu: 500m          # 0.5 CPU cores
    memory: 512Mi       # 512 Megabytes
```

### Dimensionamento Recomendado

| Serviço | CPU Request | Memory Request | CPU Limit | Memory Limit |
|---------|-------------|----------------|-----------|----|
| auth-service | 100m | 128Mi | 500m | 512Mi |
| flag-service | 100m | 128Mi | 500m | 512Mi |
| targeting-service | 100m | 128Mi | 500m | 512Mi |
| evaluation-service | 100m | 256Mi | 500m | 512Mi |
| analytics-service | 100m | 256Mi | 500m | 512Mi |
| auth-db | 100m | 256Mi | 500m | 512Mi |
| flag-db | 100m | 256Mi | 500m | 512Mi |
| target-db | 100m | 256Mi | 500m | 512Mi |
| redis | 50m | 64Mi | 250m | 256Mi |

---

## 🏥 Health Checks

### LivenessProbe
Reinicia o pod se falhar. Use para detectar deadlocks.

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 15    # Aguarda 15s antes da primeira verificação
  periodSeconds: 10           # Verifica a cada 10s
  timeoutSeconds: 5           # Timeout de 5s por requisição
  failureThreshold: 3         # Reinicia após 3 falhas
```

### ReadinessProbe
Remove do balanceador se falhar. Use para verificar estado da aplicação.

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 2
  successThreshold: 1
```

### Startup Probe
Aguarda a aplicação iniciar antes de outras probes.

```yaml
startupProbe:
  httpGet:
    path: /health
    port: 8000
  failureThreshold: 30        # 30 * 10s = 5 minutos para iniciar
  periodSeconds: 10
```

---

## 🚀 Deployment Strategy

### RollingUpdate (Padrão - Recomendado)
Substitui pods gradualmente, mantendo disponibilidade.

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1              # 1 pod extra durante update
    maxUnavailable: 0        # 0 pods indisponíveis
```

### Blue-Green
Manter versão antiga rodando enquanto nova é ativada.

```yaml
strategy:
  type: Recreate            # Mata tudo e recria
```

### Canary
Liberar para porcentagem dos usuários primeiro.

```yaml
# Usar Flagger + Istio para canary automático
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: auth-service
  namespace: tech-challenge
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: auth-service
  progressDeadlineSeconds: 60
  service:
    port: 8000
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 5
  metrics:
    - name: error-rate
      thresholdRange:
        max: 0.05
```

---

## 📈 Monitoring & Logging

### Prometheus Metrics

```yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-service-metrics
  namespace: tech-challenge
spec:
  ports:
    - name: metrics
      port: 9090
      targetPort: 9090
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: auth-service
  namespace: tech-challenge
spec:
  selector:
    matchLabels:
      app: auth-service
  endpoints:
    - port: metrics
      interval: 30s
```

### Logging (ELK Stack)

```bash
# Instalar ELK
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch --namespace logging
helm install kibana elastic/kibana --namespace logging
helm install logstash elastic/logstash --namespace logging

# Fluent Bit para log collection
helm repo add fluent https://fluent.github.io/helm-charts
helm install fluent-bit fluent/fluent-bit --namespace logging
```

---

## 🔄 Persistent Data

### PersistentVolume para Databases

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: auth-db-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data/auth-db
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: auth-db-pvc
  namespace: tech-challenge-db
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
```

---

## 🔐 Secrets em Produção

### Option 1: AWS Secrets Manager

```yaml
apiVersion: v1
kind: SecretProviderClass
metadata:
  name: aws-secrets
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "tech-challenge/db-password"
        objectType: "secretsmanager"
        objectAlias: "dbpassword"
```

### Option 2: HashiCorp Vault

```bash
# Instalar Vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --namespace vault --create-namespace

# Autenticar pods com Vault
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
  namespace: tech-challenge
EOF
```

### Option 3: Google Secret Manager

```bash
gcloud secrets create db-password --data-file=- <<< "your-password"

# Criar Kubernetes secret a partir do GCP secret
gcloud secrets versions access latest --secret="db-password" | \
  kubectl create secret generic db-secret \
  --from-file=password=/dev/stdin -n tech-challenge
```

---

## 🧪 Testes de Performance

### Teste de Carga

```bash
# Usando Apache Bench
ab -n 10000 -c 100 http://api.techChallenge.local/auth/health

# Usando wrk
wrk -t12 -c400 -d30s http://api.techChallenge.local/auth/health

# Usando k6
k6 run load_test.js
```

### Teste de Failover

```bash
# Simular falha de um node
kubectl drain <node-name> --delete-emptydir-data --ignore-daemonsets

# Verificar se os pods foram rescheduled
kubectl get pods -n tech-challenge -o wide

# Retornar o node ao ar
kubectl uncordon <node-name>
```

---

## 📋 Checklist de Produção

- [ ] Usar imagens específicas (não `latest`)
- [ ] Configurar Resource Requests e Limits
- [ ] Implementar Liveness e Readiness Probes
- [ ] Usar múltiplas replicas (mínimo 2)
- [ ] Configurar Pod Disruption Budgets
- [ ] Usar Persistent Volumes para dados
- [ ] Implementar Ingress com TLS
- [ ] Configurar RBAC
- [ ] Implementar Network Policies
- [ ] Configurar Monitoring e Logging
- [ ] Fazer backup dos Secrets
- [ ] Implementar GitOps (ArgoCD)
- [ ] Configurar HPA (Horizontal Pod Autoscaler)
- [ ] Testes de carga
- [ ] Plano de disaster recovery

---

## 🔗 Referências

- [Kubernetes Production Best Practices](https://kubernetes.io/docs/setup/production-environment/)
- [12 Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [OWASP Kubernetes Top 10](https://owasp.org/www-project-kubernetes-top-ten/)
