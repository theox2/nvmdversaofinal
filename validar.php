<?php
/**
 * api/cupons/validar.php - Validar cupom de desconto
 * Método: POST
 * Body: { codigo, subtotal }
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
    $codigo = strtoupper(trim($input['codigo'] ?? ''));
    $subtotal = (float)($input['subtotal'] ?? 0);
    
    if (empty($codigo)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Código do cupom é obrigatório'
        ]);
        exit;
    }
    
    // Buscar cupom
    $stmt = $pdo->prepare("
        SELECT * FROM cupons 
        WHERE codigo = ? AND ativo = 1
    ");
    $stmt->execute([$codigo]);
    $cupom = $stmt->fetch();
    
    if (!$cupom) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Cupom inválido ou expirado'
        ]);
        exit;
    }
    
    // Validar data de expiração
    if ($cupom['data_expiracao'] && strtotime($cupom['data_expiracao']) < time()) {
        echo json_encode([
            'success' => false,
            'message' => 'Este cupom expirou'
        ]);
        exit;
    }
    
    // Validar data de início
    if ($cupom['data_inicio'] && strtotime($cupom['data_inicio']) > time()) {
        echo json_encode([
            'success' => false,
            'message' => 'Este cupom ainda não está ativo'
        ]);
        exit;
    }
    
    // Validar valor mínimo
    if ($cupom['valor_minimo'] && $subtotal < $cupom['valor_minimo']) {
        echo json_encode([
            'success' => false,
            'message' => sprintf(
                'Valor mínimo para este cupom: R$ %.2f', 
                $cupom['valor_minimo']
            )
        ]);
        exit;
    }
    
    // Validar limite de uso
    if ($cupom['limite_uso'] && $cupom['vezes_usado'] >= $cupom['limite_uso']) {
        echo json_encode([
            'success' => false,
            'message' => 'Este cupom atingiu o limite de uso'
        ]);
        exit;
    }
    
    // Calcular desconto
    $desconto = 0;
    if ($cupom['tipo'] === 'percentual') {
        $desconto = $subtotal * ((float)$cupom['valor'] / 100);
    } else {
        $desconto = (float)$cupom['valor'];
    }
    
    // Não permitir desconto maior que o subtotal
    $desconto = min($desconto, $subtotal);
    
    echo json_encode([
        'success' => true,
        'message' => 'Cupom aplicado com sucesso!',
        'cupom' => [
            'codigo' => $cupom['codigo'],
            'tipo' => $cupom['tipo'],
            'valor' => (float)$cupom['valor'],
            'desconto' => round($desconto, 2),
            'descricao' => $cupom['descricao']
        ]
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao validar cupom',
        'error' => $e->getMessage()
    ]);
}
?>