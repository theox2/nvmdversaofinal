-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 09/12/2025 às 05:54
-- Versão do servidor: 10.4.32-MariaDB
-- Versão do PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `novamoda`
--
CREATE DATABASE IF NOT EXISTS `novamoda` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `novamoda`;

DELIMITER $$
--
-- Procedimentos
--
DROP PROCEDURE IF EXISTS `sp_atualizar_estoque`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_atualizar_estoque` (IN `p_pedido_id` INT)   BEGIN
    UPDATE produtos p
    JOIN pedido_itens pi ON p.id = pi.produto_id
    SET p.estoque = p.estoque - pi.quantidade
    WHERE pi.pedido_id = p_pedido_id;
END$$

DROP PROCEDURE IF EXISTS `sp_calcular_total_carrinho`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_calcular_total_carrinho` (IN `p_carrinho_id` INT)   BEGIN
    SELECT 
        SUM(ci.quantidade * ci.preco_unitario) as subtotal,
        COUNT(*) as total_itens
    FROM carrinho_itens ci
    WHERE ci.carrinho_id = p_carrinho_id;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `avaliacao_imagens`
--

DROP TABLE IF EXISTS `avaliacao_imagens`;
CREATE TABLE IF NOT EXISTS `avaliacao_imagens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `avaliacao_id` int(11) NOT NULL,
  `url` varchar(500) NOT NULL,
  `data_upload` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_avaliacao` (`avaliacao_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `avaliacao_util`
--

DROP TABLE IF EXISTS `avaliacao_util`;
CREATE TABLE IF NOT EXISTS `avaliacao_util` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `avaliacao_id` int(11) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `data_voto` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_usuario_avaliacao` (`usuario_id`,`avaliacao_id`),
  KEY `idx_avaliacao` (`avaliacao_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `avaliacoes`
--

DROP TABLE IF EXISTS `avaliacoes`;
CREATE TABLE IF NOT EXISTS `avaliacoes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `produto_id` int(11) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `nota` int(11) NOT NULL CHECK (`nota` >= 1 and `nota` <= 5),
  `titulo` varchar(200) DEFAULT NULL,
  `comentario` text DEFAULT NULL,
  `verificada` tinyint(1) DEFAULT 0,
  `aprovada` tinyint(1) DEFAULT 1,
  `data_avaliacao` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_usuario_produto` (`usuario_id`,`produto_id`),
  KEY `idx_produto` (`produto_id`),
  KEY `idx_usuario` (`usuario_id`),
  KEY `idx_nota` (`nota`),
  KEY `idx_avaliacoes_produto_aprovada` (`produto_id`,`aprovada`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `avaliacoes`
--

INSERT INTO `avaliacoes` (`id`, `produto_id`, `usuario_id`, `nota`, `titulo`, `comentario`, `verificada`, `aprovada`, `data_avaliacao`) VALUES
(1, 1, 2, 5, 'Produto excelente!', 'A qualidade superou minhas expectativas. Muito confortável e o tecido é ótimo.', 1, 1, '2025-12-04 23:15:20'),
(2, 1, 3, 4, 'Muito bom', 'Gostei bastante, só achei um pouco grande. Recomendo pedir um tamanho menor.', 1, 1, '2025-12-04 23:15:20'),
(3, 2, 2, 5, 'Melhor moletom que já comprei', 'Super quente e confortável. Vale cada centavo!', 1, 1, '2025-12-04 23:15:20');

-- --------------------------------------------------------

--
-- Estrutura para tabela `carrinhos`
--

DROP TABLE IF EXISTS `carrinhos`;
CREATE TABLE IF NOT EXISTS `carrinhos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) DEFAULT NULL,
  `sessao_id` varchar(100) DEFAULT NULL,
  `data_criacao` timestamp NOT NULL DEFAULT current_timestamp(),
  `data_atualizacao` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_usuario` (`usuario_id`),
  KEY `idx_sessao` (`sessao_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `carrinho_itens`
--

DROP TABLE IF EXISTS `carrinho_itens`;
CREATE TABLE IF NOT EXISTS `carrinho_itens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `carrinho_id` int(11) NOT NULL,
  `produto_id` int(11) NOT NULL,
  `quantidade` int(11) DEFAULT 1,
  `tamanho` varchar(10) DEFAULT NULL,
  `cor` varchar(50) DEFAULT NULL,
  `preco_unitario` decimal(10,2) NOT NULL,
  `data_adicao` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_carrinho` (`carrinho_id`),
  KEY `idx_produto` (`produto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `categorias`
--

DROP TABLE IF EXISTS `categorias`;
CREATE TABLE IF NOT EXISTS `categorias` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `descricao` text DEFAULT NULL,
  `imagem_url` varchar(500) DEFAULT NULL,
  `ativo` tinyint(1) DEFAULT 1,
  `ordem` int(11) DEFAULT 0,
  `data_cadastro` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `idx_slug` (`slug`),
  KEY `idx_ativo` (`ativo`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `categorias`
--

INSERT INTO `categorias` (`id`, `nome`, `slug`, `descricao`, `imagem_url`, `ativo`, `ordem`, `data_cadastro`) VALUES
(1, 'Masculino', 'masculino', 'Moda masculina urbana e streetwear', NULL, 1, 1, '2025-12-04 23:15:20'),
(2, 'Feminino', 'feminino', 'Estilo e elegância feminina', NULL, 1, 2, '2025-12-04 23:15:20'),
(3, 'Infantil', 'infantil', 'Conforto e diversão para os pequenos', NULL, 1, 3, '2025-12-04 23:15:20'),
(4, 'Acessórios', 'acessorios', 'Complete seu look com estilo', NULL, 1, 4, '2025-12-04 23:15:20'),
(5, 'Calçados', 'calcados', 'Tênis e sapatos para todos os estilos', NULL, 1, 5, '2025-12-04 23:15:20');

-- --------------------------------------------------------

--
-- Estrutura para tabela `cupons`
--

DROP TABLE IF EXISTS `cupons`;
CREATE TABLE IF NOT EXISTS `cupons` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(50) NOT NULL,
  `descricao` varchar(200) DEFAULT NULL,
  `tipo` enum('percentual','fixo') NOT NULL,
  `valor` decimal(10,2) NOT NULL,
  `valor_minimo` decimal(10,2) DEFAULT 0.00,
  `limite_uso` int(11) DEFAULT NULL,
  `vezes_usado` int(11) DEFAULT 0,
  `ativo` tinyint(1) DEFAULT 1,
  `data_inicio` date DEFAULT NULL,
  `data_expiracao` date DEFAULT NULL,
  `data_cadastro` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo` (`codigo`),
  KEY `idx_codigo` (`codigo`),
  KEY `idx_ativo` (`ativo`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `cupons`
--

INSERT INTO `cupons` (`id`, `codigo`, `descricao`, `tipo`, `valor`, `valor_minimo`, `limite_uso`, `vezes_usado`, `ativo`, `data_inicio`, `data_expiracao`, `data_cadastro`) VALUES
(1, 'NOVA10', 'Desconto de 10% para novos clientes', 'percentual', 10.00, 100.00, 100, 0, 1, NULL, '2025-12-31', '2025-12-04 23:15:20'),
(2, 'PRIMEIRA', 'Desconto de 15% na primeira compra', 'percentual', 15.00, 150.00, 50, 0, 1, NULL, '2025-12-31', '2025-12-04 23:15:20'),
(3, 'FRETE50', 'R$ 50 de desconto no frete', 'fixo', 50.00, 200.00, NULL, 0, 1, NULL, '2025-12-31', '2025-12-04 23:15:20');

-- --------------------------------------------------------

--
-- Estrutura para tabela `enderecos`
--

DROP TABLE IF EXISTS `enderecos`;
CREATE TABLE IF NOT EXISTS `enderecos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) NOT NULL,
  `nome_endereco` varchar(50) DEFAULT 'Principal',
  `cep` varchar(10) NOT NULL,
  `estado` varchar(2) NOT NULL,
  `cidade` varchar(100) NOT NULL,
  `bairro` varchar(100) NOT NULL,
  `endereco` varchar(200) NOT NULL,
  `numero` varchar(20) NOT NULL,
  `complemento` varchar(100) DEFAULT NULL,
  `padrao` tinyint(1) DEFAULT 0,
  `data_cadastro` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_usuario` (`usuario_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `favoritos`
--

DROP TABLE IF EXISTS `favoritos`;
CREATE TABLE IF NOT EXISTS `favoritos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) NOT NULL,
  `produto_id` int(11) NOT NULL,
  `data_adicao` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_usuario_produto` (`usuario_id`,`produto_id`),
  KEY `idx_usuario` (`usuario_id`),
  KEY `idx_produto` (`produto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `logs_sistema`
--

DROP TABLE IF EXISTS `logs_sistema`;
CREATE TABLE IF NOT EXISTS `logs_sistema` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) DEFAULT NULL,
  `acao` varchar(100) NOT NULL,
  `descricao` text DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `data_log` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_usuario` (`usuario_id`),
  KEY `idx_acao` (`acao`),
  KEY `idx_data` (`data_log`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `newsletter`
--

DROP TABLE IF EXISTS `newsletter`;
CREATE TABLE IF NOT EXISTS `newsletter` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(150) NOT NULL,
  `ativo` tinyint(1) DEFAULT 1,
  `data_inscricao` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_email` (`email`),
  KEY `idx_ativo` (`ativo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `pedidos`
--

DROP TABLE IF EXISTS `pedidos`;
CREATE TABLE IF NOT EXISTS `pedidos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `numero_pedido` varchar(20) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `endereco_id` int(11) DEFAULT NULL,
  `status` enum('pendente','processando','enviado','entregue','cancelado') DEFAULT 'pendente',
  `forma_pagamento` enum('pix','credito','boleto') NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `desconto` decimal(10,2) DEFAULT 0.00,
  `frete` decimal(10,2) DEFAULT 0.00,
  `total` decimal(10,2) NOT NULL,
  `cupom_codigo` varchar(50) DEFAULT NULL,
  `observacoes` text DEFAULT NULL,
  `data_pedido` timestamp NOT NULL DEFAULT current_timestamp(),
  `data_atualizacao` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `numero_pedido` (`numero_pedido`),
  KEY `endereco_id` (`endereco_id`),
  KEY `idx_numero` (`numero_pedido`),
  KEY `idx_usuario` (`usuario_id`),
  KEY `idx_status` (`status`),
  KEY `idx_data` (`data_pedido`),
  KEY `idx_pedidos_usuario_status` (`usuario_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Acionadores `pedidos`
--
DROP TRIGGER IF EXISTS `trg_gerar_numero_pedido`;
DELIMITER $$
CREATE TRIGGER `trg_gerar_numero_pedido` BEFORE INSERT ON `pedidos` FOR EACH ROW BEGIN
    IF NEW.numero_pedido IS NULL OR NEW.numero_pedido = '' THEN
        SET NEW.numero_pedido = CONCAT('#', LPAD(FLOOR(RAND() * 99999) + 10000, 5, '0'));
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para tabela `pedido_itens`
--

DROP TABLE IF EXISTS `pedido_itens`;
CREATE TABLE IF NOT EXISTS `pedido_itens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pedido_id` int(11) NOT NULL,
  `produto_id` int(11) NOT NULL,
  `nome_produto` varchar(200) NOT NULL,
  `quantidade` int(11) NOT NULL,
  `tamanho` varchar(10) DEFAULT NULL,
  `cor` varchar(50) DEFAULT NULL,
  `preco_unitario` decimal(10,2) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pedido` (`pedido_id`),
  KEY `idx_produto` (`produto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `produtos`
--

DROP TABLE IF EXISTS `produtos`;
CREATE TABLE IF NOT EXISTS `produtos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(200) NOT NULL,
  `slug` varchar(200) NOT NULL,
  `descricao` text DEFAULT NULL,
  `categoria_id` int(11) DEFAULT NULL,
  `preco` decimal(10,2) NOT NULL,
  `preco_antigo` decimal(10,2) DEFAULT NULL,
  `estoque` int(11) DEFAULT 0,
  `imagem_principal` varchar(500) DEFAULT NULL,
  `ativo` tinyint(1) DEFAULT 1,
  `destaque` tinyint(1) DEFAULT 0,
  `data_cadastro` timestamp NOT NULL DEFAULT current_timestamp(),
  `ultima_atualizacao` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `idx_slug` (`slug`),
  KEY `idx_categoria` (`categoria_id`),
  KEY `idx_ativo` (`ativo`),
  KEY `idx_destaque` (`destaque`),
  KEY `idx_preco` (`preco`),
  KEY `idx_produtos_categoria_ativo` (`categoria_id`,`ativo`)
) ENGINE=InnoDB AUTO_INCREMENT=142 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `produtos`
--

INSERT INTO `produtos` (`id`, `nome`, `slug`, `descricao`, `categoria_id`, `preco`, `preco_antigo`, `estoque`, `imagem_principal`, `ativo`, `destaque`, `data_cadastro`, `ultima_atualizacao`) VALUES
(1, 'Camiseta Oversized Street', 'camiseta-oversized-street', 'Camiseta oversized premium com tecido 100% algodão. Design moderno e confortável.', 1, 129.90, 179.90, 45, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800', 1, 1, '2025-12-04 23:15:20', '2025-12-04 23:15:20'),
(2, 'Moletom Premium Black', 'moletom-premium-black', 'Moletom com capuz e bolso canguru. Tecido macio e quente.', 1, 249.90, NULL, 23, 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800', 1, 1, '2025-12-04 23:15:20', '2025-12-04 23:15:20'),
(3, 'Calça Cargo Utility', 'calca-cargo-utility', 'Calça cargo com múltiplos bolsos funcionais. Design utilitário moderno.', 1, 189.90, NULL, 8, 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800', 1, 0, '2025-12-04 23:15:20', '2025-12-04 23:15:20'),
(4, 'Jaqueta Bomber Vintage', 'jaqueta-bomber-vintage', 'Jaqueta bomber estilo vintage com acabamento premium.', 1, 299.90, 399.90, 0, 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800', 1, 0, '2025-12-04 23:15:20', '2025-12-04 23:15:20'),
(5, 'Tênis Air Classic', 'tenis-air-classic', 'Tênis esportivo clássico com tecnologia de amortecimento.', 5, 599.90, NULL, 67, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800', 1, 1, '2025-12-04 23:15:20', '2025-12-04 23:15:20'),
(6, 'Boné Snapback Logo', 'bone-snapback-logo', 'Boné snapback com logo bordado. Ajuste regulável.', 4, 79.90, NULL, 120, 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=800', 1, 0, '2025-12-04 23:15:20', '2025-12-04 23:15:20'),
(18, 'Camiseta Oversized Trap Wave', 'camiseta-oversized-trap-wave', 'Camiseta oversized premium com estampa inspirada na cultura trap. Tecido 100% algodão fio 30.1, modelagem drop shoulder e barra alongada. Perfeita para o estilo Matuê.', 1, 149.90, 199.90, 35, 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(19, 'Camiseta Tie-Dye Psychedelic', 'camiseta-tie-dye-psychedelic', 'Camiseta tie-dye artesanal com cores vibrantes. Cada peça é única. Modelagem oversized, 100% algodão premium. Vibe psicodélica autêntica.', 1, 139.90, NULL, 28, 'https://images.unsplash.com/photo-1620799140188-3b2a02fd9a77?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(20, 'Camiseta Vintage Nike Air', 'camiseta-vintage-nike-air', 'Camiseta estilo vintage Nike com logo Air clássico. Efeito desbotado intencional, oversized fit. Algodão stone washed premium.', 1, 169.90, 229.90, 42, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(21, 'Camiseta Adidas Three Stripes Black', 'camiseta-adidas-three-stripes', 'Camiseta preta clássica Adidas com três listras laterais. Tecido respirável, fit regular. Essencial do streetwear.', 1, 129.90, NULL, 58, 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(22, 'Camiseta Corta-Vento Central Cee', 'camiseta-corta-vento-central', 'Camiseta técnica com proteção UV, estilo UK drill. Tecido dry-fit, modelagem slim fit. Inspirada no visual de Central Cee.', 1, 159.90, NULL, 31, 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(23, 'Moletom Trap Skull Premium', 'moletom-trap-skull-premium', 'Moletom canguru com estampa de caveira trap nas costas. Capuz duplo, bolso frontal grande. Tecido felpa 100% algodão. Perfeito para shows.', 1, 289.90, 399.90, 24, 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(24, 'Hoodie Oversized \"30 PRAÇA\"', 'hoodie-oversized-30-praca', 'Hoodie oversized inspirado no 30PRAÇA. Estampa frontal e traseira, capuz grande. Modelagem drop shoulder, mangas compridas.', 1, 329.90, NULL, 19, 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(25, 'Moletom Nike Tech Fleece', 'moletom-nike-tech-fleece', 'Moletom Nike Tech Fleece original. Tecnologia de isolamento térmico, zíper completo, bolsos laterais. Fit moderno e slim.', 1, 449.90, 599.90, 15, 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(26, 'Hoodie Adidas Yeezy Style', 'hoodie-adidas-yeezy-style', 'Hoodie minimalista estilo Yeezy. Cores neutras, modelagem oversized, capuz grande. Algodão orgânico premium.', 1, 359.90, NULL, 22, 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(27, 'Calça Cargo Militar Trap', 'calca-cargo-militar-trap', 'Calça cargo estilo militar com múltiplos bolsos funcionais. Tecido resistente ripstop, ajuste nos tornozelos. Essencial do streetwear.', 1, 249.90, 329.90, 33, 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(28, 'Calça Slim Fit Destroyed', 'calca-slim-fit-destroyed', 'Calça jeans slim com rasgos estratégicos. Lavagem escura, stretch confortável. Visual UK drill autêntico.', 1, 219.90, NULL, 41, 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(29, 'Calça Jogger Tech Nike', 'calca-jogger-tech-nike', 'Calça jogger Nike com tecnologia Dri-FIT. Elástico nos tornozelos, bolsos com zíper. Perfeita para treino e estilo.', 1, 279.90, 349.90, 38, 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(30, 'Calça Wide Leg Skate', 'calca-wide-leg-skate', 'Calça estilo skate com perna larga. Jeans lavagem clara, fit relaxado. Visual anos 90 revival.', 1, 269.90, NULL, 27, 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(31, 'Shorts Cargo Preto Tactical', 'shorts-cargo-preto-tactical', 'Shorts cargo tático com bolsos laterais grandes. Tecido resistente, comprimento na altura do joelho. Estilo urbano militar.', 1, 179.90, NULL, 45, 'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(32, 'Jaqueta Bomber MA-1 Verde Militar', 'jaqueta-bomber-ma1-verde', 'Jaqueta bomber clássica MA-1 verde militar. Bolsos laterais e no braço, zíper YKK, forro laranja interno. Ícone do streetwear.', 1, 399.90, 549.90, 18, 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(33, 'Corta-Vento Nike Windrunner', 'corta-vento-nike-windrunner', 'Jaqueta corta-vento Nike Windrunner com capuz. Tecnologia repelente à água, logo refletivo. Clássico atemporal.', 1, 329.90, NULL, 26, 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(34, 'Jaqueta Jeans Oversized Destroyed', 'jaqueta-jeans-oversized-destroyed', 'Jaqueta jeans oversized com rasgos e patches. Lavagem escura, gola de pelos removível. Visual grunge moderno.', 1, 379.90, 479.90, 21, 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(35, 'Corta-Vento Adidas Tricolor', 'corta-vento-adidas-tricolor', 'Corta-vento Adidas vintage tricolor. Bolsos frontais, capuz ajustável, logo bordado. Estilo anos 90.', 1, 299.90, NULL, 32, 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(36, 'Boné Aba Reta Trap Culture', 'bone-aba-reta-trap-culture', 'Boné aba reta snapback com bordado trap. Regulagem traseira, aba dura. Estilo autêntico de hip-hop.', 4, 89.90, NULL, 67, 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(37, 'Touca Beanie Carhartt Style', 'touca-beanie-carhartt-style', 'Touca beanie de tricô grossa estilo Carhartt. Dobra dupla, logo bordado. Essencial para o inverno.', 4, 79.90, 99.90, 88, 'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(38, 'Boné Dad Hat Nike SB', 'bone-dad-hat-nike-sb', 'Boné dad hat Nike SB com aba curva. Tecido suave, regulagem traseira de metal. Fit confortável.', 4, 119.90, NULL, 54, 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(39, 'Touca Balaclava Ninja', 'touca-balaclava-ninja', 'Balaclava ninja preta full face. Tecido respirável, abertura para olhos e boca. Visual tático urbano.', 4, 69.90, NULL, 73, 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(40, 'Tênis Nike Air Force 1 Low White', 'tenis-nike-air-force-1-white', 'Nike Air Force 1 branco clássico. Couro premium, solado de borracha, tecnologia Air. O tênis mais icônico do streetwear.', 5, 699.90, 899.90, 42, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(41, 'Tênis Air Jordan 1 Mid Chicago', 'tenis-air-jordan-1-chicago', 'Air Jordan 1 Mid colorway Chicago. Couro e nobuck, cano médio, Air-Sole. Lenda do basquete e streetwear.', 5, 899.90, 1199.90, 28, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(42, 'Tênis Adidas Samba OG Black', 'tenis-adidas-samba-og-black', 'Adidas Samba OG preto com três listras brancas. Cabedal em couro, solado de borracha gum. Clássico do futebol ao streetwear.', 5, 599.90, NULL, 35, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(43, 'Tênis New Balance 550 White Navy', 'tenis-new-balance-550-white-navy', 'New Balance 550 branco com detalhes azul marinho. Cabedal em couro sintético, design retro basquete. Hype do momento.', 5, 649.90, 799.90, 31, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(44, 'Tênis Vans Old Skool Black', 'tenis-vans-old-skool-black', 'Vans Old Skool preto clássico. Canvas resistente, listra lateral icônica, solado waffle. Essencial do skate e streetwear.', 5, 349.90, NULL, 58, 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(45, 'Tênis Converse Chuck 70 High Black', 'tenis-converse-chuck-70-black', 'Converse Chuck Taylor 70 High preto. Canvas premium, cano alto, sola vintage. Ícone atemporal.', 5, 429.90, NULL, 47, 'https://images.unsplash.com/photo-1514989940723-e8e51635b782?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(46, 'Cropped Hoodie Rosa Neon', 'cropped-hoodie-rosa-neon', 'Cropped hoodie rosa neon oversized. Capuz ajustável, mangas longas, barra elástica. Vibe Y2K moderna.', 2, 179.90, NULL, 38, 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=800', 1, 1, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(47, 'Calça Cargo Feminina Bege', 'calca-cargo-feminina-bege', 'Calça cargo feminina high waist bege. Múltiplos bolsos, ajuste nos tornozelos, cintura alta. Urbano e feminino.', 2, 229.90, 289.90, 34, 'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(48, 'Top Esportivo Nike Pro', 'top-esportivo-nike-pro', 'Top esportivo Nike Pro com tecnologia Dri-FIT. Sustentação média, tecido respirável. Ideal para treino e streetwear.', 2, 139.90, NULL, 52, 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=800', 1, 0, '2025-12-09 04:25:02', '2025-12-09 04:25:02'),
(106, 'Camiseta Oversized Trap Culture', 'camiseta-trap-culture-2024', 'Camiseta oversized premium estilo Neemzz. 100% algodão fio 30, fit largo e confortável. Estampa exclusiva trap culture.', 1, 149.90, 199.90, 45, 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(107, 'Camiseta Oversized Black Skull', 'camiseta-black-skull-street', 'Oversized preta com caveira streetwear. Tecido premium, corte moderno. Perfeita para o trap.', 1, 139.90, NULL, 38, 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(108, 'Camiseta Oversized White Minimalist', 'camiseta-white-minimal-urban', 'Branca oversized minimalista. Design clean estilo Central Cee. Alta qualidade.', 1, 129.90, 179.90, 52, 'https://images.unsplash.com/photo-1622445275463-afa2ab738c34?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(109, 'Camiseta Oversized Gray Stonewashed', 'camiseta-gray-stonewashed-trap', 'Cinza stonewashed oversized. Efeito envelhecido. Estilo vintage trap.', 1, 159.90, NULL, 40, 'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(110, 'Moletom Premium Black Hoodie', 'moletom-black-hoodie-premium-2024', 'Moletom preto oversized com capuz. Tecido flanelado interno. Estilo Matuê - 30PRAUM vibes.', 1, 289.90, 349.90, 28, 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(111, 'Moletom Tie Dye Streetwear', 'moletom-tie-dye-trap-edition', 'Moletom tie dye exclusivo. Capuz e bolso canguru. Edição limitada trap.', 1, 319.90, NULL, 15, 'https://images.unsplash.com/photo-1620799140188-3b2a02fd9a77?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(112, 'Moletom Corta Vento Urban', 'moletom-corta-vento-urban-tech', 'Moletom corta vento com capuz. Impermeável. Ideal para shows e quebrada.', 1, 259.90, 299.90, 22, 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(113, 'Moletom Canguru Burgundy', 'moletom-canguru-burgundy-neemzz', 'Moletom vinho oversized. Bolso canguru grande. Cor exclusiva trap.', 1, 269.90, NULL, 30, 'https://images.unsplash.com/photo-1578587018452-892bacefd3f2?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(114, 'Calça Cargo Black Tactical', 'calca-cargo-tactical-black-2024', 'Calça cargo preta com múltiplos bolsos. Estilo tático streetwear. Fit perfeito estilo trap.', 1, 249.90, NULL, 35, 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(115, 'Calça Jogger Tech Gray', 'calca-jogger-tech-gray-urban', 'Jogger cinza tech wear. Bolsos com zíper. Elástico no tornozelo. Conforto máximo.', 1, 219.90, 269.90, 30, 'https://images.unsplash.com/photo-1624378515195-6bbdb73dff1a?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(116, 'Calça Jeans Destroyed Black', 'calca-jeans-destroyed-black-trap', 'Jeans preta destroyed. Rasgos estratégicos. Fit skinny estilo trap brasileiro.', 1, 279.90, NULL, 25, 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(117, 'Calça Cargo Olive Green', 'calca-cargo-olive-green-military', 'Cargo verde militar. Múltiplos bolsos. Estilo tático urbano.', 1, 259.90, 309.90, 28, 'https://images.unsplash.com/photo-1624378516671-e608e2e4d1c4?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(118, 'Jaqueta Corta Vento Reflective', 'jaqueta-reflective-night-rider', 'Jaqueta corta vento com detalhes refletivos. Impermeável. Estilo rave/trap.', 1, 359.90, 449.90, 18, 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(119, 'Jaqueta Bomber Urban Black', 'jaqueta-bomber-urban-black-classic', 'Bomber preta oversized. Bolsos laterais. Essencial no guarda-roupa trap.', 1, 329.90, NULL, 20, 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(120, 'Jaqueta Puffer Neon Yellow', 'jaqueta-puffer-neon-yellow-hype', 'Puffer amarelo neon. Super quentinha. Estilo hypebeast garantido.', 1, 399.90, 499.90, 15, 'https://images.unsplash.com/photo-1608256246200-53e635b5b65f?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(121, 'Nike Air Force 1 Triple White', 'nike-air-force-1-white-2024', 'Clássico Air Force todo branco. Icônico no trap mundial. Conforto e estilo.', 5, 699.90, 799.90, 40, 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(122, 'Nike Dunk Low Black White', 'nike-dunk-low-panda-edition', 'Dunk Low Panda. Preto e branco. Hype máximo. Essencial pra qualquer trapper.', 5, 899.90, NULL, 25, 'https://images.unsplash.com/photo-1605348532760-6753d2c43329?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(123, 'Adidas Yeezy Boost 350 V2', 'adidas-yeezy-boost-350-v2-2024', 'Yeezy Boost 350 V2. Conforto incomparável. O tênis do Kanye usado por todos os rappers.', 5, 1299.90, 1499.90, 12, 'https://images.unsplash.com/photo-1543508282-6319a3e2621f?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(124, 'Nike Air Max 97 Silver Bullet', 'nike-air-max-97-silver-2024', 'Air Max 97 prata. Design futurista. Perfeito pro trap estilo space age.', 5, 999.90, NULL, 18, 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(125, 'Adidas Forum Low White', 'adidas-forum-low-white-og', 'Forum Low branco. Clássico 90s de volta. Street style autêntico.', 5, 649.90, 749.90, 30, 'https://images.unsplash.com/photo-1552066344-2464c1135c32?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(126, 'Nike Air Jordan 1 Chicago', 'nike-jordan-1-chicago-retro', 'Air Jordan 1 Chicago. Lenda do basquete no trap. Colorway icônica.', 5, 1599.90, NULL, 10, 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(127, 'Boné New Era Yankees Black', 'bone-new-era-yankees-ny-black', 'Clássico New Era NY preto. Essencial no trap game. Fechamento snapback.', 4, 179.90, NULL, 60, 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(128, 'Boné Dad Hat Black Unstructured', 'bone-dad-hat-black-minimal', 'Dad hat preto desestruturado. Fit curvo. Minimalista e clean.', 4, 89.90, 129.90, 75, 'https://images.unsplash.com/photo-1575428652377-a2d80e2277fc?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(129, 'Boné Trucker Mesh White', 'bone-trucker-mesh-white-2024', 'Trucker branco com tela. Ventilado. Perfeito pro verão trap.', 4, 109.90, NULL, 55, 'https://images.unsplash.com/photo-1521369909029-2afed882baee?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(130, 'Touca Beanie Black Supreme Style', 'touca-beanie-black-supreme-2024', 'Beanie preta estilo Supreme. Material quentinho. Must have no inverno trap.', 4, 79.90, NULL, 85, 'https://images.unsplash.com/photo-1576871337632-b9aef4c17ab9?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(131, 'Touca Beanie Neon Green', 'touca-beanie-neon-green-hype', 'Beanie verde neon. Destaque garantido. Perfeita pra show e cypher.', 4, 89.90, 119.90, 45, 'https://images.unsplash.com/photo-1611312449412-6cefac5dc2e4?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(132, 'Touca Beanie Burgundy Oversized', 'touca-beanie-burgundy-long', 'Beanie vinho oversized longa. Pode dobrar ou usar solta. Trap essentials.', 4, 94.90, NULL, 50, 'https://images.unsplash.com/photo-1608613304899-ea8294bf7e3d?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(133, 'Corrente Cubana Prata 5mm', 'corrente-cubana-prata-5mm-rapper', 'Corrente cubana prata 5mm. Estilo rapper. Fechamento seguro. Brilho intenso.', 4, 159.90, 199.90, 40, 'https://images.unsplash.com/photo-1611955167811-4711904bb9f8?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(134, 'Óculos de Sol Hexagonal Black', 'oculos-hexagonal-black-matrix', 'Óculos hexagonal preto estilo Matrix. Proteção UV400. Trap futurista.', 4, 129.90, NULL, 50, 'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(135, 'Mochila Urban Preta Impermeável', 'mochila-urban-black-tech-2024', 'Mochila preta impermeável com porta USB. Compartimento notebook. Essencial urbano.', 4, 249.90, 299.90, 30, 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(136, 'Shoulder Bag Nike Tech', 'shoulder-bag-nike-tech-mini', 'Shoulder bag Nike mini. Perfeita pra essenciais. Alça ajustável. Trap essentials.', 4, 189.90, NULL, 35, 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=800', 1, 1, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(137, 'Cinto Tático Preto Fivela', 'cinto-tatico-preto-fivela-metal', 'Cinto tático preto com fivela metal. Resistente. Estilo militar urbano.', 4, 79.90, 99.90, 65, 'https://images.unsplash.com/photo-1624222247344-550fb60583e2?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(138, 'Cropped Hoodie Black', 'cropped-hoodie-black-fem-2024', 'Cropped hoodie preto oversized. Estilo trap feminino. Conforto e atitude.', 2, 169.90, 219.90, 32, 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(139, 'Calça Cargo Feminina Bege', 'calca-cargo-fem-bege-highwaist', 'Cargo feminina bege high waist. Bolsos funcionais. Cintura alta trap style.', 2, 229.90, NULL, 28, 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(140, 'Top Cropped Ribbed White', 'top-cropped-ribbed-white-fem', 'Top cropped canelado branco. Manga longa. Básico essencial feminino trap.', 2, 89.90, 119.90, 45, 'https://images.unsplash.com/photo-1594633313593-bab3825d0caf?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54'),
(141, 'Legging Tech Preta Cintura Alta', 'legging-tech-black-highwaist-fem', 'Legging preta tech com cintura alta. Bolso lateral. Perfeita pra treino ou street.', 2, 149.90, NULL, 40, 'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=800', 1, 0, '2025-12-09 04:39:54', '2025-12-09 04:39:54');

-- --------------------------------------------------------

--
-- Estrutura para tabela `produto_cores`
--

DROP TABLE IF EXISTS `produto_cores`;
CREATE TABLE IF NOT EXISTS `produto_cores` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `produto_id` int(11) NOT NULL,
  `cor` varchar(50) NOT NULL,
  `codigo_hex` varchar(7) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_produto_cor` (`produto_id`,`cor`),
  KEY `idx_produto` (`produto_id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `produto_cores`
--

INSERT INTO `produto_cores` (`id`, `produto_id`, `cor`, `codigo_hex`) VALUES
(1, 1, 'Preto', '#000000'),
(2, 1, 'Branco', '#FFFFFF'),
(3, 1, 'Cinza', '#808080'),
(4, 2, 'Preto', '#000000'),
(5, 2, 'Cinza', '#808080'),
(6, 2, 'Azul Marinho', '#000080'),
(7, 3, 'Verde Militar', '#4B5320'),
(8, 3, 'Preto', '#000000'),
(9, 3, 'Bege', '#F5F5DC'),
(10, 5, 'Branco', '#FFFFFF'),
(11, 5, 'Preto', '#000000'),
(12, 6, 'Preto', '#000000'),
(13, 6, 'Branco', '#FFFFFF'),
(14, 6, 'Azul', '#0000FF');

-- --------------------------------------------------------

--
-- Estrutura para tabela `produto_imagens`
--

DROP TABLE IF EXISTS `produto_imagens`;
CREATE TABLE IF NOT EXISTS `produto_imagens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `produto_id` int(11) NOT NULL,
  `url` varchar(500) NOT NULL,
  `ordem` int(11) DEFAULT 0,
  `data_cadastro` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_produto` (`produto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estrutura para tabela `produto_tamanhos`
--

DROP TABLE IF EXISTS `produto_tamanhos`;
CREATE TABLE IF NOT EXISTS `produto_tamanhos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `produto_id` int(11) NOT NULL,
  `tamanho` varchar(10) NOT NULL,
  `estoque` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_produto_tamanho` (`produto_id`,`tamanho`),
  KEY `idx_produto` (`produto_id`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `produto_tamanhos`
--

INSERT INTO `produto_tamanhos` (`id`, `produto_id`, `tamanho`, `estoque`) VALUES
(1, 1, 'P', 10),
(2, 1, 'M', 15),
(3, 1, 'G', 12),
(4, 1, 'GG', 8),
(5, 2, 'P', 5),
(6, 2, 'M', 8),
(7, 2, 'G', 7),
(8, 2, 'GG', 3),
(9, 3, '38', 2),
(10, 3, '40', 2),
(11, 3, '42', 2),
(12, 3, '44', 2),
(13, 5, '38', 10),
(14, 5, '39', 12),
(15, 5, '40', 15),
(16, 5, '41', 15),
(17, 5, '42', 10),
(18, 5, '43', 5),
(19, 6, 'Único', 120);

-- --------------------------------------------------------

--
-- Estrutura para tabela `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `senha` varchar(255) NOT NULL,
  `telefone` varchar(20) DEFAULT NULL,
  `cpf` varchar(14) DEFAULT NULL,
  `tipo` enum('cliente','admin') DEFAULT 'cliente',
  `ativo` tinyint(1) DEFAULT 1,
  `data_cadastro` timestamp NOT NULL DEFAULT current_timestamp(),
  `ultima_atualizacao` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `cpf` (`cpf`),
  KEY `idx_email` (`email`),
  KEY `idx_tipo` (`tipo`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Despejando dados para a tabela `usuarios`
--

INSERT INTO `usuarios` (`id`, `nome`, `email`, `senha`, `telefone`, `cpf`, `tipo`, `ativo`, `data_cadastro`, `ultima_atualizacao`) VALUES
(1, 'Administrador', 'admin@novamoda.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, 'admin', 1, '2025-12-04 23:15:20', '2025-12-04 23:15:20'),
(2, 'João Silva', 'joao@email.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, 'cliente', 1, '2025-12-04 23:15:20', '2025-12-04 23:15:20'),
(3, 'Maria Santos', 'maria@email.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, 'cliente', 1, '2025-12-04 23:15:20', '2025-12-04 23:15:20'),
(4, 'Carlos Oliveira', 'carlos@email.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, 'cliente', 1, '2025-12-04 23:15:20', '2025-12-04 23:15:20');

-- --------------------------------------------------------

--
-- Estrutura stand-in para view `vw_pedidos_detalhes`
-- (Veja abaixo para a visão atual)
--
DROP VIEW IF EXISTS `vw_pedidos_detalhes`;
CREATE TABLE IF NOT EXISTS `vw_pedidos_detalhes` (
`id` int(11)
,`numero_pedido` varchar(20)
,`data_pedido` timestamp
,`status` enum('pendente','processando','enviado','entregue','cancelado')
,`total` decimal(10,2)
,`cliente_nome` varchar(100)
,`cliente_email` varchar(150)
,`total_itens` bigint(21)
);

-- --------------------------------------------------------

--
-- Estrutura stand-in para view `vw_produtos_avaliacoes`
-- (Veja abaixo para a visão atual)
--
DROP VIEW IF EXISTS `vw_produtos_avaliacoes`;
CREATE TABLE IF NOT EXISTS `vw_produtos_avaliacoes` (
`id` int(11)
,`nome` varchar(200)
,`slug` varchar(200)
,`descricao` text
,`categoria_id` int(11)
,`preco` decimal(10,2)
,`preco_antigo` decimal(10,2)
,`estoque` int(11)
,`imagem_principal` varchar(500)
,`ativo` tinyint(1)
,`destaque` tinyint(1)
,`data_cadastro` timestamp
,`ultima_atualizacao` timestamp
,`nota_media` decimal(14,4)
,`total_avaliacoes` bigint(21)
);

-- --------------------------------------------------------

--
-- Estrutura para view `vw_pedidos_detalhes`
--
DROP TABLE IF EXISTS `vw_pedidos_detalhes`;

DROP VIEW IF EXISTS `vw_pedidos_detalhes`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_pedidos_detalhes`  AS SELECT `pd`.`id` AS `id`, `pd`.`numero_pedido` AS `numero_pedido`, `pd`.`data_pedido` AS `data_pedido`, `pd`.`status` AS `status`, `pd`.`total` AS `total`, `u`.`nome` AS `cliente_nome`, `u`.`email` AS `cliente_email`, count(`pi`.`id`) AS `total_itens` FROM ((`pedidos` `pd` join `usuarios` `u` on(`pd`.`usuario_id` = `u`.`id`)) left join `pedido_itens` `pi` on(`pd`.`id` = `pi`.`pedido_id`)) GROUP BY `pd`.`id` ;

-- --------------------------------------------------------

--
-- Estrutura para view `vw_produtos_avaliacoes`
--
DROP TABLE IF EXISTS `vw_produtos_avaliacoes`;

DROP VIEW IF EXISTS `vw_produtos_avaliacoes`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_produtos_avaliacoes`  AS SELECT `p`.`id` AS `id`, `p`.`nome` AS `nome`, `p`.`slug` AS `slug`, `p`.`descricao` AS `descricao`, `p`.`categoria_id` AS `categoria_id`, `p`.`preco` AS `preco`, `p`.`preco_antigo` AS `preco_antigo`, `p`.`estoque` AS `estoque`, `p`.`imagem_principal` AS `imagem_principal`, `p`.`ativo` AS `ativo`, `p`.`destaque` AS `destaque`, `p`.`data_cadastro` AS `data_cadastro`, `p`.`ultima_atualizacao` AS `ultima_atualizacao`, coalesce(avg(`a`.`nota`),0) AS `nota_media`, count(`a`.`id`) AS `total_avaliacoes` FROM (`produtos` `p` left join `avaliacoes` `a` on(`p`.`id` = `a`.`produto_id` and `a`.`aprovada` = 1)) GROUP BY `p`.`id` ;

--
-- Restrições para tabelas despejadas
--

--
-- Restrições para tabelas `avaliacao_imagens`
--
ALTER TABLE `avaliacao_imagens`
  ADD CONSTRAINT `avaliacao_imagens_ibfk_1` FOREIGN KEY (`avaliacao_id`) REFERENCES `avaliacoes` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `avaliacao_util`
--
ALTER TABLE `avaliacao_util`
  ADD CONSTRAINT `avaliacao_util_ibfk_1` FOREIGN KEY (`avaliacao_id`) REFERENCES `avaliacoes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `avaliacao_util_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `avaliacoes`
--
ALTER TABLE `avaliacoes`
  ADD CONSTRAINT `avaliacoes_ibfk_1` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `avaliacoes_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `carrinhos`
--
ALTER TABLE `carrinhos`
  ADD CONSTRAINT `carrinhos_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `carrinho_itens`
--
ALTER TABLE `carrinho_itens`
  ADD CONSTRAINT `carrinho_itens_ibfk_1` FOREIGN KEY (`carrinho_id`) REFERENCES `carrinhos` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `carrinho_itens_ibfk_2` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `enderecos`
--
ALTER TABLE `enderecos`
  ADD CONSTRAINT `enderecos_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `favoritos`
--
ALTER TABLE `favoritos`
  ADD CONSTRAINT `favoritos_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `favoritos_ibfk_2` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `logs_sistema`
--
ALTER TABLE `logs_sistema`
  ADD CONSTRAINT `logs_sistema_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL;

--
-- Restrições para tabelas `pedidos`
--
ALTER TABLE `pedidos`
  ADD CONSTRAINT `pedidos_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`),
  ADD CONSTRAINT `pedidos_ibfk_2` FOREIGN KEY (`endereco_id`) REFERENCES `enderecos` (`id`) ON DELETE SET NULL;

--
-- Restrições para tabelas `pedido_itens`
--
ALTER TABLE `pedido_itens`
  ADD CONSTRAINT `pedido_itens_ibfk_1` FOREIGN KEY (`pedido_id`) REFERENCES `pedidos` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `pedido_itens_ibfk_2` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`);

--
-- Restrições para tabelas `produtos`
--
ALTER TABLE `produtos`
  ADD CONSTRAINT `produtos_ibfk_1` FOREIGN KEY (`categoria_id`) REFERENCES `categorias` (`id`) ON DELETE SET NULL;

--
-- Restrições para tabelas `produto_cores`
--
ALTER TABLE `produto_cores`
  ADD CONSTRAINT `produto_cores_ibfk_1` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `produto_imagens`
--
ALTER TABLE `produto_imagens`
  ADD CONSTRAINT `produto_imagens_ibfk_1` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`) ON DELETE CASCADE;

--
-- Restrições para tabelas `produto_tamanhos`
--
ALTER TABLE `produto_tamanhos`
  ADD CONSTRAINT `produto_tamanhos_ibfk_1` FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
