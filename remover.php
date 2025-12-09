<?php
/**
 * api/carrinho/limpar.php - Limpar todo o carrinho do usuário
 * Método: POST
 * Body: { usuario_id }
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Apenas POST permitido']));
}

$input = json_decode(file_get_contents('php://input'), true);

try {
    $usuario_id = $input['usuario_id'] ?? null;
    
    if (!$usuario_id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'usuario_id é obrigatório'
        ]);
        exit;
    }
    
    // Buscar o carrinho do usuário
    $stmt = $pdo->prepare("SELECT id FROM carrinhos WHERE usuario_id = ?");
    $stmt->execute([$usuario_id]);
    $carrinho = $stmt->fetch();
    
    if (!$carrinho) {
        echo json_encode([
            'success' => true,
            'message' => 'Carrinho já estava vazio'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Remover todos os itens do carrinho
    $stmt = $pdo->prepare("DELETE FROM carrinho_itens WHERE carrinho_id = ?");
    $stmt->execute([$carrinho['id']]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Carrinho limpo com sucesso',
        'itens_removidos' => $stmt->rowCount()
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao limpar carrinho',
        'error' => $e->getMessage()
    ]);
}
?>