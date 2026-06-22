require('dotenv').config();
const express = require('express');
const session = require('express-session');
const mysql = require('mysql2/promise');
const { SQSClient, SendMessageCommand } = require('@aws-sdk/client-sqs');
const { S3Client, PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const multer = require('multer');
const path = require('path');
const crypto = require('crypto');
const fs = require('fs').promises;

const app = express();
const PORT = process.env.PORT || 3000;

let pool;

async function initializeDatabase() {
  let dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'feiras',
    port: parseInt(process.env.DB_PORT, 10) || 3307
  };

  const secretArn = process.env.DB_SECRET_ARN;
  if (secretArn) {
    console.log('Buscando credenciais do banco no AWS Secrets Manager...');
    try {
      const client = new SecretsManagerClient({ region: process.env.AWS_REGION || 'sa-east-1' });
      const response = await client.send(new GetSecretValueCommand({ SecretId: secretArn }));
      if (response.SecretString) {
        const secret = JSON.parse(response.SecretString);
        dbConfig.host = secret.host || dbConfig.host;
        dbConfig.user = secret.username || dbConfig.user;
        dbConfig.password = secret.password || dbConfig.password;
        dbConfig.database = secret.dbname || dbConfig.database;
        dbConfig.port = parseInt(secret.port, 10) || dbConfig.port;
        console.log(`Credenciais obtidas com sucesso. Conectando no banco de dados AWS RDS em: ${dbConfig.host}`);
      }
    } catch (error) {
      console.error('Erro ao buscar credenciais do banco no Secrets Manager, utilizando variáveis locais do .env:', error);
    }
  }

  pool = mysql.createPool({
    ...dbConfig,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
  });
}

const sessionSecret = process.env.SESSION_SECRET || 'alterar_para_um_segredo_forte';
const queueUrl = process.env.SQS_QUEUE_URL || '';
const sqsClient = new SQSClient({ region: process.env.AWS_REGION || 'us-east-1' });
const s3Client = new S3Client({ region: process.env.AWS_REGION || 'sa-east-1' });
const bucketName = process.env.S3_BUCKET_NAME || '';

function getContentType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.gif') return 'image/gif';
  if (ext === '.svg') return 'image/svg+xml';
  return 'image/jpeg';
}

async function uploadToS3(localFilePath, s3Key) {
  try {
    const fileContent = await fs.readFile(localFilePath);
    const contentType = getContentType(localFilePath);
    await s3Client.send(new PutObjectCommand({
      Bucket: bucketName,
      Key: s3Key,
      Body: fileContent,
      ContentType: contentType
    }));
    console.log(`Upload para S3 concluído: ${s3Key}`);
  } catch (error) {
    console.error(`Erro ao fazer upload do arquivo ${localFilePath} para o S3:`, error);
    throw error;
  }
}

async function syncLocalImagesToS3() {
  if (!bucketName) return;
  console.log('Iniciando sincronização de imagens locais com o S3...');
  const dirs = [
    'imagens/banner',
    'imagens/expositores',
    'imagens/produtos',
    'imagens/usuarios'
  ];

  for (const dir of dirs) {
    try {
      const dirPath = path.join(__dirname, dir);
      await fs.mkdir(dirPath, { recursive: true });
      const files = await fs.readdir(dirPath);
      for (const file of files) {
        const localPath = path.join(dirPath, file);
        const stat = await fs.stat(localPath);
        if (stat.isFile()) {
          const s3Key = `${dir}/${file}`;
          await uploadToS3(localPath, s3Key).catch(err => {
            console.error(`Falha ao sincronizar ${s3Key}:`, err);
          });
        }
      }
    } catch (err) {
      console.error(`Erro ao ler diretório ${dir} para sincronização S3:`, err);
    }
  }
  console.log('Sincronização de imagens locais concluída.');
}

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(session({
  secret: sessionSecret,
  resave: false,
  saveUninitialized: false
}));

app.use(express.static(path.join(__dirname)));
app.use('/style', express.static(path.join(__dirname, 'style')));
app.use('/imagens', (req, res, next) => {
  if (bucketName) {
    const s3Url = `https://${bucketName}.s3.${process.env.AWS_REGION || 'sa-east-1'}.amazonaws.com/imagens${req.path}`;
    return res.redirect(s3Url);
  }
  next();
});
app.use('/imagens', express.static(path.join(__dirname, 'imagens')));
app.use('/video', express.static(path.join(__dirname, 'video')));

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const folder = file.fieldname === 'fotoUsuario' ? 'imagens/usuarios' : 'imagens/produtos';
    cb(null, path.join(__dirname, folder));
  },
  filename: (req, file, cb) => {
    const fileName = `${Date.now()}-${file.originalname}`.replace(/\s+/g, '-');
    cb(null, fileName);
  }
});

const upload = multer({ storage });

function hashPassword(password) {
  return crypto.createHash('sha1').update(password).digest('hex');
}

function ensureAdmin(req, res, next) {
  if (req.session.user && req.session.user.id) {
    return next();
  }
  return res.redirect('/admin/login');
}

app.get('/', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const [feiras] = await connection.query('SELECT * FROM feiras');
    const [produtos] = await connection.query('SELECT * FROM produtos');
    const [expositores] = await connection.query('SELECT * FROM expositores');
    res.render('index', {
      title: 'Feiras Ecológicas de Porto Alegre',
      feiras,
      produtos,
      expositores,
      message: req.query.message
    });
  } finally {
    connection.release();
  }
});

app.post('/contato', async (req, res) => {
  const { nome, telefone, email, mensagem } = req.body;
  if (!nome || !telefone || !email || !mensagem) {
    return res.redirect('/#contato?message=Preencha todos os campos');
  }

  const dataEnvio = new Date().toISOString();
  const contactPayload = {
    nome,
    telefone,
    email,
    mensagem,
    data_envio: dataEnvio
  };

  if (queueUrl) {
    const params = {
      QueueUrl: queueUrl,
      MessageBody: JSON.stringify(contactPayload)
    };

    try {
      await sqsClient.send(new SendMessageCommand(params));
      return res.redirect('/#contato?message=Mensagem enviada com sucesso! (fila SQS)');
    } catch (error) {
      console.error('Erro ao enviar mensagem para SQS:', error);
      return res.redirect('/#contato?message=Erro ao enviar mensagem para fila.');
    }
  }

  const connection = await pool.getConnection();
  try {
    await connection.query(
      'INSERT INTO mensagens (nome, telefone, email, mensagem, data_envio) VALUES (?, ?, ?, ?, ?)',
      [nome, telefone, email, mensagem, dataEnvio]
    );
    res.redirect('/#contato?message=Mensagem enviada com sucesso!');
  } finally {
    connection.release();
  }
});

app.get('/admin/login', (req, res) => {
  res.render('admin/login', {
    title: 'Acesso administrador',
    error: req.query.error
  });
});

app.post('/admin/login', async (req, res) => {
  const { email, senha } = req.body;
  if (!email || !senha) {
    return res.redirect('/admin/login?error=Informe e-mail e senha');
  }

  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query(
      'SELECT * FROM usuarios WHERE email = ? AND senha = ? LIMIT 1',
      [email, hashPassword(senha)]
    );
    if (rows.length === 0) {
      return res.redirect('/admin/login?error=Usuário ou senha inválidos.');
    }

    req.session.user = rows[0];
    return res.redirect('/admin');
  } finally {
    connection.release();
  }
});

app.get('/admin/logout', (req, res) => {
  req.session.destroy(() => {
    res.redirect('/admin/login');
  });
});

app.get('/admin', ensureAdmin, async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const [mensagens] = await connection.query('SELECT * FROM mensagens ORDER BY data_envio DESC');
    const [produtos] = await connection.query('SELECT * FROM produtos');
    const [usuarios] = await connection.query('SELECT * FROM usuarios ORDER BY nome ASC');

    res.render('admin/dashboard', {
      title: 'Painel Administrativo',
      user: req.session.user,
      mensagens,
      produtos,
      usuarios,
      message: req.query.message
    });
  } finally {
    connection.release();
  }
});

app.post('/admin/produtos', ensureAdmin, upload.single('fotoProduto'), async (req, res) => {
  const { nome, preco, descricao } = req.body;
  if (!nome || !preco || !descricao || !req.file) {
    return res.redirect('/admin?message=Preencha todos os campos e selecione uma imagem');
  }

  const fotoDb = `imagens/produtos/${req.file.filename}`;

  if (bucketName) {
    try {
      await uploadToS3(req.file.path, fotoDb);
      await fs.unlink(req.file.path).catch(() => {});
    } catch (error) {
      console.error('Erro ao enviar imagem do produto para o S3:', error);
      return res.redirect('/admin?message=Erro ao enviar imagem para o S3.');
    }
  }

  const connection = await pool.getConnection();
  try {
    await connection.query(
      'INSERT INTO produtos (nome, preco, descricao, foto) VALUES (?, ?, ?, ?)',
      [nome, preco, descricao, fotoDb]
    );
    res.redirect('/admin?message=Produto cadastrado com sucesso!');
  } finally {
    connection.release();
  }
});

app.get('/admin/produtos/delete/:id', ensureAdmin, async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query('SELECT foto FROM produtos WHERE id = ?', [id]);
    if (rows.length > 0) {
      const fotoDb = rows[0].foto;
      const fotoPath = path.join(__dirname, fotoDb);
      await fs.unlink(fotoPath).catch(() => {});
      if (bucketName) {
        await s3Client.send(new DeleteObjectCommand({
          Bucket: bucketName,
          Key: fotoDb
        })).catch(err => console.error('Erro ao deletar imagem do produto do S3:', err));
      }
      await connection.query('DELETE FROM produtos WHERE id = ?', [id]);
    }
    res.redirect('/admin?message=Produto excluído com sucesso!');
  } finally {
    connection.release();
  }
});

app.get('/admin/usuarios', ensureAdmin, async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const [usuarios] = await connection.query('SELECT * FROM usuarios ORDER BY nome ASC');
    res.render('admin/users', {
      title: 'Administradores',
      user: req.session.user,
      usuarios,
      message: req.query.message
    });
  } finally {
    connection.release();
  }
});

app.get('/admin/usuarios/add', ensureAdmin, (req, res) => {
  res.render('admin/add-user', {
    title: 'Adicionar Novo Administrador',
    user: req.session.user,
    message: req.query.message
  });
});

app.post('/admin/usuarios/add', ensureAdmin, upload.single('fotoUsuario'), async (req, res) => {
  const { nome, email, senha } = req.body;
  if (!nome || !email || !senha || !req.file) {
    return res.redirect('/admin/usuarios/add?message=Preencha todos os campos e selecione uma foto');
  }

  const fotoDb = `imagens/usuarios/${req.file.filename}`;

  if (bucketName) {
    try {
      await uploadToS3(req.file.path, fotoDb);
      await fs.unlink(req.file.path).catch(() => {});
    } catch (error) {
      console.error('Erro ao enviar foto do usuário para o S3:', error);
      return res.redirect('/admin/usuarios/add?message=Erro ao enviar imagem para o S3.');
    }
  }

  const connection = await pool.getConnection();
  try {
    await connection.query(
      'INSERT INTO usuarios (nome, email, senha, foto) VALUES (?, ?, ?, ?)',
      [nome, email, hashPassword(senha), fotoDb]
    );
    res.redirect('/admin/usuarios?message=Usuário cadastrado com sucesso!');
  } finally {
    connection.release();
  }
});

app.get('/admin/usuarios/edit/:id', ensureAdmin, async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query('SELECT * FROM usuarios WHERE id = ?', [id]);
    if (rows.length === 0) {
      return res.redirect('/admin/usuarios?message=Usuário não encontrado');
    }
    res.render('admin/edit-user', {
      title: 'Editar Administrador',
      user: req.session.user,
      usuario: rows[0],
      message: req.query.message
    });
  } finally {
    connection.release();
  }
});

app.post('/admin/usuarios/edit/:id', ensureAdmin, upload.single('fotoUsuario'), async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const { nome, email, senha } = req.body;
  const updates = [];
  const params = [];

  if (!nome || !email) {
    return res.redirect(`/admin/usuarios/edit/${id}?message=Nome e e-mail são obrigatórios`);
  }

  updates.push('nome = ?');
  params.push(nome);
  updates.push('email = ?');
  params.push(email);

  if (senha) {
    updates.push('senha = ?');
    params.push(hashPassword(senha));
  }

  if (req.file) {
    const fotoDb = `imagens/usuarios/${req.file.filename}`;
    if (bucketName) {
      try {
        await uploadToS3(req.file.path, fotoDb);
        await fs.unlink(req.file.path).catch(() => {});
      } catch (error) {
        console.error('Erro ao enviar nova foto do usuário para o S3:', error);
        return res.redirect(`/admin/usuarios/edit/${id}?message=Erro ao enviar imagem para o S3.`);
      }
    }
    updates.push('foto = ?');
    params.push(fotoDb);
  }

  params.push(id);

  const connection = await pool.getConnection();
  try {
    await connection.query(`UPDATE usuarios SET ${updates.join(', ')} WHERE id = ?`, params);
    if (req.session.user.id === id) {
      req.session.user.nome = nome;
      req.session.user.email = email;
      if (req.file) {
        req.session.user.foto = `imagens/usuarios/${req.file.filename}`;
      }
    }
    res.redirect(`/admin/usuarios/edit/${id}?message=Alterações salvas com sucesso!`);
  } finally {
    connection.release();
  }
});

app.get('/admin/usuarios/delete/:id', ensureAdmin, async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query('SELECT foto FROM usuarios WHERE id = ?', [id]);
    if (rows.length > 0 && rows[0].foto) {
      const fotoDb = rows[0].foto;
      const fotoPath = path.join(__dirname, fotoDb);
      await fs.unlink(fotoPath).catch(() => {});
      if (bucketName) {
        await s3Client.send(new DeleteObjectCommand({
          Bucket: bucketName,
          Key: fotoDb
        })).catch(err => console.error('Erro ao deletar foto do usuário do S3:', err));
      }
    }
    await connection.query('DELETE FROM usuarios WHERE id = ?', [id]);
    res.redirect('/admin/usuarios?message=Usuário excluído com sucesso!');
  } finally {
    connection.release();
  }
});

async function startServer() {
  await initializeDatabase();
  app.listen(PORT, () => {
    console.log(`Servidor rodando em http://localhost:${PORT}`);
  });
}
startServer();
