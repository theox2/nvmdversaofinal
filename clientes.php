<?php
/**
 * api/admin/clientes.php - Listar Clientes (CORRIGIDO)
 * COLOQUE EM: /Novamoda/api/admin/clientes.php
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

error_reporting(E_ALL);
ini_set('display_errors', 0);

try {
    require_once __DIR__ . '/../../config.php';
    
    if (!isset($pdo)) {
        throw new Exception('PDO não conectado');
    }
    
    // ==========================================
    // BUSCAR CLIENTES COM ESTATÍSTICAS
    // ==========================================
    
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
    
    $clientes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Formatar dados
    foreach ($clientes as &$cliente) {
        $cliente['id'] = (int)$cliente['id'];
        $cliente['total_pedidos'] = (int)$cliente['total_pedidos'];
        $cliente['total_gasto'] = (float)$cliente['total_gasto'];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $clientes,
        'total' => count($clientes)
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao buscar clientes',
        'error' => $e->getMessage()
    ]);
}
?>
