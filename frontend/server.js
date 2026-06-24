require('dotenv').config();
const express = require('express');
const axios = require('axios');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const API_URL = process.env.API_URL || 'http://localhost:4000';
const ADMIN_URL = process.env.ADMIN_URL || API_URL;

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use('/style', express.static(path.join(__dirname, 'style')));
app.use('/imagens', express.static(path.join(__dirname, 'imagens')));

app.get('/', async (req, res) => {
  try {
    const [feirasRes, produtosRes, expositoresRes] = await Promise.all([
      axios.get(`${API_URL}/api/feiras`),
      axios.get(`${API_URL}/api/produtos`),
      axios.get(`${API_URL}/api/expositores`)
    ]);

    res.render('index', {
      title: 'Feiras Ecológicas de Porto Alegre',
      feiras: feirasRes.data,
      produtos: produtosRes.data,
      expositores: expositoresRes.data,
      message: req.query.message,
      apiUrl: API_URL,
      adminUrl: ADMIN_URL
    });
  } catch (error) {
    console.error('Erro ao carregar dados do backend:', error.message);
    res.status(500).send('Erro ao carregar os dados do site.');
  }
});

app.post('/contato', async (req, res) => {
  const { nome, telefone, email, mensagem } = req.body;
  try {
    const apiResponse = await axios.post(`${API_URL}/api/contato`, {
      nome,
      telefone,
      email,
      mensagem
    });
    return res.redirect(`/?message=${encodeURIComponent(apiResponse.data.message)}`);
  } catch (error) {
    console.error('Erro ao enviar contato:', error.message);
    const message = error.response?.data?.message || 'Erro ao enviar contato. Tente novamente.';
    return res.redirect(`/?message=${encodeURIComponent(message)}`);
  }
});

app.post('/notificacoes', async (req, res) => {
  const { nome, email } = req.body;
  try {
    const apiResponse = await axios.post(`${API_URL}/api/notificacoes`, {
      nome,
      email
    });
    return res.redirect(`/?message=${encodeURIComponent(apiResponse.data.message)}`);
  } catch (error) {
    console.error('Erro ao enviar notificação:', error.message);
    const message = error.response?.data?.message || 'Erro ao se inscrever para notificações. Tente novamente.';
    return res.redirect(`/?message=${encodeURIComponent(message)}`);
  }
});

app.listen(PORT, () => {
  console.log(`Frontend rodando em http://localhost:${PORT}`);
});
