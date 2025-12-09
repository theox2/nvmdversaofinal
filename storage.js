/**
 * storage.js - Sistema 100% COM BANCO DE DADOS
 * ZERO localStorage - TUDO na API PHP
 * 
 * @author NovaModa Team
 * @version 3.0.0
 */

const API_BASE = window.API_BASE || (window.location.origin + '/Novamoda/api');

class Storage {
  constructor() {
    this.user = null;
    this.cart = [];
    this.favorites = [];
    this.ADMIN_EMAILS = [
      'admin@novamoda.com',
      'nicollastheodoro97@gmail.com'
    ];
    this.init();
  }

  // ==========================================
  // INICIALIZAÇÃO
  // ==========================================
  async init() {
    console.log('🚀 Iniciando Storage 100% Banco de Dados');
    
    // Verificar sessão via cookie
    const userSession = this.getCookie('novamoda_user');
    if (userSession) {
      try {
        this.user = JSON.parse(userSession);
        console.log('✅ Usuário:', this.user.nome || this.user.name);
      } catch (e) {
        console.error('❌ Erro ao parsear usuário:', e);
        this.user = null;
        this.deleteCookie('novamoda_user');
      }
    }
    
    // Carregar dados do servidor
    if (this.user) {
      await Promise.all([
        this.loadCartFromServer(),
        this.loadFavoritesFromServer()
      ]);
    }
    
    // Atualizar UI
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.updateUI());
    } else {
      this.updateUI();
    }
    
    setTimeout(() => this.updateUI(), 500);
    
    console.log('✅ Storage 100% Banco inicializado');
  }

  // ==========================================
  // COOKIES (substituem localStorage)
  // ==========================================
  setCookie(name, value, days = 7) {
    const expires = new Date(Date.now() + days * 864e5).toUTCString();
    document.cookie = `${name}=${encodeURIComponent(value)}; expires=${expires}; path=/; SameSite=Lax`;
  }

  getCookie(name) {
    return document.cookie.split('; ').reduce((r, v) => {
      const parts = v.split('=');
      return parts[0] === name ? decodeURIComponent(parts[1]) : r;
    }, '');
  }

  deleteCookie(name) {
    this.setCookie(name, '', -1);
  }

  // ==========================================
  // AUTENTICAÇÃO
  // ==========================================
  async login(email, password) {
    try {
      const response = await fetch(`${API_BASE}/auth/login.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });

      const data = await response.json();

      if (data.success) {
        this.user = data.user;
        this.setCookie('novamoda_user', JSON.stringify(data.user));
        this.setCookie('novamoda_token', data.token);
        
        // Carregar dados do usuário
        await Promise.all([
          this.loadCartFromServer(),
          this.loadFavoritesFromServer()
        ]);
        
        this.updateUI();
        return { success: true, user: data.user };
      } else {
        return { success: false, message: data.message };
      }
    } catch (error) {
      console.error('Erro no login:', error);
      return { success: false, message: 'Erro de conexão' };
    }
  }

  async register(userData) {
    try {
      const response = await fetch(`${API_BASE}/auth/register.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(userData)
      });

      const data = await response.json();

      if (data.success) {
        this.user = data.user;
        this.setCookie('novamoda_user', JSON.stringify(data.user));
        this.setCookie('novamoda_token', data.token);
        this.updateUI();
        return { success: true, user: data.user };
      } else {
        return { success: false, message: data.message };
      }
    } catch (error) {
      console.error('Erro no cadastro:', error);
      return { success: false, message: 'Erro de conexão' };
    }
  }

  logout() {
    this.user = null;
    this.cart = [];
    this.favorites = [];
    this.deleteCookie('novamoda_user');
    this.deleteCookie('novamoda_token');
    this.updateUI();
    window.location.href = 'index.html';
  }

  getUser() {
    return this.user;
  }

  isLoggedIn() {
    return this.user !== null;
  }

  isAdmin(email) {
    if (!email && this.user) {
      email = this.user.email;
    }
    return this.ADMIN_EMAILS.includes(email?.toLowerCase());
  }

  // ==========================================
  // CARRINHO - 100% BANCO DE DADOS
  // ==========================================
  async loadCartFromServer() {
    if (!this.user) {
      this.cart = [];
      this.updateCartCount();
      return;
    }

    try {
      const response = await fetch(`${API_BASE}/carrinho/listar.php?usuario_id=${this.user.id}`);
      const data = await response.json();

      if (data.success && data.data?.itens) {
        this.cart = data.data.itens.map(item => ({
          id: item.produto_id,
          name: item.produto_nome || item.nome_produto,
          price: parseFloat(item.preco_unitario),
          img: item.imagem_principal || 'https://via.placeholder.com/400',
          qty: item.quantidade,
          size: item.tamanho,
          color: item.cor
        }));
      } else {
        this.cart = [];
      }
      
      this.updateCartCount();
    } catch (error) {
      console.error('❌ Erro ao carregar carrinho:', error);
      this.cart = [];
      this.updateCartCount();
    }
  }

  async addToCart(product, qty = 1) {
    if (!this.user) {
      this.showToast('Faça login para adicionar ao carrinho', 'info');
      setTimeout(() => window.location.href = 'login.html', 1500);
      return false;
    }

    try {
      const response = await fetch(`${API_BASE}/carrinho/adicionar.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          usuario_id: this.user.id,
          produto_id: product.id,
          quantidade: qty,
          tamanho: product.size || null,
          cor: product.color || null
        })
      });

      const data = await response.json();

      if (data.success) {
        await this.loadCartFromServer();
        this.showToast(`✓ ${product.name} adicionado!`, 'success');
        return true;
      } else {
        this.showToast(data.message, 'error');
        return false;
      }
    } catch (error) {
      console.error('Erro ao adicionar ao carrinho:', error);
      this.showToast('Erro ao adicionar produto', 'error');
      return false;
    }
  }

  async updateCartQty(productId, delta) {
    const item = this.cart.find(i => i.id === productId);
    if (!item) return false;

    const newQty = item.qty + delta;
    if (newQty < 1) {
      return this.removeFromCart(productId);
    }

    try {
      const response = await fetch(`${API_BASE}/carrinho/atualizar.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          usuario_id: this.user.id,
          produto_id: productId,
          quantidade: newQty
        })
      });

      const data = await response.json();

      if (data.success) {
        await this.loadCartFromServer();
        return true;
      }
      return false;
    } catch (error) {
      console.error('Erro ao atualizar quantidade:', error);
      return false;
    }
  }

  async removeFromCart(productId) {
    try {
      const response = await fetch(`${API_BASE}/carrinho/remover.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          usuario_id: this.user.id,
          produto_id: productId
        })
      });

      const data = await response.json();

      if (data.success) {
        await this.loadCartFromServer();
        return true;
      }
      return false;
    } catch (error) {
      console.error('Erro ao remover do carrinho:', error);
      return false;
    }
  }

  async clearCart() {
    if (!this.user) return false;

    try {
      const response = await fetch(`${API_BASE}/carrinho/limpar.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          usuario_id: this.user.id
        })
      });

      const data = await response.json();

      if (data.success) {
        this.cart = [];
        this.updateCartCount();
        return true;
      }
      return false;
    } catch (error) {
      console.error('Erro ao limpar carrinho:', error);
      return false;
    }
  }

  getCart() {
    return this.cart;
  }

  getCartTotal() {
    return this.cart.reduce((sum, item) => sum + (item.price * item.qty), 0);
  }

  updateCartCount() {
    const count = this.cart.reduce((sum, item) => sum + item.qty, 0);
    document.querySelectorAll('.cart-count').forEach(el => {
      el.textContent = count;
      el.style.display = count > 0 ? 'inline-block' : 'none';
    });
  }

  // ==========================================
  // FAVORITOS - 100% BANCO DE DADOS
  // ==========================================
  async loadFavoritesFromServer() {
    if (!this.user) {
      this.favorites = [];
      return;
    }

    try {
      const response = await fetch(`${API_BASE}/favoritos/listar.php?usuario_id=${this.user.id}`);
      const data = await response.json();

      if (data.success && data.data) {
        this.favorites = data.data.map(f => f.produto_id);
      } else {
        this.favorites = [];
      }
    } catch (error) {
      console.error('❌ Erro ao carregar favoritos:', error);
      this.favorites = [];
    }
  }

  async addToFavorites(productId) {
    if (!this.user) {
      this.showToast('Faça login para favoritar', 'info');
      setTimeout(() => window.location.href = 'login.html', 1500);
      return false;
    }

    try {
      const response = await fetch(`${API_BASE}/favoritos/adicionar.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          usuario_id: this.user.id,
          produto_id: productId
        })
      });

      const data = await response.json();

      if (data.success) {
        await this.loadFavoritesFromServer();
        this.showToast('✓ Adicionado aos favoritos!', 'success');
        return true;
      } else {
        this.showToast(data.message, 'error');
        return false;
      }
    } catch (error) {
      console.error('Erro ao favoritar:', error);
      return false;
    }
  }

  async removeFromFavorites(productId) {
    try {
      const response = await fetch(`${API_BASE}/favoritos/remover.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          usuario_id: this.user.id,
          produto_id: productId
        })
      });

      const data = await response.json();

      if (data.success) {
        await this.loadFavoritesFromServer();
        this.showToast('Removido dos favoritos', 'info');
        return true;
      }
      return false;
    } catch (error) {
      console.error('Erro ao remover favorito:', error);
      return false;
    }
  }

  isFavorite(productId) {
    return this.favorites.includes(productId);
  }

  getFavorites() {
    return this.favorites;
  }

  // ==========================================
  // PEDIDOS - 100% BANCO DE DADOS
  // ==========================================
  async getOrders() {
    if (!this.user) return [];

    try {
      const response = await fetch(`${API_BASE}/pedidos/listar.php?usuario_id=${this.user.id}`);
      const data = await response.json();

      if (data.success) {
        return data.data || [];
      }
      return [];
    } catch (error) {
      console.error('Erro ao buscar pedidos:', error);
      return [];
    }
  }

  async saveOrder(orderData) {
    if (!this.user) {
      this.showToast('Faça login para finalizar a compra', 'error');
      return null;
    }

    try {
      const response = await fetch(`${API_BASE}/pedidos/criar.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          usuario_id: this.user.id,
          endereco: {
            cep: orderData.cep,
            estado: orderData.state,
            cidade: orderData.city,
            bairro: orderData.neighborhood,
            endereco: orderData.address,
            numero: orderData.number,
            complemento: orderData.complement
          },
          forma_pagamento: orderData.payment,
          itens: this.cart.map(item => ({
            produto_id: item.id,
            nome: item.name,
            quantidade: item.qty,
            tamanho: item.size,
            cor: item.color,
            preco: item.price
          })),
          subtotal: this.getCartTotal(),
          desconto: 0,
          frete: 0,
          total: this.getCartTotal(),
          observacoes: null
        })
      });

      const data = await response.json();

      if (data.success) {
        await this.clearCart();
        return data.pedido;
      } else {
        this.showToast(data.message, 'error');
        return null;
      }
    } catch (error) {
      console.error('Erro ao criar pedido:', error);
      this.showToast('Erro ao processar pedido', 'error');
      return null;
    }
  }

  // ==========================================
  // UI
  // ==========================================
  updateUI() {
    // Remove elementos antigos
    document.querySelectorAll('.novamoda-user-area').forEach(el => el.remove());

    const userArea = document.createElement('div');
    userArea.className = 'novamoda-user-area';
    userArea.style.cssText = 'display:flex;align-items:center;gap:10px;';

    if (this.user) {
      const firstName = (this.user.name || this.user.nome || 'Usuário').split(' ')[0];
      const isUserAdmin = this.isAdmin(this.user.email);
      
      userArea.innerHTML = `
        <div style="display:flex;align-items:center;gap:12px;background:#111;padding:8px 12px;border-radius:8px;border:1px solid #222;">
          <div style="width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#14d0d6,#0ea5e9);display:flex;align-items:center;justify-content:center;font-weight:700;color:#000;font-size:14px;">
            ${firstName[0].toUpperCase()}
          </div>
          <div>
            <div style="color:#fff;font-size:13px;font-weight:600;">${this.escapeHtml(firstName)}</div>
            <div style="font-size:11px;color:#888;">${isUserAdmin ? '👑 Admin' : 'Cliente'}</div>
          </div>
        </div>
        ${isUserAdmin ? '<a href="admin.html" class="btn" style="padding:8px 12px;font-size:13px;margin-left:8px;background:#14d0d6;color:#000;border-radius:6px;text-decoration:none;">📊 Admin</a>' : ''}
        <button id="storage-logout-btn" class="btn" style="background:#222;color:#aaa;padding:8px 12px;font-size:13px;border:none;border-radius:6px;cursor:pointer;font-weight:600;">Sair</button>
      `;
    } else {
      userArea.innerHTML = '<a href="login.html" class="btn entrar-btn">Entrar</a>';
    }

    // Inserir no header
    const rightArea = document.querySelector('.right-area');
    const entrarBtn = document.querySelector('.entrar-btn');
    
    if (entrarBtn) {
      entrarBtn.replaceWith(userArea);
    } else if (rightArea) {
      const icons = rightArea.querySelector('.icons');
      if (icons) {
        rightArea.insertBefore(userArea, icons);
      } else {
        rightArea.appendChild(userArea);
      }
    }

    // Adicionar listener ao botão de logout
    const logoutBtn = document.getElementById('storage-logout-btn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', () => this.logout());
    }
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  // ==========================================
  // TOAST
  // ==========================================
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
      animation: storageSlideIn 0.3s ease;
      font-family: Inter, Arial, sans-serif;
    `;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
      toast.style.animation = 'storageSlideOut 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, 3000);
  }
}

// Inicializar
const storage = new Storage();
window.storage = storage;

// CSS
if (!document.getElementById('storage-animations')) {
  const styleEl = document.createElement('style');
  styleEl.id = 'storage-animations';
  styleEl.textContent = `
    @keyframes storageSlideIn {
      from { transform: translateX(400px); opacity: 0; }
      to { transform: translateX(0); opacity: 1; }
    }
    @keyframes storageSlideOut {
      from { transform: translateX(0); opacity: 1; }
      to { transform: translateX(400px); opacity: 0; }
    }
  `;
  document.head.appendChild(styleEl);
}

console.log('✅ Storage v3.0.0 carregado - 100% Banco de Dados');