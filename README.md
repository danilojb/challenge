================================================================================
                    TECHCCHALLENGE - INSTRUÇÕES DOCKER COMPOSE
================================================================================

SOBRE O PROJETO
===============
Este projeto é uma arquitetura de microsserviços com 5 serviços principais:
- Auth-service (Go): Autenticação e gestão de usuários
- Flag-service (Python): Gestão de flags/desafios
- Targeting-service (Python): Direcionamento de conteúdo
- Evaluation-service (Go): Avaliação de soluções com fila SQS
- Analytics-service (Python): Análise de eventos

INFRAESTRUTURA DE SUPORTE
=========================
- PostgreSQL: 3 instâncias para cada serviço (auth, flag, targeting)
- Redis: Cache para avaliações
- LocalStack: Simula serviços AWS (SQS, DynamoDB)


COMO COMEÇAR
============

1. PRÉ-REQUISITOS
   - Docker instalado
   - Docker Compose instalado
   - AWS CLI (opcional, para setup do LocalStack)

2. CLONANDO/PREPARANDO O PROJETO
   - Se ainda não tem um repositório Git, pode usar este projeto diretamente

3. BUILD DAS IMAGENS (opcional - Docker Compose faz automaticamente)
   make build-all
   
   OU manualmente:
   docker build -t auth-service:local ./auth-service
   docker build -t flag-service:local ./flag-service
   docker build -t targeting-service:local ./targeting-service
   docker build -t evaluation-service:local ./evaluation-service
   docker build -t analytics-service:local ./analytics-service

4. INICIANDO OS SERVIÇOS
   docker-compose up -d
   
   Isto vai:
   - Lowcase todas as imagens dos serviços
   - Iniciar todos os containers
   - Criar volumes para dados persistentes
   - Conectar todos os serviços em uma rede privada

5. VERIFICAR STATUS DOS SERVIÇOS
   docker-compose ps
   
   Você deve ver algo como:
   - auth-service (UP)
   - flag-service (UP)
   - targeting-service (UP)
   - evaluation-service (UP)
   - analytics-service (UP)
   - redis (UP)
   - localstack (UP)
   - auth-db (UP)
   - flag-db (UP)
   - target-db (UP)


ACESSANDO OS SERVIÇOS
=====================
Após os containers estarem UP, você pode acessar:

Auth-service:         http://localhost:8001
Flag-service:         http://localhost:8002
Targeting-service:    http://localhost:8003
Evaluation-service:   http://localhost:8004
Analytics-service:    http://localhost:8005


SETUP DO LOCALSTACK (SQS + DYNAMODB)
====================================
Os serviços de avaliação precisam de fila SQS e tabela DynamoDB.

Para setup automático:
   bash setup-localstack.sh

Este script:
- Aguarda o LocalStack ficar pronto
- Cria a fila SQS
- Cria a tabela DynamoDB do Google Analytics

Se precisar fazer manualmente:
   # Verificar saúde do LocalStack
   curl http://localhost:4566/_localstack/health

   # Criar fila SQS
   aws sqs create-queue --queue-name queue --region us-east-1 \
     --endpoint-url http://localhost:4566

   # Criar tabela DynamoDB
   aws dynamodb create-table --table-name analytics \
     --attribute-definitions AttributeName=event_id,AttributeType=S \
     --key-schema AttributeName=event_id,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST --region us-east-1 \
     --endpoint-url http://localhost:4566


COMANDOS ÚTEIS
==============

Ver logs de todos os serviços:
   docker-compose logs -f

Ver logs de um serviço específico:
   docker-compose logs -f auth-service

Parar todos os serviços:
   docker-compose down

Parar e remover volumes (CUIDADO - deleta dados):
   docker-compose down -v

Reiniciar um serviço:
   docker-compose restart auth-service

Executar comando dentro de um container:
   docker-compose exec auth-service bash

Reconstruir uma imagem:
   docker-compose build auth-service --no-cache

Atualizar após mudanças no código:
   docker-compose down
   docker-compose up -d


VARIÁVEIS DE AMBIENTE
=====================
As variáveis de ambiente estão definidas no docker-compose.yml para cada serviço:

Auth-service:
  - PORT=8000
  - DATABASE_URL=postgres://auth:auth@auth-db:5432/authdb
  - MASTER_KEY=admin-secreto-123

Flag-service:
  - PORT=8000
  - DATABASE_URL=postgres://flag:flag@flag-db:5432/flagdb
  - AUTH_SERVICE_URL=http://auth-service:8000

Targeting-service:
  - PORT=8000
  - DATABASE_URL=postgres://target:target@target-db:5432/targetdb
  - AUTH_SERVICE_URL=http://auth-service:8000

Evaluation-service:
  - PORT=8000
  - REDIS_URL=redis://redis:6379
  - AWS_SQS_URL=http://localstack:4566/000000000000/queue
  - AWS_REGION=us-east-1
  - AWS_ACCESS_KEY_ID=test
  - AWS_SECRET_ACCESS_KEY=test
  - FLAG_SERVICE_URL=http://flag-service:8000
  - TARGETING_SERVICE_URL=http://targeting-service:8000

Analytics-service:
  - PORT=8000
  - AWS_ACCESS_KEY_ID=test
  - AWS_SECRET_ACCESS_KEY=test
  - AWS_DYNAMODB_TABLE=analytics
  - AWS_SQS_URL=http://localstack:4566/000000000000/queue
  - AWS_REGION=us-east-1


ACESSO AOS BANCOS DE DADOS
==========================

PostgreSQL (Auth DB):
   PSQL_HOST=localhost
   PSQL_PORT=5432
   PSQL_USER=auth
   PSQL_PASSWORD=auth
   PSQL_DB=authdb

   Conectar:
   psql -h localhost -U auth -d authdb

PostgreSQL (Flag DB):
   PSQL_USER=flag
   PSQL_PASSWORD=flag
   PSQL_DB=flagdb

PostgreSQL (Target DB):
   PSQL_USER=target
   PSQL_PASSWORD=target
   PSQL_DB=targetdb

Redis:
   redis-cli -h localhost -p 6379

LocalStack:
   Endpoint: http://localhost:4566
   Console Web: http://localhost:4571 (se disponível)


TROUBLESHOOTING
===============

1. Serviço não inicia
   - Verifique logs: docker-compose logs <service-name>
   - Verifique se porta já está em uso
   - Tente reconstruir: docker-compose build --no-cache <service>

2. Banco de dados não conecta
   - Verifique se o container do banco está rodando
   - Espere alguns segundos para o serviço iniciar
   - Verifique a variável DATABASE_URL

3. LocalStack não responde
   - Aguarde mais tempo (pode levar até 30 segundos)
   - Rode: docker-compose logs localstack
   - Tente reiniciar: docker-compose restart localstack

4. Volumes de dados não persistem
   - Docker volumes são criados automaticamente
   - Para ver volumes: docker volume ls
   - Para limpar: docker volume prune

5. Erro de conexão entre serviços
   - Os serviços precisam estar na mesma rede (automático com compose)
   - Use nomes dos serviços como hostnames (ex: auth-service)
   - Não use localhost dentro de containers, use o nome do serviço


TESTES
======
Para executar testes:
   python test-evaluation.py

Este script testa a integração entre os serviços.


DESENVOLVIMENTO
===============
Se quiser fazer mudanças no código:

1. Edite o arquivo na sua máquina local
2. Reconstrua a imagem: docker-compose build <service>
3. Reinicie o serviço: docker-compose restart <service>
4. OU simplesmente: docker-compose up -d (vai rebuildar tudo)

Para desenvolvimento mais rápido, considere usar volumes para código-fonte
compartilhado entre o host e o container.


SUPORTE À REDE
==============
Os serviços se comunicam através de uma rede Docker gerenciada pelo compose.
Você pode inspecionar a rede:
   docker network ls
   docker network inspect <network-name>


PARADA E LIMPEZA
================

Parar os serviços (dados persistem):
   docker-compose stop

Parar todos os serviços e remover containers:
   docker-compose down

Remover todos os volumes (CUIDADO - deleta dados):
   docker-compose down -v

Remover todas as imagens:
   docker-compose down --rmi all

Limpar tudo (containers, volumes, redes, imagens):
   docker system prune -a --volumes

================================================================================
                         Boa sorte com seu projeto!
================================================================================
