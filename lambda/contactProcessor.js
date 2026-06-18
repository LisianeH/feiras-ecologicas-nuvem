const { SQSClient, DeleteMessageCommand } = require('@aws-sdk/client-sqs');
const mysql = require('mysql2/promise');

const sqsClient = new SQSClient({ region: process.env.AWS_REGION || 'us-east-1' });

exports.handler = async (event) => {
  const dbHost = process.env.DB_HOST || 'localhost';
  const dbUser = process.env.DB_USER || 'root';
  const dbPassword = process.env.DB_PASSWORD || '';
  const dbName = process.env.DB_NAME || 'feiras';
  const dbPort = parseInt(process.env.DB_PORT, 10) || 3306;
  const queueUrl = process.env.SQS_QUEUE_URL;

  if (!queueUrl) {
    throw new Error('SQS_QUEUE_URL não definido');
  }

  const connection = await mysql.createConnection({
    host: dbHost,
    user: dbUser,
    password: dbPassword,
    database: dbName,
    port: dbPort
  });

  try {
    for (const record of event.Records) {
      const body = JSON.parse(record.body);
      const { nome, telefone, email, mensagem, data_envio } = body;

      await connection.execute(
        'INSERT INTO mensagens (nome, telefone, email, mensagem, data_envio) VALUES (?, ?, ?, ?, ?)',
        [nome, telefone, email, mensagem, data_envio]
      );

      await sqsClient.send(new DeleteMessageCommand({
        QueueUrl: queueUrl,
        ReceiptHandle: record.receiptHandle
      }));
    }

    return { statusCode: 200, body: 'Mensagens processadas com sucesso' };
  } catch (error) {
    console.error('Erro no Lambda:', error);
    throw error;
  } finally {
    await connection.end();
  }
};
