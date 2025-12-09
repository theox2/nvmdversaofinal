<?php
/**
 * api/auth/register.php - Cadastro de Novos Usuários
 * Método: POST
 * Body: { nome, email, password, telefone?, cpf? }
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
    $nome = $input['nome'] ?? '';
    $email = $input['email'] ?? '';
    $password = $input['password'] ?? '';
    $telefone = $input['telefone'] ?? null;
    $cpf = $input['cpf'] ?? null;
    
    // ==========================================
    // VALIDAÇÕES
    // ==========================================
    
    if (empty($nome) || empty($email) || empty($password)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Nome, email e senha são obrigatórios'
        ]);
        exit;
    }
    
    if (strlen($nome) < 3) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Nome deve ter no mínimo 3 caracteres'
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
    
    if (strlen($password) < 6) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Senha deve ter no mínimo 6 caracteres'
        ]);
        exit;
    }
    
    // ==========================================
    // VERIFICAR SE EMAIL JÁ EXISTE
    // ==========================================
    
    $stmt = $pdo->prepare("SELECT id FROM usuarios WHERE email = ?");
    $stmt->execute([strtolower(trim($email))]);
    
    if ($stmt->fetch()) {
        http_response_code(409);
        echo json_encode([
            'success' => false,
            'message' => 'Este email já está cadastrado'
        ]);
        exit;
    }
    
    // ==========================================
    // VERIFICAR SE CPF JÁ EXISTE (se fornecido)
    // ==========================================
    
    if ($cpf) {
        $cpfLimpo = preg_replace('/[^0-9]/', '', $cpf);
        
        if (strlen($cpfLimpo) === 11) {
            $stmt = $pdo->prepare("SELECT id FROM usuarios WHERE cpf = ?");
            $stmt->execute([$cpfLimpo]);
            
            if ($stmt->fetch()) {
                http_response_code(409);
                echo json_encode([
                    'success' => false,
                    'message' => 'Este CPF já está cadastrado'
                ]);
                exit;
            }
        }
    }
    
    // ==========================================
    // INSERIR NOVO USUÁRIO
    // ==========================================
    
    // NOTA: Estamos salvando senha em texto plano por compatibilidade com SQL inicial
    // Em produção, descomente a linha abaixo:
    // $senhaHash = password_hash($password, PASSWORD_DEFAULT);
    
    $senhaHash = $password; // Texto plano para compatibilidade
    
    $stmt = $pdo->prepare("
        INSERT INTO usuarios (nome, email, senha, telefone, cpf, tipo, ativo)
        VALUES (?, ?, ?, ?, ?, 'cliente', 1)
    ");
    
    $cpfFormatado = $cpf ? preg_replace('/[^0-9]/', '', $cpf) : null;
    
    $stmt->execute([
        trim($nome),
        strtolower(trim($email)),
        $senhaHash,
        $telefone,
        $cpfFormatado
    ]);
    
    $userId = $pdo->lastInsertId();
    
    // ==========================================
    // REGISTRAR LOG
    // ==========================================
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO logs_sistema (usuario_id, acao, descricao, ip_address)
            VALUES (?, 'cadastro', 'Novo usuário cadastrado', ?)
        ");
        $stmt->execute([
            $userId,
            $_SERVER['REMOTE_ADDR'] ?? 'unknown'
        ]);
    } catch (PDOException $e) {
        // Ignora erro de log
    }
    
    // ==========================================
    // RETORNAR SUCESSO
    // ==========================================
    
    echo json_encode([
        'success' => true,
        'message' => 'Cadastro realizado com sucesso',
        'user' => [
            'id' => (int)$userId,
            'nome' => trim($nome),
            'email' => strtolower(trim($email)),
            'tipo' => 'cliente',
            'isAdmin' => false
        ],
        'token' => base64_encode($userId . ':' . time()) // Token simples para demo
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao criar conta',
        'error' => $e->getMessage()
    ]);
}
?>