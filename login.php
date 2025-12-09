<?php
/**
 * api/auth/login.php - Login de Usuários
 * Método: POST
 * Body: { email, password }
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

// Pegar dados JSON do corpo da requisição
$input = json_decode(file_get_contents('php://input'), true);

try {
    $email = $input['email'] ?? '';
    $password = $input['password'] ?? '';
    
    // ==========================================
    // VALIDAÇÕES
    // ==========================================
    
    if (empty($email) || empty($password)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Email e senha são obrigatórios'
        ]);
        exit;
    }
    
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Email inválido'
        ]);
        exit;
    }
    
    // ==========================================
    // BUSCAR USUÁRIO
    // ==========================================
    
    $stmt = $pdo->prepare("
        SELECT id, nome, email, senha, tipo, ativo 
        FROM usuarios 
        WHERE email = ?
    ");
    
    $stmt->execute([strtolower(trim($email))]);
    $usuario = $stmt->fetch();
    
    if (!$usuario) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Email ou senha incorretos'
        ]);
        exit;
    }
    
    // ==========================================
    // VERIFICAR SE USUÁRIO ESTÁ ATIVO
    // ==========================================
    
    if (!$usuario['ativo']) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Usuário desativado. Entre em contato com o suporte.'
        ]);
        exit;
    }
    
    // ==========================================
    // VERIFICAR SENHA
    // ==========================================
    
    // NOTA: O SQL inicial usa senha em texto plano
    // Em produção, use: password_verify($password, $usuario['senha'])
    
    $senhaCorreta = false;
    
    // Tentar verificar com hash primeiro
    if (password_verify($password, $usuario['senha'])) {
        $senhaCorreta = true;
    } 
    // Se não funcionar, comparar texto plano (compatibilidade com SQL inicial)
    elseif ($password === $usuario['senha']) {
        $senhaCorreta = true;
    }
    
    if (!$senhaCorreta) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Email ou senha incorretos'
        ]);
        exit;
    }
    
    // ==========================================
    // LOGIN BEM-SUCEDIDO
    // ==========================================
    
    // Registrar log de acesso (opcional)
    try {
        $stmt = $pdo->prepare("
            INSERT INTO logs_sistema (usuario_id, acao, descricao, ip_address)
            VALUES (?, 'login', 'Login realizado com sucesso', ?)
        ");
        $stmt->execute([
            $usuario['id'],
            $_SERVER['REMOTE_ADDR'] ?? 'unknown'
        ]);
    } catch (PDOException $e) {
        // Ignora erro de log
    }
    
    // ==========================================
    // RETORNAR DADOS DO USUÁRIO
    // ==========================================
    
    echo json_encode([
        'success' => true,
        'message' => 'Login realizado com sucesso',
        'user' => [
            'id' => (int)$usuario['id'],
            'nome' => $usuario['nome'],
            'email' => $usuario['email'],
            'tipo' => $usuario['tipo'],
            'isAdmin' => $usuario['tipo'] === 'admin'
        ],
        'token' => base64_encode($usuario['id'] . ':' . time()) // Token simples para demo
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro no servidor',
        'error' => $e->getMessage()
    ]);
}
?>