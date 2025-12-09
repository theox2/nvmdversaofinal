<?php
/**
 * api/admin/pedidos/detalhes.php - Detalhes de um pedido
 * Método: GET
 * Params: ?id=1
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once '../../../config.php';

try {
    $id = $_GET['id'] ?? null;
    
    if (!$id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID do pedido é obrigatório'
        ]);
        exit;
    }
    
    // Buscar pedido
    $stmt = $pdo->prepare("
        SELECT 
            p.*,
            u.nome as cliente_nome,
            u.email as cliente_email,
            u.telefone as cliente_telefone
        FROM pedidos p
        JOIN usuarios u ON p.usuario_id = u.id
        WHERE p.id = ?
    ");
    $stmt->execute([$id]);
    $pedido = $stmt->fetch();
    
    if (!$pedido) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Pedido não encontrado'
        ]);
        exit;
    }
    
    // Buscar itens
    $stmt = $pdo->prepare("
        SELECT 
            pi.*,
            p.imagem_principal as imagem
        FROM pedido_itens pi
        LEFT JOIN produtos p ON pi.produto_id = p.id
        WHERE pi.pedido_id = ?
    ");
    $stmt->execute([$id]);
    $pedido['itens'] = $stmt->fetchAll();
    
    // Buscar endereço
    $stmt = $pdo->prepare("SELECT * FROM enderecos WHERE id = ?");
    $stmt->execute([$pedido['endereco_id'] ?? 0]);
    $pedido['endereco'] = $stmt->fetch() ?: [];
    
    echo json_encode([
        'success' => true,
        'data' => $pedido
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao buscar pedido',
        'error' => $e->getMessage()
    ]);
}
?>