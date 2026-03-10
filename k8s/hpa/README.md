# HPA (Horizontal Pod Autoscaler)

> **Ambiente alvo:** AWS Academy (HPA por CPU).  
> **Observação:** KEDA não é usado no Academy por limitação de IAM (IRSA).

---

## 1. Ajuste o namespace
- Substitua `NAMESPACE_AJUSTAR` pelo namespace real do cluster (ex.: `togglemaster`).
- Se não houver namespace definido, use `default`.

---

## 2. Ajuste o nome do Deployment
Em `spec.scaleTargetRef.name`, confirme o nome exato do Deployment:

- Para o analytics: `analytics-deployment` (ou o que o grupo usou)
- Para o evaluation: `evaluation-deployment` (ou o que o grupo usou)

---

## 3. Pré-requisitos no cluster (quando for aplicar)
- Metrics Server instalado.
- Deployments com `resources.requests/limits` de CPU e memória definidos.

---

## 4. Aplicar (quando for usar)

```bash
kubectl apply -f k8s/hpa/hpa-analytics.yaml
kubectl apply -f k8s/hpa/hpa-evaluation.yaml
