<?php
/**
 * api/admin/produtos/atualizar.php - Atualizar Produto Existente
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, PUT');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../../../config.php';

if (!in_array($_SERVER['REQUEST_METHOD'], ['POST', 'PUT'])) {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Apenas POST ou PUT permitido']));
}

$input = json_decode(file_get_contents('php://input'), true);

try {
    // Validar ID
    if (!isset($input['id']) || empty($input['id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID do produto é obrigatório'
        ]);
        exit;
    }
    
    // Verificar se produto existe
    $stmt = $pdo->prepare("SELECT id FROM produtos WHERE id = ?");
    $stmt->execute([$input['id']]);
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Produto não encontrado'
        ]);
        exit;
    }
    
    // Atualizar produto
    $stmt = $pdo->prepare("
        UPDATE produtos SET
            nome = ?,
            descricao = ?,
            categoria_id = ?,
            preco = ?,
            preco_antigo = ?,
            estoque = ?,
            imagem_principal = ?,
            ultima_atualizacao = CURRENT_TIMESTAMP
        WHERE id = ?
    ");
    
    $stmt->execute([
        $input['nome'],
        $input['descricao'] ?? null,
        $input['categoria_id'],
        $input['preco'],
        $input['preco_antigo'] ?? null,
        $input['estoque'] ?? 0,
        $input['imagem_principal'],
        $input['id']
    ]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Produto atualizado com sucesso'
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao atualizar produto',
        'error' => $e->getMessage()
    ]);
}
?>