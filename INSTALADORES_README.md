# 🚀 Guia Rápido: Instalação de Kubernetes no Fedora

## 📋 Resumo

Você tem 3 formas de instalar Kubernetes no Fedora:

| Opção | Comando | Tempo | Uso |
|-------|---------|-------|-----|
| **MINIKUBE** ⭐ | `./install-minikube.sh` | 5-10 min | Desenvolvimento (RECOMENDADO) |
| **KIND** | `./install-kind.sh` | 3-5 min | CI/CD, Testes |
| **WSL2** 🪟 | `./install-wsl.sh` | 5 min | Se você está em WSL + Root |
| **KUBEADM** | Manual | 20-30 min | Produção |

---

## 🚀 Opção 1: MINIKUBE (⭐ Recomendado)

### Passo 1: Menu Interativo (Mais Fácil)
```bash
./install-kubernetes.sh
```
Selecione `1 - MINIKUBE` e siga as instruções.

### Passo 2: Ou Execute Diretamente
```bash
./install-minikube.sh
```

### Passo 3: Aguarde a Instalação
- Docker será instalado
- Minikube será instalado
- kubectl será instalado
- Cluster será inicializado (2-3 minutos)

### Passo 4: Verifique
```bash
./test-kubernetes-setup.sh
```

---

## 🐳 Opção 2: KIND (Kubernetes in Docker)

### Passo 1: Menu Interativo
```bash
./install-kubernetes.sh
```
Selecione `2 - KIND`.

### Passo 2: Ou Execute Diretamente
```bash
./install-kind.sh
```

### Passo 3: Aguarde a Instalação
- Docker será instalado (se não tiver)
- KIND será instalado
- kubectl será instalado
- Cluster será criado com 3 nodes (1 control-plane, 2 workers)

### Passo 4: Verifique
```bash
./test-kubernetes-setup.sh
```

---

## 🪟 Opção 3: WSL2 (Windows Subsystem Linux)

Se você está em **WSL** com usuário **root**:

### Passo 1: Menu Interativo
```bash
./install-kubernetes.sh
```
Selecione `3 - WSL2`.

### Passo 2: Ou Execute Diretamente
```bash
./install-wsl.sh
```

### Passo 3: Aguarde a Instalação
- Docker será configurado
- KIND será instalado (melhor para WSL)
- kubectl será instalado
- Cluster será criado com 3 nodes

### Passo 4: Verifique
```bash
./test-kubernetes-setup.sh
```

### Passo 5: Acessar de Windows
Para acessar seu cluster do navegador do Windows:
```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 80:80 &
```

Depois acesse: `http://localhost`

---

## 🔧 Opção 4: KUBEADM (Produção)

Leia o arquivo **INSTALAR_KUBERNETES.md** seção "KUBEADM" para instruções detalhadas.

Requer instalação manual de várias componentes.

---

## ✅ Após a Instalação

### 1️⃣ Verifique a Instalação
```bash
./test-kubernetes-setup.sh
```
Você deve ver tudo em verde ✅

### 2️⃣ Navegue para os Manifestos
```bash
cd k8s
```

### 3️⃣ Valide os Manifestos
```bash
./validate.sh
```

### 4️⃣ Implante seus Serviços
```bash
./deploy.sh 123456789012  # Substitua pelo seu AWS Account ID
```

### 5️⃣ Verifique o Status
```bash
kubectl get pods -n tech-challenge
```

---

## 🆘 Resolução de Problemas

### Docker não está rodando
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Minikube não inicia
```bash
minikube delete  # Reset
minikube start   # Reinicia
```

### KIND cluster não sobe
```bash
kind delete cluster    # Remove cluster antigo
./install-kind.sh      # Recria
```

### Permissão negada ao executar docker
```bash
newgrp docker
# OU faça logout e login
```

### Virtualização não disponível
```bash
grep -E 'vmx|svm' /proc/cpuinfo
```
Se não houver saída, **ative no BIOS** da sua máquina.

---

## 📚 Documentação Completa

- **COMECE_AQUI.md** - Guia rápido 5 minutos
- **README.md** - Documentação completa
- **INSTALAR_KUBERNETES.md** - Todas as opções
- **CHEATSHEET.md** - Comandos úteis kubectl
- **ARCHITECTURE.md** - Arquitetura do projeto

---

## 🎯 Fluxo Recomendado

```
1. Execute ./install-kubernetes.sh
   ↓
2. Escolha "1 - MINIKUBE"
   ↓
3. Aguarde conclusão (5-10 minutos)
   ↓
4. Execute ./test-kubernetes-setup.sh
   ↓
5. Tudo em verde? Parabéns! 🎉
   ↓
6. cd k8s && ./deploy.sh 123456789012
   ↓
7. kubectl get pods -n tech-challenge
   ↓
8. Veja seus serviços rodando!
```

---

## 💡 Dicas

- **Primeira instalação?** Use Minikube - é o mais simples
- **CI/CD pipeline?** Use KIND - é mais leve
- **Ambiente de produção?** Use Kubeadm - mais controle

---

## 📞 Precisa de Ajuda?

1. Execute: `./test-kubernetes-setup.sh` → Veja qual teste falhou
2. Leia: **INSTALAR_KUBERNETES.md** → Mais detalhes
3. Verifique: **README.md** → Troubleshooting completo

---

**Escrito em:** 2024-03-03

**Atualizado:** Março de 2024

**Status:** ✅ Pronto para uso
