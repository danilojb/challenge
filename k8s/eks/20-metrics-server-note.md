Instalar Metrics Server (necessário para HPA e útil ao KEDA):

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

Verificar:
kubectl top nodes
kubectl top pods -n <NAMESPACE>
