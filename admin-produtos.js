/**
 * admin-produtos.js - Gerenciamento de Produtos (COM API PHP)
 * Para usar na página admin-produtos.html
 */

class AdminProdutos {
  constructor() {
    this.API_BASE = '/api/admin/produtos'; // Ajuste se necessário
    this.API_PRODUTOS = '/api/produtos/listar.php';
    this.currentProductId = null;
    this.init();
  }

  // ==========================================
  // CARREGAR PRODUTOS DO BANCO
  // ==========================================
  
  async loadProducts() {
    try {
      const response = await fetch(this.API_PRODUTOS);
      const data = await response.json();
      
      if (data.success) {
        this.renderProducts(data.data);
      } else {
        this.showToast('Erro ao carregar produtos', 'error');
      }
    } catch (error) {
      console.error('Erro ao carregar produtos:', error);
      this.showToast('Erro de conexão', 'error');
    }
  }

  // ==========================================
  // RENDERIZAR PRODUTOS
  // ==========================================
  
  renderProducts(products) {
    const grid = document.getElementById('productsGrid');
    if (!grid) return;

    if (products.length === 0) {
      grid.innerHTML = `
        <div style="grid-column:1/-1;text-align:center;padding:60px;color:#888;">
          <div style="font-size:4rem;margin-bottom:20px;">📦</div>
          <h3>Nenhum produto cadastrado</h3>
          <p>Clique em "Novo Produto" para adicionar</p>
        </div>
      `;
      return;
    }

    grid.innerHTML = products.map(p => {
      const stockStatus = this.getStockStatus(p.estoque);
      
      return `
        <div class="product-card">
          <img src="${p.imagem_principal || p.images?.[0] || 'https://via.placeholder.com/400'}" 
               alt="${p.nome}" 
               class="product-image">
          <div class="product-info">
            <div class="product-name">${this.escapeHtml(p.nome)}</div>
            <div class="product-price">
              R$ ${this.formatMoney(p.preco)}
              ${p.preco_antigo ? `<span style="font-size:14px;color:#666;text-decoration:line-through;margin-left:8px;">R$ ${this.formatMoney(p.preco_antigo)}</span>` : ''}
            </div>
            <div class="product-meta">
              <span>Categoria: ${p.categoria_nome || 'Sem categoria'}</span>
            </div>
            <span class="product-stock ${stockStatus.class}">${stockStatus.label}: ${p.estoque}</span>
            <div class="product-actions" style="margin-top:15px;">
              <button class="btn btn-primary" onclick="adminProdutos.editProduct(${p.id})">Editar</button>
              <button class="btn btn-danger" onclick="adminProdutos.deleteProduct(${p.id})">Excluir</button>
            </div>
          </div>
        </div>
      `;
    }).join('');
  }

  getStockStatus(estoque) {
    if (estoque === 0) return { class: 'stock-out', label: 'Sem Estoque' };
    if (estoque <= 10) return { class: 'stock-low', label: 'Estoque Baixo' };
    return { class: 'stock-high', label: 'Em Estoque' };
  }

  // ==========================================
  // CRIAR PRODUTO
  // ==========================================
  
  async createProduct(formData) {
    try {
      const response = await fetch(`${this.API_BASE}/criar.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (data.success) {
        this.showToast('✓ Produto criado com sucesso!', 'success');
        this.closeModal();
        this.loadProducts(); // Recarregar lista
      } else {
        this.showToast(data.message || 'Erro ao criar produto', 'error');
      }
    } catch (error) {
      console.error('Erro ao criar produto:', error);
      this.showToast('Erro de conexão', 'error');
    }
  }

  // ==========================================
  // ATUALIZAR PRODUTO
  // ==========================================
  
  async updateProduct(id, formData) {
    try {
      const response = await fetch(`${this.API_BASE}/atualizar.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id, ...formData })
      });

      const data = await response.json();

      if (data.success) {
        this.showToast('✓ Produto atualizado!', 'success');
        this.closeModal();
        this.loadProducts();
      } else {
        this.showToast(data.message || 'Erro ao atualizar', 'error');
      }
    } catch (error) {
      console.error('Erro ao atualizar produto:', error);
      this.showToast('Erro de conexão', 'error');
    }
  }

  // ==========================================
  // DELETAR PRODUTO
  // ==========================================
  
  async deleteProduct(id) {
    if (!confirm('⚠️ Tem certeza que deseja deletar este produto?')) return;

    try {
      const response = await fetch(`${this.API_BASE}/deletar.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id })
      });

      const data = await response.json();

      if (data.success) {
        this.showToast('✓ Produto deletado!', 'success');
        this.loadProducts();
      } else {
        this.showToast(data.message || 'Erro ao deletar', 'error');
      }
    } catch (error) {
      console.error('Erro ao deletar produto:', error);
      this.showToast('Erro de conexão', 'error');
    }
  }

  // ==========================================
  // MODAL
  // ==========================================
  
  openAddModal() {
    this.currentProductId = null;
    document.getElementById('modalTitle').textContent = 'Novo Produto';
    document.getElementById('productForm').reset();
    document.getElementById('productModal').classList.add('show');
  }

  async editProduct(id) {
    this.currentProductId = id;
    document.getElementById('modalTitle').textContent = 'Editar Produto';
    
    // Buscar dados do produto
    try {
      const response = await fetch(`/api/produtos/detalhes.php?id=${id}`);
      const data = await response.json();
      
      if (data.success) {
        const p = data.data;
        
        // Preencher formulário
        document.getElementById('productName').value = p.nome;
        document.getElementById('productPrice').value = p.preco;
        document.getElementById('productOldPrice').value = p.preco_antigo || '';
        document.getElementById('productCategory').value = p.categoria_id;
        document.getElementById('productStock').value = p.estoque;
        document.getElementById('productImage').value = p.imagem_principal;
        document.getElementById('productDescription').value = p.descricao || '';
        
        document.getElementById('productModal').classList.add('show');
      }
    } catch (error) {
      console.error('Erro ao buscar produto:', error);
      this.showToast('Erro ao carregar produto', 'error');
    }
  }

  closeModal() {
    document.getElementById('productModal').classList.remove('show');
    this.currentProductId = null;
  }

  // ==========================================
  // HANDLE FORM SUBMIT
  // ==========================================
  
  handleFormSubmit(e) {
    e.preventDefault();

    const formData = {
      nome: document.getElementById('productName').value.trim(),
      preco: parseFloat(document.getElementById('productPrice').value),
      preco_antigo: document.getElementById('productOldPrice').value ? parseFloat(document.getElementById('productOldPrice').value) : null,
      categoria_id: parseInt(document.getElementById('productCategory').value),
      estoque: parseInt(document.getElementById('productStock').value),
      imagem_principal: document.getElementById('productImage').value.trim(),
      descricao: document.getElementById('productDescription').value.trim()
    };

    // Validações
    if (!formData.nome || !formData.imagem_principal) {
      this.showToast('Preencha todos os campos obrigatórios', 'error');
      return;
    }

    if (this.currentProductId) {
      this.updateProduct(this.currentProductId, formData);
    } else {
      this.createProduct(formData);
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================
  
  formatMoney(value) {
    return parseFloat(value).toFixed(2).replace('.', ',');
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  showToast(message, type = 'info') {
    if (typeof storage !== 'undefined' && storage.showToast) {
      storage.showToast(message, type);
    } else {
      alert(message);
    }
  }

  // ==========================================
  // FILTROS
  // ==========================================
  
  setupFilters() {
    const searchInput = document.getElementById('searchProducts');
    const categoryFilter = document.getElementById('categoryFilter');
    const stockFilter = document.getElementById('stockFilter');

    if (searchInput) {
      searchInput.addEventListener('input', () => this.applyFilters());
    }
    if (categoryFilter) {
      categoryFilter.addEventListener('change', () => this.applyFilters());
    }
    if (stockFilter) {
      stockFilter.addEventListener('change', () => this.applyFilters());
    }
  }

  async applyFilters() {
    const search = document.getElementById('searchProducts')?.value || '';
    const category = document.getElementById('categoryFilter')?.value || '';
    
    let url = this.API_PRODUTOS;
    const params = [];
    
    if (search) params.push(`busca=${encodeURIComponent(search)}`);
    if (category) params.push(`categoria=${category}`);
    
    if (params.length > 0) {
      url += '?' + params.join('&');
    }

    try {
      const response = await fetch(url);
      const data = await response.json();
      
      if (data.success) {
        this.renderProducts(data.data);
      }
    } catch (error) {
      console.error('Erro ao filtrar:', error);
    }
  }

  // ==========================================
  // INICIALIZAÇÃO
  // ==========================================
  
  init() {
    // Carregar produtos
    this.loadProducts();

    // Setup form
    const form = document.getElementById('productForm');
    if (form) {
      form.addEventListener('submit', (e) => this.handleFormSubmit(e));
    }

    // Setup filtros
    this.setupFilters();

    // Expor método para abrir modal
    window.openAddModal = () => this.openAddModal();

    console.log('✅ Admin Produtos inicializado (com PHP API)');
  }
}

// Inicializar
const adminProdutos = new AdminProdutos();
window.adminProdutos = adminProdutos;