<?php
/**
 * api/admin/pedidos/listar.php - Listar Pedidos (CORRIGIDO)
 * COLOQUE EM: /Novamoda/api/admin/pedidos/listar.php
 */

// Headers CORS primeiro
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Responder OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Mostrar erros para debug (REMOVER EM PRODUÇÃO)
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

try {
    // Incluir config
    $config_path = __DIR__ . '/../../../config.php';
    
    if (!file_exists($config_path)) {
        throw new Exception('Arquivo config.php não encontrado em: ' . $config_path);
    }
    
    require_once $config_path;
    
    if (!isset($pdo)) {
        throw new Exception('Conexão PDO não estabelecida. Verifique config.php');
    }
    
    // Testar conexão
    $pdo->query("SELECT 1");
    
    // ==========================================
    // BUSCAR PEDIDOS COM INFORMAÇÕES COMPLETAS
    // ==========================================
    
    $sql = "
        SELECT 
            p.id,
            p.numero_pedido,
            p.data_pedido,
            p.status,
            p.forma_pagamento,
            p.subtotal,
            p.desconto,
            p.frete,
            p.total,
            p.codigo_rastreio,
            p.observacoes,
            
            -- Cliente
            u.id as cliente_id,
            u.nome as cliente_nome,
            u.email as cliente_email,
            u.telefone as cliente_telefone,
            
            -- Endereço
            e.cep,
            e.estado,
            e.cidade,
            e.bairro,
            e.endereco,
            e.numero,
            e.complemento
            
        FROM pedidos p
        INNER JOIN usuarios u ON p.usuario_id = u.id
        LEFT JOIN enderecos e ON p.endereco_id = e.id
        ORDER BY p.data_pedido DESC
        LIMIT 100
    ";
    
    $stmt = $pdo->query($sql);
    $pedidos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // ==========================================
    // BUSCAR ITENS DE CADA PEDIDO
    // ==========================================
    
    foreach ($pedidos as &$pedido) {
        // Buscar itens
        $stmt = $pdo->prepare("
            SELECT 
                pi.id,
                pi.produto_id,
                pi.nome_produto,
                pi.quantidade,
                pi.tamanho,
                pi.cor,
                pi.preco_unitario,
                pi.subtotal,
                prod.imagem_principal
            FROM pedido_itens pi
            LEFT JOIN produtos prod ON pi.produto_id = prod.id
            WHERE pi.pedido_id = ?
        ");
        
        $stmt->execute([$pedido['id']]);
        $itens = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Formatar itens
        $pedido['itens'] = array_map(function($item) {
            return [
                'id' => (int)$item['id'],
                'produto_id' => (int)$item['produto_id'],
                'produto_nome' => $item['nome_produto'],
                'quantidade' => (int)$item['quantidade'],
                'tamanho' => $item['tamanho'],
                'cor' => $item['cor'],
                'preco_unitario' => (float)$item['preco_unitario'],
                'subtotal' => (float)$item['subtotal'],
                'imagem' => $item['imagem_principal'] ?: 'https://via.placeholder.com/100'
            ];
        }, $itens);
        
        // Formatar endereço
        $pedido['endereco'] = [
            'cep' => $pedido['cep'] ?: '',
            'estado' => $pedido['estado'] ?: '',
            'cidade' => $pedido['cidade'] ?: '',
            'bairro' => $pedido['bairro'] ?: '',
            'endereco' => $pedido['endereco'] ?: '',
            'numero' => $pedido['numero'] ?: '',
            'complemento' => $pedido['complemento'] ?: ''
        ];
        
        // Remover campos duplicados do endereço
        unset(
            $pedido['cep'],
            $pedido['estado'],
            $pedido['cidade'],
            $pedido['bairro'],
            $pedido['numero'],
            $pedido['complemento']
        );
        
        // Converter tipos
        $pedido['id'] = (int)$pedido['id'];
        $pedido['cliente_id'] = (int)$pedido['cliente_id'];
        $pedido['subtotal'] = (float)$pedido['subtotal'];
        $pedido['desconto'] = (float)$pedido['desconto'];
        $pedido['frete'] = (float)$pedido['frete'];
        $pedido['total'] = (float)$pedido['total'];
        $pedido['total_itens'] = count($pedido['itens']);
    }
    
    // ==========================================
    // RESPOSTA DE SUCESSO
    // ==========================================
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => $pedidos,
        'total' => count($pedidos),
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} catch (PDOException $e) {
    // Erro de banco de dados
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao buscar pedidos do banco de dados',
        'error' => $e->getMessage(),
        'sql_state' => $e->getCode(),
        'file' => basename(__FILE__)
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    // Erro geral
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro interno do servidor',
        'error' => $e->getMessage(),
        'file' => basename(__FILE__)
    ], JSON_UNESCAPED_UNICODE);
}
?>
