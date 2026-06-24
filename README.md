# Feiras Ecológicas - Arquitetura AWS com Microserviços

Projeto de aplicação de três camadas para a disciplina de Arquitetura de Computação em Nuvem.

## Visão geral

A aplicação exibe feiras ecológicas, produtos e expositores e oferece:
- cadastro de contato com a organização;
- inscrição para receber notificações por e-mail;
- painel administrativo para mensagens, produtos e usuários.

## Arquitetura AWS proposta

A solução será implementada em AWS com microserviços, usando:

- EC2 para o frontend;
- EC2 para o backend;
- RDS MySQL para o banco de dados;
- SQS e SNS para mensageria;
- CloudWatch para observabilidade e logs.

### Motivo da arquitetura de microserviços

- separação de responsabilidades entre frontend e backend;
- escalabilidade independente das camadas;
- padronização de deployment em EC2 para cada serviço;
- maior resiliência com mensageria assíncrona.

## Modelo de três camadas

1. **Camada de apresentação**
   - EC2 frontend que renderiza EJS e consome APIs do backend;
   - interface com páginas públicas e formulários.

2. **Camada de aplicação**
   - EC2 backend em Node.js/Express;
   - expõe APIs REST para `feiras`, `produtos`, `expositores`, `contato` e `notificacoes`;
   - persiste dados em RDS e publica eventos em SQS/SNS.

3. **Camada de dados**
   - AWS RDS MySQL;
   - armazena `feiras`, `produtos`, `expositores`, `mensagens`, `usuarios` e `notificacoes`.

## Fluxo de dados e mensageria

A aplicação utiliza mensageria AWS para garantir robustez e desacoplamento.

- Quando o usuário enviar a mensagem de contato:
  - o backend grava o registro em RDS MySQL;
  - opcionalmente publica um evento em Amazon SQS.

- Quando o usuário se inscrever para notificações:
  - o backend grava a inscrição em `notificacoes`;
  - publica um evento em Amazon SNS para distribuir a informação.

### Benefícios do fluxo

- garante persistência imediata dos dados;
- permite processamento assíncrono e integração futura;
- mantém o backend como ponto central de controle.

## Observabilidade e logs

A solução usa AWS CloudWatch como plataforma de monitoramento central.

- CloudWatch Logs para capturar logs de frontend e backend;
- CloudWatch Metrics para monitorar instâncias EC2 e RDS;
- CloudWatch Alarms para alertar sobre erros, alta latência e uso excessivo de recursos;
- CloudWatch Dashboards para visualizar o estado do sistema.

## Estrutura do projeto

- `backend/` — serviço API Node.js/Express que se integra com MySQL, SQS e SNS;
- `frontend/` — serviço web Node.js/Express com templates EJS;
- `bd/feiras.sql` — script de banco de dados com esquema e dados iniciais;
- `docker-compose.yml` — ambiente local para backend, frontend e MySQL;
- `.env` — variáveis de configuração;
- `.dockerignore` — padrões a ignorar no build Docker.

## Configuração local

### Requisitos

- Docker
- Docker Compose
- Node.js (para desenvolvimento local)

### Rodando com Docker

1. Abra o terminal na pasta do projeto.
2. Execute:

```bash
docker-compose up --build
```

3. Acesse a aplicação em:

```text
http://localhost:3000
```

### Variáveis de ambiente

O arquivo `.env` deve conter:

```text
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=feiras
DB_PORT=3307
SESSION_SECRET=alterar_para_um_segredo_forte
PORT=3000
AWS_REGION=us-east-1
SQS_QUEUE_URL=
NOTIFICATIONS_SQS_QUEUE_URL=
SNS_TOPIC_ARN=
```

> Em Docker local, o banco é acessível como `db:3306`, mas a aplicação usa `DB_HOST` de `.env`.

## Scripts disponíveis

- `npm start` — inicia o servidor Node.js
- `npm run dev` — inicia o servidor com `nodemon`

## Alta disponibilidade e monitoramento

- EC2 frontend e backend podem ser distribuídos em múltiplas zonas de disponibilidade;
- RDS MySQL pode ser configurado com Multi-AZ para failover;
- SQS e SNS são serviços gerenciados e resilientes;
- CloudWatch fornece logs, métricas e alarmes para visibilidade contínua.


## Notas finais

Esta versão documenta a solução como uma arquitetura AWS de três camadas com microserviços, mensageria e observabilidade.
