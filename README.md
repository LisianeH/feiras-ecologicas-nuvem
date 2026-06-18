# Feiras Ecológicas - Arquitetura em Nuvem

Projeto de aplicação de três camadas para a disciplina de Arquitetura de Computação em Nuvem.

## Visão geral

Esta aplicação exibe feiras ecológicas, produtos e expositores, além de permitir contato com a organização e o gerenciamento administrativo.

### Tecnologias usadas

- Backend: Node.js + Express
- Frontend: EJS (templates server-side)
- Banco de dados: MySQL
- Upload de arquivos: Multer
- Autenticação simples: sessão Express
- Mensageria / serverless: AWS SQS + AWS Lambda (handler `lambda/contactProcessor.js`)

## Arquitetura da solução

A aplicação foi modelada como um monolito de três camadas com suporte a fluxo serverless para processamento de mensagens de contato:

1. **Frontend**
   - Renderizado pelo Express usando templates EJS em `views/`
   - Página principal com feiras, produtos, expositores e formulário de contato

2. **Backend**
   - `server.js` controla rotas de exibição, administração, upload de imagens e envio de contato
   - A rota `POST /contato` envia os dados para o SQS quando a variável `SQS_QUEUE_URL` estiver configurada

3. **Banco de dados**
   - MySQL para persistência de feiras, produtos, expositores, mensagens e usuários
   - Esquema inicial fornecido em `bd/feiras.sql`

### Fluxo serverless / mensageria

- O formulário de contato envia a mensagem para a fila SQS.
- Uma função AWS Lambda `lambda/contactProcessor.js` processa os registros da fila e grava no banco MySQL.
- Esse padrão separa a recepção do contato do processamento e permite maior resiliência e desacoplamento.

## Estrutura do projeto

- `server.js` — aplicação Express principal
- `package.json` — dependências e scripts
- `views/` — templates EJS
- `lambda/contactProcessor.js` — código da função serverless
- `Dockerfile` — imagem do app Node.js
- `docker-compose.yml` — ambiente local com Node.js + MySQL
- `bd/feiras.sql` — esquema e dados de exemplo para MySQL
- `.env` — variáveis de configuração
- `.dockerignore` — arquivos ignorados pelo Docker

## Configuração local

### Requisitos

- Docker
- Docker Compose
- Node.js (apenas para editar; o ambiente pode rodar em contêiner)

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

O arquivo `.env` deve conter as configurações:

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
```

> No modo Docker local, o banco roda em `db:3306`, mas o código usa o valor definido em `.env`.

## Scripts disponíveis

- `npm start` — inicia o servidor Node.js
- `npm run dev` — inicia o servidor com `nodemon` para desenvolvimento

## Como funciona a fila SQS

Se `SQS_QUEUE_URL` estiver configurada no ambiente, a rota de envio de contato não grava diretamente no banco. Em vez disso:

1. `server.js` envia a mensagem para a fila SQS.
2. A Lambda `lambda/contactProcessor.js` processa a fila.
3. A Lambda grava a mensagem no MySQL e remove o item da fila.

## Observabilidade e alta disponibilidade

Para a entrega da disciplina, a arquitetura pode ser estendida com:

- AWS RDS para banco de dados gerenciado
- AWS S3 para armazenamento de imagens
- AWS ECS/EKS/EC2 para execução do backend
- AWS CloudWatch para logs e métricas
- Grafana/Prometheus para dashboards de observabilidade

## Próximos passos para implantação em nuvem

1. Criar infraestrutura com IaC (Terraform) para:
   - VPC, subnets e security groups
   - RDS MySQL
   - SQS
   - Lambda
   - S3 (se armazenar imagens)
2. Configurar a função Lambda para ler de SQS e se conectar ao banco
3. Adicionar monitoramento em CloudWatch e painel Grafana
4. Testar o fluxo completo de envio de contato e processamento serverless

## Notas finais

Este projeto já está preparado como base para um sistema de três camadas com componente serverless. A aplicação pode ser apresentada localmente via Docker ou estendida para um deploy em AWS para demonstrar a arquitetura de nuvem.
