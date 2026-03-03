# 🪟 Guia Especial: Kubernetes em WSL2 com Root

## ⚠️ Sua Situação

- ✅ Você está em **WSL2** (Windows Subsystem for Linux)
- ✅ Você está com usuário **root**
- ✅ Isso é **OK** - muitos desenvolvedores usam assim

---

## 🎯 Recomendação

Use **KIND** em vez de Minikube em WSL:

```bash
./install-kind.sh
```

**Por que KIND é melhor em WSL:**
- Mais leve
- Menos problemas de VM
- Mais rápido
- Docker nativo funciona melhor

---

## 🚀 Passo a Passo para WSL

### 1️⃣ Verifique Docker
```bash
docker --version
```

Se não tiver, instale:
```bash
apt update
apt install -y docker.io
service docker start
```

### 2️⃣ Instale KIND com Root
```bash
cd /root/fiap/techChallenge/fase2/challenge
./install-kind.sh
```

### 3️⃣ Aguarde Instalação
- kubectl será instalado
- KIND será instalado
- Cluster K8s será criado (2-3 min)

### 4️⃣ Teste a Instalação
```bash
./test-kubernetes-setup.sh
```

Todos em **VERDE ✅**?

### 5️⃣ Implante Seus Serviços
```bash
cd k8s
./validate.sh
./deploy.sh 123456789012  # Seu AWS ID
```

---

## ⚡ WSL-Specific Issues & Solutions

### Problema: Docker não inicia
```bash
service docker start
```

### Problema: Permissão de docker
Como você está como root, pule o `usermod -aG docker`:
```bash
# Não precisa fazer newgrp docker como root
```

### Problema: WSL não tem `/proc/cpuinfo` com vmx/svm
```bash
# Isso é normal em WSL
# KIND vai funcionar mesmo assim
```

### Problema: Rede local não funciona
WSL pode ter problemas de networking. Adicione ao `/etc/wsl.conf`:
```ini
[interop]
enabled = true
appendWindowsPath = true

[network]
generateHosts = true
generateResolvConf = true
```

Depois reinicie WSL:
```bash
wsl --shutdown
```

---

## 🔧 Alternativas em WSL

### ✅ KIND (Recomendado)
```bash
./install-kind.sh
```

### ⚠️ Minikube (Pode funcionar)
```bash
./install-minikube.sh
```

### ❌ Kubeadm (Não recomendado em WSL)
Muito complexo para WSL

---

## 📊 Verificar WSL Version

```bash
wsl --list --verbose
```

Você deve ter **WSL 2** (não WSL 1):
```
NAME      STATE           VERSION
Ubuntu    Running         2
```

Se for WSL 1, atualize:
```powershell
# No PowerShell (como admin):
wsl --set-version Ubuntu 2
```

---

## 💾 Salvar Portas Usadas

KIND usa docker, então acesse via `localhost`:

```bash
# Port-forward para trafico HTTP
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 80:80 &

# Port-forward para trafico HTTPS  
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 443:443 &
```

Então acesse do Windows:
```
http://localhost:80/auth/status
http://localhost:80/flags/list
```

---

## 🐳 Docker em WSL

Como root, seu docker já está acessível:

```bash
docker ps
docker images
docker logs container-name
```

---

## 🎯 Quick Checklist WSL

- ✅ WSL 2 instalado
- ✅ Docker funcionando
- ✅ Root user OK
- ✅ KIND rodando
- ✅ kubectl acessível
- ✅ Cluster criado
- ✅ Serviços implantados

---

## ❓ Erros Comuns em WSL

### "field ports not found in type v1alpha4.Node" (KIND YAML Error)
**Solução já aplicada** - scripts foram corrigidos
```bash
# Se você ainda perder esse erro, a solução é:
# Usar extraPortMappings ao invés de ports no YAML:

kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kind
nodes:
  - role: control-plane
    extraPortMappings:  ← CORRETO
      - containerPort: 80
        hostPort: 80
```

### "Permission denied"
- Você é root, então não deve ter esse erro
- Se tiver: `chmod +x arquivo.sh`

### "Cannot connect to Docker"
```bash
service docker start
```

### "WSL interop disabled"
Ative em `/etc/wsl.conf`:
```ini
[interop]
enabled = true
```

### "Network timeout"
WSL às vezes tem delay de rede. Aguarde 30 segundos e tente novamente.

### "kind: command not found"
```bash
# KIND não instalou corretamente? Tente:
which kind
# Se não encontrar:
curl -Lo /usr/local/bin/kind \
  https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x /usr/local/bin/kind
```

### "Docker socket error"
```bash
# Docker não está conectado
ls -la /var/run/docker.sock

# Inicie Docker:
service docker start

# Se persistir:
dockerd &
```

---

## 📚 Documentação Geral Ainda Válida

Toda a documentação em:
- `QUICK_START.md`
- `k8s/COMECE_AQUI.md`
- `k8s/README.md`

Funciona normal!

---

## 🚀 COMECE AGORA

```bash
cd /root/fiap/techChallenge/fase2/challenge
./install-kind.sh
```

Pronto! Em 5 minutos você terá Kubernetes rodando em WSL! 🎉

---

**Data:** Março 2026  
**Status:** ✅ Otimizado para WSL + Root  
**Testado em:** WSL 2 Ubuntu / Docker
