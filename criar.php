<?php
/**
 * api/admin/produtos/criar.php - Criar Novo Produto
 * Método: POST
 * Body: { nome, preco, preco_antigo?, categoria_id, estoque, imagem_principal, descricao?, tamanhos[], cores[] }
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Apenas POST permitido']));
}

$input = json_decode(file_get_contents('php://input'), true);

try {
    // ==========================================
    // VALIDAÇÕES
    // ==========================================
    
    $required = ['nome', 'preco', 'categoria_id', 'imagem_principal'];
    foreach ($required as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => "Campo obrigatório ausente: {$field}"
            ]);
            exit;
        }
    }
    
    // Validar categoria existe
    $stmt = $pdo->prepare("SELECT id FROM categorias WHERE id = ?");
    $stmt->execute([$input['categoria_id']]);
    if (!$stmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Categoria não encontrada'
        ]);
        exit;
    }
    
    // ==========================================
    // CRIAR SLUG
    // ==========================================
    
    function gerarSlug($texto) {
        $texto = strtolower($texto);
        $texto = preg_replace('/[^a-z0-9\s-]/', '', $texto);
        $texto = preg_replace('/[\s-]+/', '-', $texto);
        $texto = trim($texto, '-');
        return $texto;
    }
    
    $slug = gerarSlug($input['nome']);
    
    // Verificar se slug já existe e adicionar número se necessário
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM produtos WHERE slug LIKE ?");
    $stmt->execute([$slug . '%']);
    $count = $stmt->fetchColumn();
    
    if ($count > 0) {
        $slug = $slug . '-' . ($count + 1);
    }
    
    // ==========================================
    // INSERIR PRODUTO
    // ==========================================
    
    $stmt = $pdo->prepare("
        INSERT INTO produtos (
            nome,
            slug,
            descricao,
            categoria_id,
            preco,
            preco_antigo,
            estoque,
            imagem_principal,
            ativo,
            destaque
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
    ");
    
    $stmt->execute([
        $input['nome'],
        $slug,
        $input['descricao'] ?? null,
        $input['categoria_id'],
        $input['preco'],
        $input['preco_antigo'] ?? null,
        $input['estoque'] ?? 0,
        $input['imagem_principal'],
        $input['destaque'] ?? 0
    ]);
    
    $produto_id = $pdo->lastInsertId();
    
    // ==========================================
    // ADICIONAR TAMANHOS
    // ==========================================
    
    if (!empty($input['tamanhos']) && is_array($input['tamanhos'])) {
        $stmt = $pdo->prepare("
            INSERT INTO produto_tamanhos (produto_id, tamanho, estoque)
            VALUES (?, ?, ?)
        ");
        
        foreach ($input['tamanhos'] as $tamanho) {
            $stmt->execute([
                $produto_id,
                $tamanho['tamanho'] ?? $tamanho,
                $tamanho['estoque'] ?? $input['estoque'] ?? 0
            ]);
        }
    }
    
    // ==========================================
    // ADICIONAR CORES
    // ==========================================
    
    if (!empty($input['cores']) && is_array($input['cores'])) {
        $stmt = $pdo->prepare("
            INSERT INTO produto_cores (produto_id, cor, codigo_hex)
            VALUES (?, ?, ?)
        ");
        
        foreach ($input['cores'] as $cor) {
            $stmt->execute([
                $produto_id,
                $cor['cor'] ?? $cor,
                $cor['codigo_hex'] ?? null
            ]);
        }
    }
    
    // ==========================================
    // ADICIONAR IMAGENS ADICIONAIS
    // ==========================================
    
    if (!empty($input['imagens']) && is_array($input['imagens'])) {
        $stmt = $pdo->prepare("
            INSERT INTO produto_imagens (produto_id, url, ordem)
            VALUES (?, ?, ?)
        ");
        
        foreach ($input['imagens'] as $index => $url) {
            $stmt->execute([
                $produto_id,
                $url,
                $index + 1
            ]);
        }
    }
    
    // ==========================================
    // BUSCAR PRODUTO COMPLETO
    // ==========================================
    
    $stmt = $pdo->prepare("
        SELECT 
            p.*,
            c.nome as categoria_nome,
            c.slug as categoria_slug
        FROM produtos p
        LEFT JOIN categorias c ON p.categoria_id = c.id
        WHERE p.id = ?
    ");
    $stmt->execute([$produto_id]);
    $produto = $stmt->fetch();
    
    // ==========================================
    // RESPOSTA
    // ==========================================
    
    echo json_encode([
        'success' => true,
        'message' => 'Produto criado com sucesso',
        'produto' => [
            'id' => (int)$produto['id'],
            'nome' => $produto['nome'],
            'slug' => $produto['slug'],
            'preco' => (float)$produto['preco'],
            'estoque' => (int)$produto['estoque'],
            'categoria_nome' => $produto['categoria_nome']
        ]
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao criar produto',
        'error' => $e->getMessage()
    ]);
}
?>