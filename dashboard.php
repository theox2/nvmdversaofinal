<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once '../../config.php';

try {
    // Total de pedidos
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM pedidos");
    $totalPedidos = $stmt->fetchColumn();
    
    // Total de clientes
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM usuarios WHERE tipo = 'cliente'");
    $totalClientes = $stmt->fetchColumn();
    
    // Novos clientes (últimos 30 dias)
    $stmt = $pdo->query("
        SELECT COUNT(*) as total 
        FROM usuarios 
        WHERE tipo = 'cliente' 
        AND data_cadastro >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    ");
    $novosClientes = $stmt->fetchColumn();
    
    // Vendas hoje
    $stmt = $pdo->query("
        SELECT COALESCE(SUM(total), 0) as vendas_hoje
        FROM pedidos
        WHERE DATE(data_pedido) = CURDATE()
    ");
    $vendasHoje = $stmt->fetchColumn();
    
    // Produtos com estoque baixo
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM produtos WHERE estoque > 0 AND estoque <= 10");
    $estoqueBaixo = $stmt->fetchColumn();
    
    echo json_encode([
        'success' => true,
        'data' => [
            'total_pedidos' => (int)$totalPedidos,
            'total_clientes' => (int)$totalClientes,
            'novos_clientes' => (int)$novosClientes,
            'vendas_hoje' => (float)$vendasHoje,
            'estoque_baixo' => (int)$estoqueBaixo
        ]
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