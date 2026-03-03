# 🚀 Instalar Kubernetes no Fedora

## 1️⃣ MINIKUBE (Recomendado) ⭐

### Passo 1: Verificar Pré-requisitos

```bash
# Verificar virtualização ativada
grep -E 'vmx|svm' /proc/cpuinfo

# Se houver saída → ✅ Virtualização ativa
# Se não houver → ❌ Ativar no BIOS
```

### Passo 2: Instalar Docker (se não tiver)

```bash
# Instalar Docker no Fedora
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Iniciar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Adicionar seu usuário ao grupo docker (sem sudo)
sudo usermod -aG docker $USER

# Fazer logout e login para aplicar mudanças
logout
# ou
newgrp docker
```

### Passo 3: Instalar Minikube

```bash
# Baixar Minikube (versão mais recente)
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Verificar instalação
minikube version
```

### Passo 4: Instalar kubectl

```bash
# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Verificar instalação
kubectl version --client
```

### Passo 5: Iniciar Minikube

```bash
# Iniciar (primeira vez leva alguns minutos)
minikube start

# Usar Docker como driver (recomendado)
# minikube start --driver=docker

# Com mais recursos (se tiver)
# minikube start --cpus=4 --memory=8192

# Verificar status
minikube status
```

### Passo 6: Testar Kubectl

```bash
# Ver nodes
kubectl get nodes

# Ver pods em todos os namespaces
kubectl get pods --all-namespaces

# Dashboard (abrir em browser)
minikube dashboard
```

---

## 2️⃣ KIND (Mais Leve)

Se preferir uma alternativa mais leve que usa Docker:

```bash
# Instalar Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Criar cluster
kind create cluster

# Ver contexto
kubectl cluster-info

# Deletar cluster
kind delete cluster
```

---

## 3️⃣ KUBEADM (Profissional)

Opção mais complexa para setup real:

```bash
# Instalar no Fedora
sudo dnf install -y kubeadm kubelet kubectl

# Inicializar control plane
sudo kubeadm init

# Setup kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instalar network plugin
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Verificar
kubectl get nodes
```

---

## ⚡ Comandos Úteis Após Instalação

```bash
# Ver status do cluster
kubectl cluster-info
kubectl get nodes

# Ver versão do Kubernetes
kubectl version

# Ver contexto atual
kubectl config current-context

# Ver namespaces padrão
kubectl get namespaces

# Dashboard (Minikube)
minikube dashboard

# Parar Minikube
minikube stop

# Reiniciar
minikube start

# Deletar Minikube
minikube delete
```

---

## 🔧 Troubleshooting

### Problema: "Docker daemon is not running"
```bash
# Solução:
sudo systemctl start docker
```

### Problema: "Permission denied" ao usar docker
```bash
# Solução: Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### Problema: "VT-x/AMD-v not detected"
```bash
# Solução: Ativar virtualização no BIOS
# Reinicie o PC e entre no BIOS (Del, F2, F10, etc)
# Procure por: Virtualization Technology, Hyper-V, ou SVM
```

### Problema: "insufficient memory"
```bash
# Solução: Aumentar memória do Minikube
minikube delete
minikube start --memory=8192 --cpus=4
```

### Ver logs do Minikube
```bash
minikube logs
```

---

## ✅ Próxima Etapa

Após instalar, volte para o diretório e execute:

```bash
cd /root/fiap/techChallenge/fase2/challenge/k8s

# Validar manifestos
./validate.sh

# Fazer deploy dos seus manifestos
./deploy.sh 123456789012  # Seu ECR Account ID

# Verificar
kubectl get pods -n tech-challenge
```

---

## 📚 Referências

- [Minikube Docs](https://minikube.sigs.k8s.io/)
- [KIND Docs](https://kind.sigs.k8s.io/)
- [Kubectl Docs](https://kubernetes.io/docs/reference/kubectl/)
- [Kubernetes Docs](https://kubernetes.io/docs/)

---

**Recomendação:** Use **MINIKUBE** para começar. É a mais simples e perfeita para desenvolvimento!
