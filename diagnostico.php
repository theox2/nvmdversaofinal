<?php
/**
 * diagnostico.php - Verificar Estrutura e Conexões
 * COLOQUE EM: /Novamoda/api/diagnostico.php
 * 
 * ACESSE: http://localhost/Novamoda/api/diagnostico.php
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$diagnostico = [
    'timestamp' => date('Y-m-d H:i:s'),
    'servidor' => [
        'php_version' => PHP_VERSION,
        'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Desconhecido',
        'document_root' => $_SERVER['DOCUMENT_ROOT'] ?? 'Desconhecido'
    ],
    'caminhos' => [
        'script_atual' => __FILE__,
        'diretorio_atual' => __DIR__,
        'config_path' => __DIR__ . '/../config.php',
        'config_existe' => file_exists(__DIR__ . '/../config.php')
    ],
    'estrutura_pastas' => [],
    'banco' => [],
    'tabelas' => []
];

// ==========================================
// 1. VERIFICAR ESTRUTURA DE PASTAS
// ==========================================

$pastas_necessarias = [
    '../config.php',
    'auth/login.php',
    'auth/register.php',
    'produtos/listar.php',
    'produtos/detalhes.php',
    'admin/dashboard.php',
    'admin/clientes.php',
    'admin/pedidos/listar.php',
    'carrinho/adicionar.php',
    'carrinho/listar.php'
];

foreach ($pastas_necessarias as $caminho) {
    $caminho_completo = __DIR__ . '/' . $caminho;
    $diagnostico['estrutura_pastas'][$caminho] = [
        'caminho_completo' => $caminho_completo,
        'existe' => file_exists($caminho_completo),
        'legivel' => is_readable($caminho_completo)
    ];
}

// ==========================================
// 2. TESTAR CONEXÃO COM BANCO
// ==========================================

try {
    $config_file = __DIR__ . '/../config.php';
    
    if (!file_exists($config_file)) {
        throw new Exception('config.php não encontrado!');
    }
    
    require_once $config_file;
    
    if (!isset($pdo)) {
        throw new Exception('Variável $pdo não definida no config.php');
    }
    
    // Testar conexão
    $pdo->query("SELECT 1");
    
    $diagnostico['banco']['status'] = 'CONECTADO ✓';
    $diagnostico['banco']['host'] = DB_HOST ?? 'Não definido';
    $diagnostico['banco']['database'] = DB_NAME ?? 'Não definido';
    $diagnostico['banco']['user'] = DB_USER ?? 'Não definido';
    
    // ==========================================
    // 3. VERIFICAR TABELAS
    // ==========================================
    
    $stmt = $pdo->query("SHOW TABLES");
    $tabelas = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    $diagnostico['tabelas']['total'] = count($tabelas);
    $diagnostico['tabelas']['lista'] = $tabelas;
    
    // Contar registros em cada tabela
    $diagnostico['tabelas']['registros'] = [];
    
    foreach ($tabelas as $tabela) {
        try {
            $stmt = $pdo->query("SELECT COUNT(*) FROM `$tabela`");
            $count = $stmt->fetchColumn();
            $diagnostico['tabelas']['registros'][$tabela] = (int)$count;
        } catch (PDOException $e) {
            $diagnostico['tabelas']['registros'][$tabela] = 'ERRO: ' . $e->getMessage();
        }
    }
    
} catch (Exception $e) {
    $diagnostico['banco']['status'] = 'ERRO ✗';
    $diagnostico['banco']['erro'] = $e->getMessage();
}

// ==========================================
// 4. VERIFICAR PERMISSÕES
// ==========================================

$diagnostico['permissoes'] = [
    'api_dir_writable' => is_writable(__DIR__),
    'config_readable' => is_readable(__DIR__ . '/../config.php')
];

// ==========================================
// 5. RESPOSTA
// ==========================================

// Se tudo OK
$tudo_ok = true;

if ($diagnostico['banco']['status'] !== 'CONECTADO ✓') {
    $tudo_ok = false;
}

if (!$diagnostico['caminhos']['config_existe']) {
    $tudo_ok = false;
}

$diagnostico['status_geral'] = $tudo_ok ? 'TUDO OK ✓✓✓' : 'PROBLEMAS ENCONTRADOS ✗';

echo json_encode($diagnostico, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>
