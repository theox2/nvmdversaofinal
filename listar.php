<?php
/**
 * api/admin/pedidos/listar.php - Listar Pedidos com TODOS os dados
 * VERSÃO CORRIGIDA - Retorna cliente e itens completos
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once '../../../config.php';

try {
    // ==========================================
    // BUSCAR PEDIDOS COM JOIN COMPLETO
    // ==========================================
    
    $stmt = $pdo->query("
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
            
            -- Dados do Cliente
            u.id as cliente_id,
            u.nome as cliente_nome,
            u.email as cliente_email,
            u.telefone as cliente_telefone,
            
            -- Dados do Endereço
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
    ");
    
    $pedidos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // ==========================================
    // BUSCAR ITENS DE CADA PEDIDO
    // ==========================================
    
    foreach ($pedidos as &$pedido) {
        // Buscar itens com informações completas do produto
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
                'imagem' => $item['imagem_principal'] ?? 'https://via.placeholder.com/100'
            ];
        }, $itens);
        
        // Formatar endereço
        $pedido['endereco'] = [
            'cep' => $pedido['cep'] ?? '',
            'estado' => $pedido['estado'] ?? '',
            'cidade' => $pedido['cidade'] ?? '',
            'bairro' => $pedido['bairro'] ?? '',
            'endereco' => $pedido['endereco'] ?? '',
            'numero' => $pedido['numero'] ?? '',
            'complemento' => $pedido['complemento'] ?? ''
        ];
        
        // Remover campos duplicados
        unset(
            $pedido['cep'],
            $pedido['estado'],
            $pedido['cidade'],
            $pedido['bairro'],
            $pedido['numero'],
            $pedido['complemento']
        );
        
        // Formatar valores
        $pedido['id'] = (int)$pedido['id'];
        $pedido['cliente_id'] = (int)$pedido['cliente_id'];
        $pedido['subtotal'] = (float)$pedido['subtotal'];
        $pedido['desconto'] = (float)$pedido['desconto'];
        $pedido['frete'] = (float)$pedido['frete'];
        $pedido['total'] = (float)$pedido['total'];
        $pedido['total_itens'] = count($pedido['itens']);
    }
    
    // ==========================================
    // RESPOSTA
    // ==========================================
    
    echo json_encode([
        'success' => true,
        'data' => $pedidos,
        'total' => count($pedidos)
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao buscar pedidos',
        'error' => $e->getMessage()
    ]);
}
?>