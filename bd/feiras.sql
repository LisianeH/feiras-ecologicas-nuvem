-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Tempo de geração: 09/07/2025 às 01:04
-- Versão do servidor: 10.4.32-MariaDB
-- Versão do PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `feiras`
--

-- --------------------------------------------------------

--
-- Estrutura para tabela `expositores`
--

CREATE TABLE `expositores` (
  `id` int(11) NOT NULL,
  `nome` varchar(128) NOT NULL,
  `produtos` text NOT NULL,
  `contato` varchar(32) NOT NULL,
  `foto` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `expositores`
--

INSERT INTO `expositores` (`id`, `nome`, `produtos`, `contato`, `foto`) VALUES
(1, 'Horta do Eltinho', 'Aipim, cebola, brócolis, couve-flor, tomate', '(51) 98888-8888', 'imagens/expositores/elton.jpg'),
(2, 'Colheita da Laís', 'Melão, melancia, abóbora, pepino', '(51) 97777-7777', 'imagens/expositores/lais.jpg'),
(3, 'Fazenda Schenkel', 'Alface, rúcula, cebolinha, morango', '(51) 96666-6666', 'imagens/expositores/schenkel.jpg'),
(4, 'Naturais do Gui', 'Tomate, batata, berinjela, pimentão', '(51) 95555-5555', 'imagens/expositores/gui.jpg');

-- --------------------------------------------------------

--
-- Estrutura para tabela `feiras`
--

CREATE TABLE `feiras` (
  `id` int(11) NOT NULL,
  `nome` varchar(128) NOT NULL,
  `dia_semana` varchar(64) NOT NULL,
  `horario` varchar(64) NOT NULL,
  `bairro` varchar(64) NOT NULL,
  `descricao` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `feiras`
--

INSERT INTO `feiras` (`id`, `nome`, `dia_semana`, `horario`, `bairro`, `descricao`) VALUES
(1, 'Feira Ecológica do Bom Fim', 'Sábados', '7h às 13h', 'Bom Fim', 'Avenida José Bonifácio, 675 (quadra 2)'),
(2, 'Feira Ecológica da Tristeza', 'Sábados', '7h às 12h', 'Tristeza', 'Avenida Otto Niemeyer esquina com a Avenida Wenceslau Escobar'),
(3, 'Feira Ecológica Três Figueiras', 'Domingos', '7h às 12h30', 'Três Figueiras', 'Rua Cel. Armando Assis, Praça Desembargador La Hire Guerra'),
(4, 'Feira Ecológica Lindóia', 'Quartas e Sextas', '14h às 18h', 'Lindóia', 'Rua Catamarca (Praça Ponaim)'),
(5, 'Feira Ecológica do Centro Administrativo Municipal Guilherme Socias Villela', 'Quintas', '7h30 às 11h30', 'Centro', 'Rua General João Manoel, 157'),
(6, 'Feira Ecológica André Forster', 'Sábados', '7h às 13h', 'Centro', 'Rua Rômulo Telles Pessoa, Praça André Forster');

-- --------------------------------------------------------

--
-- Estrutura para tabela `mensagens`
--

CREATE TABLE `mensagens` (
  `id` int(11) NOT NULL,
  `nome` varchar(128) NOT NULL,
  `telefone` varchar(32) NOT NULL,
  `email` varchar(128) NOT NULL,
  `mensagem` text NOT NULL,
  `data_envio` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `mensagens`
--

INSERT INTO `mensagens` (`id`, `nome`, `telefone`, `email`, `mensagem`, `data_envio`) VALUES
(1, 'Carlos Silva', '(51) 99999-8888', 'carlos.silva@email.com', 'Olá, sou produtor de hortaliças orgânicas e gostaria de participar da feira.', '2025-07-03 13:10:23'),
(10, 'Maria', '51 987654321', 'maria@email.com', 'Oii, eu sou Maria, gostaria de expor meus produtos! ', '2025-07-08 19:43:18'),
(11, 'Maria', '51 987654321', 'maria@email.com', 'Oii! Gostaria de expor meus produtos nas feiras ecológicas!', '2025-07-08 19:49:37');

-- --------------------------------------------------------

--
-- Estrutura para tabela `produtos`
--

CREATE TABLE `produtos` (
  `id` int(11) NOT NULL,
  `nome` varchar(128) NOT NULL,
  `preco` decimal(8,2) DEFAULT NULL,
  `descricao` text NOT NULL,
  `foto` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `produtos`
--

INSERT INTO `produtos` (`id`, `nome`, `preco`, `descricao`, `foto`) VALUES
(1, 'Cebola', 4.99, 'Cebora Orgânica', 'imagens/produtos/cebola.jpg'),
(2, 'Alface', 3.50, 'Alface crespa orgânica', 'imagens/produtos/alface.jpg'),
(3, 'Tomate', 6.90, 'Tomate orgânico italiano', 'imagens/produtos/tomate.jpg'),
(4, 'Cenoura', 5.20, 'Cenoura fresca e orgânica', 'imagens/produtos/cenoura.jpg'),
(5, 'Abobrinha', 4.80, 'Abobrinha verde orgânica', 'imagens/produtos/abobrinha.jpg'),
(6, 'Beterraba', 5.50, 'Beterraba doce orgânica', 'imagens/produtos/beterraba.jpg'),
(7, 'Pimentão', 7.30, 'Pimentão amarelo orgânico', 'imagens/produtos/pimentao.jpg'),
(8, 'Batata Doce', 4.60, 'Batata doce roxa orgânica', 'imagens/produtos/batata_doce.jpg'),
(9, 'Milho', 7.85, 'Milho Orgânico', 'imagens/produtos/milho.jpg');

-- --------------------------------------------------------

--
-- Estrutura para tabela `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `nome` varchar(128) DEFAULT NULL,
  `email` varchar(128) NOT NULL,
  `senha` varchar(64) NOT NULL,
  `foto` varchar(255) NOT NULL COMMENT 'Endereço da imagem'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `usuarios`
--

INSERT INTO `usuarios` (`id`, `nome`, `email`, `senha`, `foto`) VALUES
(1, 'Lisiane Hoffmeister', 'lisiane@email.com', 'd033e22ae348aeb5660fc2140aec35850c4da997', 'imagens/usuarios/lisiane.jpg'),
(8, 'Artur Raguse', 'artur@email.com', 'd033e22ae348aeb5660fc2140aec35850c4da997', 'imagens/usuarios/1752015307-artur.jpg');

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `expositores`
--
ALTER TABLE `expositores`
  ADD PRIMARY KEY (`id`);

--
-- Índices de tabela `feiras`
--
ALTER TABLE `feiras`
  ADD PRIMARY KEY (`id`);

--
-- Índices de tabela `mensagens`
--
ALTER TABLE `mensagens`
  ADD PRIMARY KEY (`id`);

--
-- Índices de tabela `produtos`
--
ALTER TABLE `produtos`
  ADD PRIMARY KEY (`id`);

--
-- Índices de tabela `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT para tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `expositores`
--
ALTER TABLE `expositores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de tabela `feiras`
--
ALTER TABLE `feiras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de tabela `mensagens`
--
ALTER TABLE `mensagens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de tabela `produtos`
--
ALTER TABLE `produtos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de tabela `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
