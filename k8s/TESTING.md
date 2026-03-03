# 🧪 Testes de API - Tech Challenge

## 1️⃣ Auth Service

### Health Check
```bash
curl -X GET http://api.techChallenge.local/auth/health
# Resposta esperada: 200 OK
```

### Validação de Token
```bash
curl -X GET http://api.techChallenge.local/auth/validate \
  -H "Authorization: Bearer tmkey_..."
```

---

## 2️⃣ Flag Service

### Health Check
```bash
curl -X GET http://api.techChallenge.local/flags/health
# Resposta esperada: 200 OK
```

### Listar Flags
```bash
curl -X GET http://api.techChallenge.local/flags \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json"
```

### Criar Flag
```bash
curl -X POST http://api.techChallenge.local/flags \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json" \
  -d '{
    "flag": "FLAG{example_flag}",
    "description": "Example flag",
    "difficulty": 1
  }'
```

### Obter Flag Específica
```bash
curl -X GET "http://api.techChallenge.local/flags/{id}" \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json"
```

### Atualizar Flag
```bash
curl -X PUT "http://api.techChallenge.local/flags/{id}" \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json" \
  -d '{
    "flag": "FLAG{updated_flag}",
    "description": "Updated description",
    "difficulty": 2
  }'
```

### Deletar Flag
```bash
curl -X DELETE "http://api.techChallenge.local/flags/{id}" \
  -H "Authorization: Bearer tmkey_..."
```

---

## 3️⃣ Targeting Service

### Health Check
```bash
curl -X GET http://api.techChallenge.local/targets/health
```

### Listar Targets
```bash
curl -X GET http://api.techChallenge.local/targets \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json"
```

### Criar Target
```bash
curl -X POST http://api.techChallenge.local/targets \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json" \
  -d '{
    "target": "example.com",
    "priority": "high",
    "metadata": {"key": "value"}
  }'
```

### Obter Target Específico
```bash
curl -X GET "http://api.techChallenge.local/targets/{id}" \
  -H "Authorization: Bearer tmkey_..."
```

### Atualizar Target
```bash
curl -X PUT "http://api.techChallenge.local/targets/{id}" \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json" \
  -d '{
    "target": "updated.com",
    "priority": "medium"
  }'
```

---

## 4️⃣ Evaluation Service

### Health Check
```bash
curl -X GET http://api.techChallenge.local/evaluations/health
```

### Submeter Avaliação
```bash
curl -X POST http://api.techChallenge.local/evaluate \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json" \
  -d '{
    "flagId": "123",
    "teamId": "456",
    "userSubmission": "FLAG{my_submission}"
  }'
```

### Obter Avaliaciones
```bash
curl -X GET http://api.techChallenge.local/evaluations \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json"
```

### Obter Histórico de Avaliação
```bash
curl -X GET "http://api.techChallenge.local/evaluations/{teamId}" \
  -H "Authorization: Bearer tmkey_..."
```

---

## 5️⃣ Analytics Service

### Health Check
```bash
curl -X GET http://api.techChallenge.local/analytics/health
```

### Obter Estatísticas Gerais
```bash
curl -X GET http://api.techChallenge.local/analytics/stats \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json"
```

### Obter Estatísticas por Time
```bash
curl -X GET "http://api.techChallenge.local/analytics/teams/{teamId}" \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json"
```

### Obter Rankings
```bash
curl -X GET http://api.techChallenge.local/analytics/rankings \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json" \
  -d '{
    "limit": 10,
    "offset": 0
  }'
```

### Obter Eventos
```bash
curl -X GET http://api.techChallenge.local/analytics/events \
  -H "Authorization: Bearer tmkey_..." \
  -H "Content-Type: application/json" \
  -d '{
    "startDate": "2024-01-01",
    "endDate": "2024-12-31"
  }'
```

---

## 🔄 Teste Integrado (Script)

```bash
#!/bin/bash

API_BASE="http://api.techChallenge.local"
AUTH_TOKEN="your_api_token_here"

echo "🧪 Iniciando testes de integração..."

# 1. Health checks
echo -e "\n✅ Health Checks:"
for service in auth flags targets evaluations analytics; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/$service/health")
    echo "  $service: HTTP $response"
done

# 2. Criar flag
echo -e "\n✅ Criando flag..."
flag_response=$(curl -s -X POST "$API_BASE/flags" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "flag": "FLAG{integration_test}",
    "description": "Integration test flag",
    "difficulty": 1
  }')
echo "  Response: $flag_response"
flag_id=$(echo $flag_response | jq -r '.id')

# 3. Listar flags
echo -e "\n✅ Listando flags..."
flags=$(curl -s -X GET "$API_BASE/flags" \
  -H "Authorization: Bearer $AUTH_TOKEN")
echo "  Flags encontradas: $(echo $flags | jq '.[] | length')"

# 4. Criar target
echo -e "\n✅ Criando target..."
target_response=$(curl -s -X POST "$API_BASE/targets" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "target": "test.example.com",
    "priority": "high"
  }')
echo "  Response: $target_response"

# 5. Submeter avaliação
echo -e "\n✅ Submetendo avaliação..."
eval_response=$(curl -s -X POST "$API_BASE/evaluate" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "flagId": "'$flag_id'",
    "teamId": "test_team",
    "userSubmission": "FLAG{integration_test}"
  }')
echo "  Response: $eval_response"

# 6. Obter analytics
echo -e "\n✅ Obtendo analytics..."
analytics=$(curl -s -X GET "$API_BASE/analytics/stats" \
  -H "Authorization: Bearer $AUTH_TOKEN")
echo "  Response: $analytics"

echo -e "\n✅ Testes concluídos!"
```

---

## 📊 Teste de Carga (Apache Bench)

```bash
# Teste básico
ab -n 1000 -c 10 http://api.techChallenge.local/auth/health

# Teste com concorrência maior
ab -n 5000 -c 100 http://api.techChallenge.local/auth/health

# Teste com timeout customizado
ab -n 1000 -c 50 -s 10 http://api.techChallenge.local/flags
```

---

## 📊 Teste de Carga (wrk)

```lua
-- test.lua
request = function()
   wrk.method = "GET"
   wrk.path = "/auth/health"
   wrk.headers["Authorization"] = "Bearer your_token_here"
   return wrk.format(nil)
end
```

```bash
# Executar teste
wrk -t12 -c400 -d30s -s test.lua http://api.techChallenge.local

# t12 = 12 threads
# c400 = 400 conexões concorrentes
# d30s = duração: 30 segundos
```

---

## 🔐 Teste com Autenticação

### Gerar Token
```bash
curl -X POST http://api.techChallenge.local/auth/generate \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "your-master-key"
  }'

# Resposta:
# {
#   "token": "tmkey_...",
#   "expires_in": 3600
# }
```

### Usar Token em Requisições
```bash
AUTH_TOKEN="tmkey_..."

curl -X GET http://api.techChallenge.local/flags \
  -H "Authorization: Bearer $AUTH_TOKEN"
```

---

## 🐛 Teste de Erro

### Requisição sem Token
```bash
curl -X GET http://api.techChallenge.local/flags
# Esperado: 401 Unauthorized
```

### Requisição com Token Inválido
```bash
curl -X GET http://api.techChallenge.local/flags \
  -H "Authorization: Bearer invalid_token_123"
# Esperado: 401 Unauthorized
```

### Requisição com ID Inválido
```bash
curl -X GET http://api.techChallenge.local/flags/invalid-id \
  -H "Authorization: Bearer $AUTH_TOKEN"
# Esperado: 404 Not Found
```

### Requisição Malformada
```bash
curl -X POST http://api.techChallenge.local/flags \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "invalid": "json"'
# Esperado: 400 Bad Request
```

---

## 📈 Monitorar Performance

### Ver tempo de resposta em tempo real
```bash
watch -n 1 'curl -w "HTTP %{http_code} - Time: %{time_total}s\n" -o /dev/null -s http://api.techChallenge.local/auth/health'
```

### Medir tempo detalhado
```bash
curl -w "\
  Tempo DNS:        %{time_namelookup}s\n\
  Tempo conectado:  %{time_connect}s\n\
  Tempo TTFB:       %{time_starttransfer}s\n\
  Tempo total:      %{time_total}s\n" \
  -o /dev/null -s http://api.techChallenge.local/auth/health
```

---

## 🎯 Teste Automatizado com Postman

Importar para Postman:
```json
{
  "info": {
    "name": "Tech Challenge API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth - Health",
      "request": {
        "method": "GET",
        "url": "{{base_url}}/auth/health"
      }
    },
    {
      "name": "Flags - Get All",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{auth_token}}"
          }
        ],
        "url": "{{base_url}}/flags"
      }
    }
  ],
  "variable": [
    {
      "key": "base_url",
      "value": "http://api.techChallenge.local"
    },
    {
      "key": "auth_token",
      "value": "tmkey_..."
    }
  ]
}
```

---

## 📝 Referências

- [cURL Documentation](https://curl.se/docs/)
- [Apache Bench Tutorial](https://httpd.apache.org/docs/current/programs/ab.html)
- [wrk GitHub](https://github.com/wg/wrk)
- [Postman Learning Center](https://learning.postman.com/)
