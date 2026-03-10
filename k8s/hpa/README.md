# HPA (Horizontal Pod Autoscaler)

> **Ambiente alvo:** AWS Academy (HPA por CPU).  
> **Observação:** KEDA não é usado no Academy por limitação de IAM (IRSA).

## Como usar estes manifestos

1. **Ajuste o namespace**
   - Substitua `NAMESPACE_AJUSTAR` pelo namespace real do cluster (ex.: `togglemaster`).
   - Se não houver namespace definido, use `default`.

2. **Ajuste o nome do Deployment**
   - Em `spec.scaleTargetRef.name`, confirme o nome exato do Deployment:
     - Para o analytics: `analytics-deployment` (ou o que o grupo usou)
     - Para o evaluation: `evaluation-deployment` (ou o que o grupo usou)

3. **Pré-requisitos no cluster (quando for aplicar)**
   - Metrics Server instalado.
   - Deployments com `resources.requests/limits` de CPU e memória definidos.

4. **Aplicar (quando for usar)**
   ```bash
   kubectl apply -f k8s/hpa/hpa-analytics.yaml
   kubectl apply -f k8s/hpa/hpa-evaluation.yaml
   
# 5. Configurando a Escalabilidade (HPA – Horizontal Pod Autoscaler)

Este diretório contém os manifestos responsáveis por implementar o **Tópico 5 do Tech Challenge – Fase 2**, que trata de **escalabilidade automática** no Kubernetes usando **Horizontal Pod Autoscaler (HPA)**.

## 📌 Ambiente alvo
Este HPA foi criado para o cenário **AWS Academy**, onde:

- A escalabilidade **deve ser feita por CPU** (métrica nativa do Kubernetes).
- **KEDA não pode ser utilizado**, pois depende de permissões IAM e IRSA (não disponíveis no Academy).

## 📌 Objetivo do HPA neste projeto
Os HPAs implementados aqui servem para:

- **evaluation-service** → escalar automaticamente conforme o uso de CPU quando há alto volume de requests.
- **analytics-service** → escalar quando a CPU aumenta durante o processamento da fila SQS (workaround para o Academy).

> No Academy, o analytics *não pode* escalar diretamente baseado na fila SQS, portanto usa-se CPU como gatilho.

---

# 📁 Arquivos incluídos
  
