<?php
/**
 * api/carrinho/adicionar.php - Adicionar item ao carrinho
 * Método: POST
 * Body: { usuario_id?, sessao_id?, produto_id, quantidade, tamanho?, cor? }
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
    // ==========================================
    // VALIDAÇÕES
    // ==========================================
    
    $usuario_id = $input['usuario_id'] ?? null;
    $sessao_id = $input['sessao_id'] ?? null;
    $produto_id = $input['produto_id'] ?? null;
    $quantidade = $input['quantidade'] ?? 1;
    $tamanho = $input['tamanho'] ?? null;
    $cor = $input['cor'] ?? null;
    
    // Precisa ter usuário OU sessão
    if (!$usuario_id && !$sessao_id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'usuario_id ou sessao_id é obrigatório'
        ]);
        exit;
    }
    
    // Validar produto
    if (!$produto_id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'produto_id é obrigatório'
        ]);
        exit;
    }
    
    // Verificar se produto existe e está ativo
    $stmt = $pdo->prepare("
        SELECT id, nome, preco, estoque, ativo 
        FROM produtos 
        WHERE id = ?
    ");
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
    
    if (!$produto['ativo']) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Produto não está disponível'
        ]);
        exit;
    }
    
    // Validar estoque
    if ($produto['estoque'] < $quantidade) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Estoque insuficiente',
            'estoque_disponivel' => (int)$produto['estoque']
        ]);
        exit;
    }
    
    // ==========================================
    // BUSCAR OU CRIAR CARRINHO
    // ==========================================
    
    $carrinho_id = null;
    
    if ($usuario_id) {
        // Buscar carrinho do usuário
        $stmt = $pdo->prepare("SELECT id FROM carrinhos WHERE usuario_id = ?");
        $stmt->execute([$usuario_id]);
        $carrinho = $stmt->fetch();
        
        if ($carrinho) {
            $carrinho_id = $carrinho['id'];
        } else {
            // Criar novo carrinho para o usuário
            $stmt = $pdo->prepare("INSERT INTO carrinhos (usuario_id) VALUES (?)");
            $stmt->execute([$usuario_id]);
            $carrinho_id = $pdo->lastInsertId();
        }
    } else {
        // Buscar carrinho por sessão
        $stmt = $pdo->prepare("SELECT id FROM carrinhos WHERE sessao_id = ?");
        $stmt->execute([$sessao_id]);
        $carrinho = $stmt->fetch();
        
        if ($carrinho) {
            $carrinho_id = $carrinho['id'];
        } else {
            // Criar novo carrinho para a sessão
            $stmt = $pdo->prepare("INSERT INTO carrinhos (sessao_id) VALUES (?)");
            $stmt->execute([$sessao_id]);
            $carrinho_id = $pdo->lastInsertId();
        }
    }
    
    // ==========================================
    // VERIFICAR SE ITEM JÁ EXISTE NO CARRINHO
    // ==========================================
    
    $stmt = $pdo->prepare("
        SELECT id, quantidade 
        FROM carrinho_itens 
        WHERE carrinho_id = ? 
        AND produto_id = ? 
        AND (tamanho = ? OR (tamanho IS NULL AND ? IS NULL))
        AND (cor = ? OR (cor IS NULL AND ? IS NULL))
    ");
    $stmt->execute([$carrinho_id, $produto_id, $tamanho, $tamanho, $cor, $cor]);
    $item_existente = $stmt->fetch();
    
    if ($item_existente) {
        // ==========================================
        // ATUALIZAR QUANTIDADE DO ITEM EXISTENTE
        // ==========================================
        
        $nova_quantidade = $item_existente['quantidade'] + $quantidade;
        
        // Verificar estoque novamente
        if ($nova_quantidade > $produto['estoque']) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Estoque insuficiente para essa quantidade',
                'quantidade_atual_carrinho' => (int)$item_existente['quantidade'],
                'estoque_disponivel' => (int)$produto['estoque']
            ]);
            exit;
        }
        
        $stmt = $pdo->prepare("
            UPDATE carrinho_itens 
            SET quantidade = ? 
            WHERE id = ?
        ");
        $stmt->execute([$nova_quantidade, $item_existente['id']]);
        
        $mensagem = 'Quantidade atualizada no carrinho';
        $item_id = $item_existente['id'];
        
    } else {
        // ==========================================
        // ADICIONAR NOVO ITEM AO CARRINHO
        // ==========================================
        
        $stmt = $pdo->prepare("
            INSERT INTO carrinho_itens (
                carrinho_id,
                produto_id,
                quantidade,
                tamanho,
                cor,
                preco_unitario
            ) VALUES (?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $carrinho_id,
            $produto_id,
            $quantidade,
            $tamanho,
            $cor,
            $produto['preco']
        ]);
        
        $item_id = $pdo->lastInsertId();
        $mensagem = 'Produto adicionado ao carrinho';
    }
    
    // ==========================================
    // BUSCAR TOTAL DO CARRINHO
    // ==========================================
    
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_itens,
            SUM(quantidade) as total_quantidade,
            SUM(quantidade * preco_unitario) as subtotal
        FROM carrinho_itens
        WHERE carrinho_id = ?
    ");
    $stmt->execute([$carrinho_id]);
    $totais = $stmt->fetch();
    
    // ==========================================
    // RESPOSTA
    // ==========================================
    
    echo json_encode([
        'success' => true,
        'message' => $mensagem,
        'data' => [
            'carrinho_id' => (int)$carrinho_id,
            'item_id' => (int)$item_id,
            'produto' => [
                'id' => (int)$produto['id'],
                'nome' => $produto['nome'],
                'preco' => (float)$produto['preco']
            ],
            'quantidade' => (int)($nova_quantidade ?? $quantidade),
            'tamanho' => $tamanho,
            'cor' => $cor,
            'totais' => [
                'total_itens' => (int)$totais['total_itens'],
                'total_quantidade' => (int)$totais['total_quantidade'],
                'subtotal' => (float)$totais['subtotal']
            ]
        ]
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro ao adicionar ao carrinho',
        'error' => $e->getMessage()
    ]);
}
?>