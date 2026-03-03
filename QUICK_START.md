# ⚡ QUICK START - 5 MINUTOS PARA KUBERNETES RODANDO

## 🎯 Sua Situação

- ✅ **WSL2** com usuário **root**? Vá para [install-wsl-guide.md](./install-wsl-guide.md)
- ❓ Fedora/Linux normal? Continue abaixo
- ❓ macOS? Use Minikube

---

## 3 passos simples

### 1️⃣ Execute o instalador
```bash
cd /root/fiap/techChallenge/fase2/challenge
./install-kubernetes.sh
```

### 2️⃣ Escolha a opção correta
```
WSL2? → Escolha: 3 (WSL2)
Fedora? → Escolha: 1 ou 2
Produção? → Escolha: 4 (Kubeadm)
```

### 3️⃣ Aguarde instalação
- Docker será instalado
- Minikube será instalado  
- kubectl será instalado
- Cluster será criado

---

## ✅ Depois de instalar, teste:

```bash
./test-kubernetes-setup.sh
```

Tudo em **verde ✅**? Parabéns! 🎉

---

## 🚀 Agora implante seus serviços:

```bash
cd k8s
./validate.sh
./deploy.sh 123456789012  # Substitua pelo seu AWS ID
```

---

## 📊 Veja seus serviços rodando:

```bash
kubectl get pods -n tech-challenge
```

Pronto! Seus 5 microsserviços estarão em **Running**! 🚀

---

**Próximas leitura recomendada:**
- [install-wsl-guide.md](./install-wsl-guide.md) - Guia WSL específico
- [INSTALADORES_README.md](./INSTALADORES_README.md) - Guia completo dos instaladores
- [COMECE_AQUI.md](./k8s/docs/COMECE_AQUI.md) - Guia rápido em português dos manifestos
