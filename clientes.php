<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once '../../config.php';

try {
    $stmt = $pdo->query("
        SELECT 
            u.id,
            u.nome,
            u.email,
            u.telefone,
            u.cpf,
            u.data_cadastro,
            COUNT(DISTINCT p.id) as total_pedidos,
            COALESCE(SUM(p.total), 0) as total_gasto
        FROM usuarios u
        LEFT JOIN pedidos p ON u.id = p.usuario_id
        WHERE u.tipo = 'cliente'
        GROUP BY u.id
        ORDER BY u.data_cadastro DESC
    ");
    
    $clientes = $stmt->fetchAll();
    
    foreach ($clientes as &$cliente) {
        $cliente['total_pedidos'] = (int)$cliente['total_pedidos'];
        $cliente['total_gasto'] = (float)$cliente['total_gasto'];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $clientes
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>

<?php
// CORS Headers
require_once __DIR__ . '/../cors.php';

require_once __DIR__ . '/../../config.php';