#!/bin/bash

# Script para setup do LocalStack (SQS + DynamoDB)
set -e

LOCALSTACK_URL="http://localhost:4566"
AWS_REGION="us-east-1"
QUEUE_NAME="queue"
TABLE_NAME="analytics"

echo "============================================"
echo "Setup LocalStack (SQS + DynamoDB)"
echo "============================================"

# Verifica se LocalStack está acessível
echo "Aguardando LocalStack..."
for i in {1..30}; do
  if curl -s "$LOCALSTACK_URL/_localstack/health" > /dev/null 2>&1; then
    echo "✓ LocalStack está acessível"
    break
  fi
  echo "  Tentativa $i/30..."
  sleep 1
done

# Cria a fila SQS
echo ""
echo "Criando fila SQS '$QUEUE_NAME'..."
aws sqs create-queue \
  --queue-name "$QUEUE_NAME" \
  --region "$AWS_REGION" \
  --endpoint-url "$LOCALSTACK_URL" \
  2>/dev/null || echo "  (fila pode já existir)"

QUEUE_URL="$LOCALSTACK_URL/000000000000/$QUEUE_NAME"
echo "✓ Fila SQS criada: $QUEUE_URL"

# Cria a tabela DynamoDB
echo ""
echo "Criando tabela DynamoDB '$TABLE_NAME'..."
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=event_id,AttributeType=S \
  --key-schema AttributeName=event_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$AWS_REGION" \
  --endpoint-url "$LOCALSTACK_URL" \
  2>/dev/null || echo "  (tabela pode já existir)"

echo "✓ Tabela DynamoDB criada: $TABLE_NAME"

echo ""
echo "============================================"
echo "Setup Concluído!"
echo "============================================"
echo ""
echo "Próximos passos:"
echo "1. Teste o health do analytics-service:"
echo "   curl http://localhost:8005/health"
echo ""
echo "2. Gere eventos no evaluation-service:"
echo "   curl 'http://localhost:8004/evaluate?user_id=test-user-1&flag_name=test-flag'"
echo ""
echo "3. Verifique os logs do analytics-service:"
echo "   docker compose logs -f analytics-service"
echo ""
