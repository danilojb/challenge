# 📖 Kubernetes Cheatsheet - Tech Challenge

## ⚡ Quick Start

```bash
# 1. Validar manifestos
cd k8s
./validate.sh

# 2. Deploy
./deploy.sh 123456789012  # Seu ECR Account ID

# 3. Verificar status
kubectl get pods -n tech-challenge
kubectl get pods -n tech-challenge-db

# 4. Port-forward
kubectl port-forward svc/auth-service 8001:8000 -n tech-challenge

# 5. Ver logs
kubectl logs -f deployment/auth-service -n tech-challenge

# 6. Remover tudo
./cleanup.sh
```

---

## 🔍 Comandos Essenciais

### Namespaces
```bash
# Criar namespace
kubectl create namespace tech-challenge

# Listar namespaces
kubectl get namespaces

# Deletar namespace
kubectl delete namespace tech-challenge
```

### Pods
```bash
# Listar pods
kubectl get pods -n tech-challenge
kubectl get pods -n tech-challenge --all-namespaces

# Descrever pod
kubectl describe pod <pod-name> -n tech-challenge

# Logs de um pod
kubectl logs <pod-name> -n tech-challenge

# Logs de um container específico (múltiplos containers)
kubectl logs <pod-name> -c <container-name> -n tech-challenge

# Logs em tempo real
kubectl logs -f <pod-name> -n tech-challenge

# Executar comando em um pod
kubectl exec -it <pod-name> -n tech-challenge -- /bin/bash

# Copiar arquivo do cluster
kubectl cp tech-challenge/<pod-name>:/app/file.txt ./file.txt
```

### Deployments
```bash
# Listar deployments
kubectl get deployments -n tech-challenge

# Descrever deployment
kubectl describe deployment <deployment-name> -n tech-challenge

# Escalar replicas
kubectl scale deployment <deployment-name> --replicas=3 -n tech-challenge

# Atualizar imagem
kubectl set image deployment/<deployment-name> \
  <container-name>=new-image:tag -n tech-challenge

# Histórico de rollout
kubectl rollout history deployment/<deployment-name> -n tech-challenge

# Rollback para versão anterior
kubectl rollout undo deployment/<deployment-name> -n tech-challenge

# Rollback para versão específica
kubectl rollout undo deployment/<deployment-name> --to-revision=2 -n tech-challenge

# Restart deployment
kubectl rollout restart deployment/<deployment-name> -n tech-challenge

# Status do rollout
kubectl rollout status deployment/<deployment-name> -n tech-challenge
```

### Services
```bash
# Listar services
kubectl get svc -n tech-challenge

# Descrever service
kubectl describe svc <service-name> -n tech-challenge

# Port-forward
kubectl port-forward svc/<service-name> 8080:8000 -n tech-challenge

# Expor service para LoadBalancer (desenvolvimento)
kubectl expose deployment <deployment> --type=LoadBalancer --port=8000 -n tech-challenge
```

### ConfigMaps
```bash
# Listar configmaps
kubectl get configmap -n tech-challenge

# Descrever configmap
kubectl describe configmap <configmap-name> -n tech-challenge

# Ver conteúdo
kubectl get configmap <configmap-name> -o yaml -n tech-challenge

# Editar configmap
kubectl edit configmap <configmap-name> -n tech-challenge

# Criar configmap
kubectl create configmap my-config --from-literal=key=value -n tech-challenge

# Deletar configmap
kubectl delete configmap <configmap-name> -n tech-challenge
```

### Secrets
```bash
# Listar secrets
kubectl get secrets -n tech-challenge

# Descrever secret
kubectl describe secret <secret-name> -n tech-challenge

# Ver valor (base64 decodificado)
kubectl get secret <secret-name> -o jsonpath='{.data.key}' | base64 -d

# Editar secret
kubectl edit secret <secret-name> -n tech-challenge

# Criar secret
kubectl create secret generic my-secret --from-literal=key=value -n tech-challenge

# Atualizar secret
kubectl patch secret <secret-name> -n tech-challenge \
  -p '{"data":{"key":"'$(echo -n "value" | base64)'"}}'
```

### Ingress
```bash
# Listar ingress
kubectl get ingress -n tech-challenge

# Descrever ingress
kubectl describe ingress <ingress-name> -n tech-challenge

# Ver ingress em YAML
kubectl get ingress <ingress-name> -o yaml -n tech-challenge

# Editar ingress
kubectl edit ingress <ingress-name> -n tech-challenge
```

### Apply/Delete
```bash
# Aplicar um arquivo
kubectl apply -f arquivo.yaml

# Aplicar um diretório
kubectl apply -f ./k8s/

# Aplicar com validação
kubectl apply -f arquivo.yaml --validate=true

# Dry-run (simular aplicação)
kubectl apply -f arquivo.yaml --dry-run=client

# Deletar usando arquivo
kubectl delete -f arquivo.yaml

# Deletar tudo em um namespace
kubectl delete all --all -n tech-challenge
```

---

## 📊 Monitoramento

### Recursos
```bash
# Top nodes
kubectl top nodes

# Top pods
kubectl top pods -n tech-challenge

# Top pods com limites
kubectl top pods -n tech-challenge --containers

# Ver requests/limits
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Eventos
```bash
# Listar eventos
kubectl get events -n tech-challenge

# Eventos ordenados por tempo
kubectl get events -n tech-challenge --sort-by='.lastTimestamp'

# Eventos em tempo real
kubectl get events -n tech-challenge -w
```

### Status
```bash
# Status geral do cluster
kubectl cluster-info

# Status dos nodes
kubectl get nodes
kubectl describe nodes

# Status do Kubernetes
kubectl get componentstatuses

# Informações sobre o cluster
kubectl version
kubectl api-resources
```

---

## 🔐 Secrets & ConfigMaps

### Codificar para Base64
```bash
# Codificar
echo -n "minha_senha" | base64
# Resultado: bWluaGFfc2VuaGE=

# Decodificar
echo "bWluaGFfc2VuaGE=" | base64 -d
# Resultado: minha_senha
```

### Criar Secrets
```bash
# Literal
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123 \
  -n tech-challenge

# De arquivo
kubectl create secret generic app-secret \
  --from-file=config.json \
  -n tech-challenge

# Docker registry
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email>
```

### Criar ConfigMaps
```bash
# Literal
kubectl create configmap app-config \
  --from-literal=app.host=localhost \
  --from-literal=app.port=8000 \
  -n tech-challenge

# De arquivo
kubectl create configmap app-config \
  --from-file=application.properties \
  -n tech-challenge

# Diretório
kubectl create configmap app-config \
  --from-file=./config/ \
  -n tech-challenge
```

---

## 🚀 Troubleshooting

### Pod não inicia
```bash
# Ver descrição
kubectl describe pod <pod-name> -n tech-challenge

# Ver logs
kubectl logs <pod-name> -n tech-challenge

# Verificar eventos
kubectl get events -n tech-challenge --sort-by='.lastTimestamp'

# Ver última linha de eventos
kubectl get events -n tech-challenge | tail -20
```

### Conectividade
```bash
# Testar DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup auth-service.tech-challenge.svc.cluster.local

# Testar conectividade
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -qO- http://auth-service.tech-challenge:8000/health

# Ping entre pods
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  ping auth-service.tech-challenge
```

### Volume issues
```bash
# Ver PVs
kubectl get pv

# Ver PVCs
kubectl get pvc -n tech-challenge

# Descrever PVC
kubectl describe pvc <pvc-name> -n tech-challenge
```

### Network policies
```bash
# Listar network policies
kubectl get networkpolicy -n tech-challenge

# Descrever network policy
kubectl describe networkpolicy <policy-name> -n tech-challenge
```

---

## 📦 YAML Tips

### Labels
```yaml
# Usar labels para organizar
metadata:
  labels:
    app: auth-service
    version: v1
    tier: backend
    environment: production

# Selector por label
selector:
  matchLabels:
    app: auth-service
```

### Annotations
```yaml
# Annotations para metadados (não usados para seleção)
metadata:
  annotations:
    description: "Auth service for Tech Challenge"
    contact: "team@example.com"
    version: "1.0.0"
```

### Recursos
```yaml
# Resources
resources:
  requests:           # Mínimo
    cpu: 100m         # Em milicores
    memory: 128Mi      # Em bytes
  limits:             # Máximo
    cpu: 500m
    memory: 512Mi
```

### Probes
```yaml
# LivenessProbe - Reinicia se falhar
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 15
  periodSeconds: 10
  failureThreshold: 3

# ReadinessProbe - Remove do LB se falhar
readinessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 2

# Exec
livenessProbe:
  exec:
    command:
      - /bin/sh
      - -c
      - pg_isready -U username
```

---

## 🎯 Workflow Típico

```bash
# 1. Editar manifestos
vim k8s/auth-service/deployment.yaml

# 2. Validar
./validate.sh

# 3. Dry-run
kubectl apply -f k8s/auth-service/deployment.yaml --dry-run=client

# 4. Aplicar
kubectl apply -f k8s/auth-service/deployment.yaml

# 5. Monitorar
kubectl rollout status deployment/auth-service -n tech-challenge

# 6. Ver logs
kubectl logs -f deployment/auth-service -n tech-challenge

# 7. Testar
kubectl port-forward svc/auth-service 8001:8000 -n tech-challenge
curl http://localhost:8001/health

# 8. Rollback se necessário
kubectl rollout undo deployment/auth-service -n tech-challenge
```

---

## 🔗 Recursos Externos

```bash
# Documentação
https://kubernetes.io/docs/

# API Reference
kubectl api-resources
kubectl explain deployment

# Kubectl plugin manager
# https://krew.sigs.k8s.io/

# Useful plugins
kubectl krew install debug
kubectl krew install ctx
kubectl krew install ns
```

---

## Pro Tips 💡

```bash
# Alias útil
alias k=kubectl
alias kn='kubectl config set-context --current --namespace'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec'

# Context útil
kubectl config current-context
kubectl config get-contexts
kubectl config use-context <context-name>

# Namespace util
kubectl config set-context --current --namespace=tech-challenge

# Watch em tempo real
kubectl get pods -n tech-challenge -w

# JSON output
kubectl get pods -n tech-challenge -o json | jq '.items[0].metadata.name'

# Wide output
kubectl get pods -n tech-challenge -o wide
```

---

**Última atualização:** 2024
