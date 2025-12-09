/**
 * admin-api.js - VERSÃO CORRIGIDA
 * Remove TODOS os usos de localStorage e usa apenas o banco de dados
 */

const API_BASE = window.API_BASE || (window.location.origin + '/Novamoda/api');

console.log('🔗 API Base:', API_BASE);

class AdminAPI {
  constructor() {
    this.init();
  }
  
  // ==========================================
  // HELPER: FAZER REQUISIÇÕES
  // ==========================================
  
  async request(endpoint, options = {}) {
    try {
      const url = `${API_BASE}${endpoint}`;
      console.log('📡 Request:', url);

      const response = await fetch(url, {
        headers: {
          'Content-Type': 'application/json',
          ...options.headers
        },
        ...options
      });

      const data = await response.json();
      console.log('📥 Response:', data);

      if (!response.ok) {
        throw new Error(data.message || 'Erro na requisição');
      }

      return data;
    } catch (error) {
      console.error('❌ Erro na API:', error);
      this.showToast(error.message, 'error');
      throw error;
    }
  }

  // ==========================================
  // DASHBOARD - DO BANCO
  // ==========================================
  
  async loadDashboard() {
    try {
      const stats = await this.request('/admin/dashboard.php');
      
      if (stats.success) {
        const data = stats.data;
        
        this.updateElement('totalPedidos', data.total_pedidos);
        this.updateElement('totalClientes', data.total_clientes);
        this.updateElement('newCustomers', data.novos_clientes);
        this.updateElement('vendasHoje', `R$ ${this.formatMoney(data.vendas_hoje)}`);
        
        if (data.estoque_baixo > 0) {
          this.updateElement('lowStockCount', data.estoque_baixo);
        }
      }
    } catch (error) {
      console.error('Erro ao carregar dashboard:', error);
    }
  }

  // ==========================================
  // PRODUTOS - DO BANCO
  // ==========================================
  
  async renderProdutosAdmin() {
    const grid = document.getElementById('productsGrid');
    if (!grid) return;

    grid.innerHTML = '<div style="grid-column:1/-1;text-align:center;padding:40px;color:#888;">⏳ Carregando produtos...</div>';

    try {
      const response = await this.request('/produtos/listar.php?limit=100');
      
      if (!response.success || !response.data || response.data.length === 0) {
        grid.innerHTML = '<div style="grid-column:1/-1;text-align:center;padding:60px;color:#888;"><div style="font-size:4rem;margin-bottom:20px;">📦</div><h3>Nenhum produto cadastrado</h3><p>Clique em "Novo Produto" para adicionar</p></div>';
        return;
      }

      const produtos = response.data;

      grid.innerHTML = produtos.map(p => {
        const stockColor = p.estoque > 10 ? '#4ade80' : (p.estoque > 0 ? '#fbbf24' : '#ff3b30');
        const stockLabel = p.estoque > 10 ? 'Em Estoque' : (p.estoque > 0 ? 'Estoque Baixo' : 'Esgotado');
        
        return `
          <div class="product-card" style="background:#111;border:1px solid #222;border-radius:12px;overflow:hidden;">
            <img src="${p.imagem_principal}" style="width:100%;height:200px;object-fit:cover;" alt="${p.nome}" onerror="this.src='https://via.placeholder.com/400x200/14d0d6/000?text=Sem+Imagem'">
            <div style="padding:16px;">
              <h3 style="color:#fff;font-size:16px;margin:0 0 8px 0;">${p.nome}</h3>
              <div style="color:#14d0d6;font-size:20px;font-weight:800;margin-bottom:8px;">
                R$ ${parseFloat(p.preco).toFixed(2).replace('.', ',')}
              </div>
              <div style="display:flex;gap:8px;font-size:13px;color:#888;margin-bottom:12px;">
                <span style="color:${stockColor};">● ${stockLabel}: ${p.estoque}</span>
                <span>•</span>
                <span>${p.categoria_nome || 'Sem categoria'}</span>
              </div>
              <div style="display:flex;gap:8px;">
                <button class="btn btn-primary" onclick="editarProduto(${p.id})" style="flex:1;padding:8px;">
                  ✏️ Editar
                </button>
                <button class="btn btn-danger" onclick="deletarProduto(${p.id}, '${p.nome.replace(/'/g, "\\'")}', ${p.estoque})" style="padding:8px 12px;">
                  🗑️
                </button>
              </div>
            </div>
          </div>
        `;
      }).join('');

    } catch (error) {
      console.error('❌ Erro ao carregar produtos:', error);
      grid.innerHTML = `<div style="grid-column:1/-1;text-align:center;padding:40px;color:#ff3b30;">
        ❌ Erro ao carregar produtos<br>
        <small>${error.message}</small>
      </div>`;
    }
  }

  // ==========================================
  // CLIENTES - DO BANCO
  // ==========================================
  
  async renderClientesAdmin() {
    const tbody = document.querySelector('#clientsTable tbody');
    if (!tbody) return;

    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:40px;color:#888;">⏳ Carregando clientes...</td></tr>';

    try {
      const response = await this.request('/admin/clientes.php');
      
      if (!response.success || !response.data || response.data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:40px;color:#888;">👥 Nenhum cliente cadastrado</td></tr>';
        return;
      }

      const clientes = response.data;

      tbody.innerHTML = clientes.map(c => {
        const dataCadastro = new Date(c.data_cadastro).toLocaleDateString('pt-BR');
        const totalGasto = parseFloat(c.total_gasto || 0);
        const totalPedidos = parseInt(c.total_pedidos || 0);
        
        return `
          <tr>
            <td><strong>#${c.id}</strong></td>
            <td>
              <div style="font-weight:600;color:#fff;">${c.nome}</div>
              <div style="font-size:12px;color:#888;">${c.email}</div>
            </td>
            <td>${c.telefone || '-'}</td>
            <td>${totalPedidos}</td>
            <td><strong style="color:#14d0d6;">R$ ${this.formatMoney(totalGasto)}</strong></td>
            <td>${dataCadastro}</td>
          </tr>
        `;
      }).join('');

      this.updateElement('totalClientes', clientes.length);

    } catch (error) {
      tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:40px;color:#ff3b30;">❌ Erro ao carregar clientes</td></tr>';
    }
  }

  // ==========================================
  // PEDIDOS - DO BANCO COM DADOS COMPLETOS
  // ==========================================
  
  async renderPedidosAdmin() {
    const tbody = document.querySelector('#ordersTable tbody');
    if (!tbody) return;

    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:40px;color:#888;">⏳ Carregando pedidos...</td></tr>';

    try {
      const response = await this.request('/admin/pedidos/listar.php');
      
      if (!response.success || !response.data || response.data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:40px;color:#888;">📦 Nenhum pedido ainda</td></tr>';
        return;
      }

      const pedidos = response.data;

      tbody.innerHTML = pedidos.slice(0, 10).map(p => {
        const data = new Date(p.data_pedido).toLocaleDateString('pt-BR');
        const total_itens = p.total_itens || p.itens?.length || 0;
        
        return `
          <tr>
            <td><strong>${p.numero_pedido}</strong></td>
            <td>
              <strong>${p.cliente_nome}</strong><br>
              <small style="color:#888;">${p.cliente_email}</small>
            </td>
            <td>${total_itens} itens</td>
            <td><strong style="color:#14d0d6;">R$ ${this.formatMoney(p.total)}</strong></td>
            <td><span class="status status-${p.status}">${this.getStatusLabel(p.status)}</span></td>
            <td>${data}</td>
            <td>
              <button class="btn" style="padding:6px 12px;font-size:12px;" onclick="verPedido(${p.id})">
                Ver
              </button>
            </td>
          </tr>
        `;
      }).join('');

      this.updateElement('totalPedidos', pedidos.length);

    } catch (error) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:40px;color:#ff3b30;">❌ Erro ao carregar pedidos</td></tr>';
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================
  
  formatMoney(value) {
    return parseFloat(value || 0).toFixed(2).replace('.', ',');
  }

  updateElement(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
  }

  getStatusLabel(status) {
    const labels = {
      'pendente': 'Pendente',
      'processando': 'Processando',
      'enviado': 'Enviado',
      'entregue': 'Entregue',
      'cancelado': 'Cancelado'
    };
    return labels[status] || status;
  }

  showToast(message, type = 'info') {
    const colors = {
      success: '#14d0d6',
      error: '#ff3b30',
      info: '#0ea5e9'
    };

    const toast = document.createElement('div');
    toast.textContent = message;
    toast.style.cssText = `
      position: fixed;
      bottom: 30px;
      right: 30px;
      background: ${colors[type]};
      color: ${type === 'error' ? '#fff' : '#000'};
      padding: 16px 24px;
      border-radius: 8px;
      font-weight: 600;
      box-shadow: 0 8px 20px rgba(0,0,0,0.3);
      z-index: 9999;
      animation: adminSlideIn 0.3s ease;
    `;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
      toast.style.animation = 'adminSlideOut 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, 3000);
  }

  // ==========================================
  // INICIALIZAÇÃO
  // ==========================================
  
  init() {
    const path = window.location.pathname;

    if (path.includes('admin.html')) {
      this.loadDashboard();
      this.renderPedidosAdmin();
    } else if (path.includes('admin-produtos')) {
      this.renderProdutosAdmin();
    } else if (path.includes('admin-clientes')) {
      this.renderClientesAdmin();
    } else if (path.includes('admin-pedidos')) {
      this.renderPedidosAdmin();
    }

    console.log('✅ AdminAPI inicializado (100% BANCO DE DADOS)');
  }
}

// Inicializar
document.addEventListener('DOMContentLoaded', () => {
  window.adminAPI = new AdminAPI();
  
  // Funções globais
  window.editarProduto = (id) => window.adminAPI.editarProduto?.(id);
  window.deletarProduto = (id, nome, estoque) => window.adminAPI.deletarProduto?.(id, nome, estoque);
  
  window.verPedido = async (id) => {
    try {
      const response = await fetch(`${API_BASE}/admin/pedidos/detalhes.php?id=${id}`);
      const data = await response.json();
      
      if (data.success) {
        const p = data.data;
        
        const itensHTML = p.itens.map(item => `
          - ${item.quantidade}x ${item.produto_nome} 
          ${item.tamanho ? `(${item.tamanho})` : ''} 
          ${item.cor ? `[${item.cor}]` : ''}
          R$ ${parseFloat(item.preco_unitario).toFixed(2)}
        `).join('\n');
        
        alert(
          `📦 PEDIDO ${p.numero_pedido}\n\n` +
          `Cliente: ${p.cliente_nome}\n` +
          `Email: ${p.cliente_email}\n` +
          `Telefone: ${p.cliente_telefone || '-'}\n\n` +
          `Endereço:\n${p.endereco.endereco}, ${p.endereco.numero}\n` +
          `${p.endereco.cidade} - ${p.endereco.estado}\n` +
          `CEP: ${p.endereco.cep}\n\n` +
          `Itens:\n${itensHTML}\n\n` +
          `Subtotal: R$ ${parseFloat(p.subtotal).toFixed(2)}\n` +
          `Frete: R$ ${parseFloat(p.frete).toFixed(2)}\n` +
          `Total: R$ ${parseFloat(p.total).toFixed(2)}\n\n` +
          `Pagamento: ${p.forma_pagamento}\n` +
          `Status: ${p.status}`
        );
      }
    } catch (error) {
      alert('Erro ao buscar detalhes do pedido');
    }
  };
});

// CSS
if (!document.getElementById('admin-animations')) {
  const styleEl = document.createElement('style');
  styleEl.id = 'admin-animations';
  styleEl.textContent = `
    @keyframes adminSlideIn {
      from { transform: translateX(400px); opacity: 0; }
      to { transform: translateX(0); opacity: 1; }
    }
    @keyframes adminSlideOut {
      from { transform: translateX(0); opacity: 1; }
      to { transform: translateX(400px); opacity: 0; }
    }
  `;
  document.head.appendChild(styleEl);
}