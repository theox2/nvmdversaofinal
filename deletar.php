<?php
/**
 * api/admin/produtos/deletar.php - Deletar Produto
 * Método: POST/DELETE
 * Body: { id }
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../../../config.php';

if (!in_array($_SERVER['REQUEST_METHOD'], ['POST', 'DELETE'])) {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Apenas POST ou DELETE permitido']));
}

$input = json_decode(file_get_contents('php://input'), true);

try {
    // ==========================================
    // VALIDAR ID
    // ==========================================
    
    if (!isset($input['id']) || empty($input['id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID do produto é obrigatório'
        ]);
        exit;
    }
    
    $produto_id = $input['id'];
    
    // Verificar se produto existe
    $stmt = $pdo->prepare("SELECT id, nome FROM produtos WHERE id = ?");
    $stmt->execute([$produto_id]);
    $produto = $stmt->fetch();
    
    if (!$produto) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Produto não encontrado'
        ]);
        exit;
    }
    
    // ==========================================
    // DELETAR PRODUTO (CASCADE automático)
    // ==========================================
    
    // O banco tem CASCADE configurado, então ao deletar o produto
    // automaticamente deleta: tamanhos, cores, imagens, avaliações
    
    $stmt = $pdo->prepare("DELETE FROM produtos WHERE id = ?");
    $stmt->execute([$produto_id]);
    
    // ==========================================
    // RESPOSTA
    // ==========================================
    
    echo json_encode([
        'success' => true,
        'message' => "Produto '{$produto['nome']}' deletado com sucesso"
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    // Verificar se tem pedidos relacionados
    if ($e->getCode() == '23000') {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Não é possível deletar este produto pois existem pedidos relacionados'
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Erro ao deletar produto',
            'error' => $e->getMessage()
        ]);
    }
}
?>