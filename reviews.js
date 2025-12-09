/**
 * admin.js - Painel Administrativo (v3.0)
 * Dashboard, Estatísticas, Gestão de Pedidos
 */

class AdminPanel {
  constructor() {
    this.checkAccess();
    this.init();
  }

  // ==========================================
  // PROTEÇÃO DE ACESSO
  // ==========================================
  
  checkAccess() {
    if (!window.NovamodaAuth?.requireAdmin) {
      console.error('Auth system not loaded');
      return;
    }
    
    NovamodaAuth.requireAdmin(true);
  }

  // ==========================================
  // ESTATÍSTICAS DO DASHBOARD
  // ==========================================
  
  updateDashboardStats() {
    const orders = storage.getOrders();
    const products = storage.getProducts();
    
    // Vendas de hoje
    const today = new Date().toDateString();
    const todayOrders = orders.filter(o => 
      new Date(o.date).toDateString() === today
    );
    const todaySales = todayOrders.reduce((sum, o) => sum + (o.total || 0), 0);
    
    // Atualizar elementos
    this.updateElement('vendasHoje', `R$ ${this.formatMoney(todaySales)}`);
    this.updateElement('totalPedidos', orders.length);
    
    // Produtos com estoque baixo
    const lowStock = products.filter(p => p.stock > 0 && p.stock <= 10).length;
    this.updateElement('lowStockCount', lowStock);
    
    // Novos clientes (últimos 30 dias)
    const thirtyDaysAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);
    const users = JSON.parse(localStorage.getItem('novamoda_users') || '[]');
    const newCustomers = users.filter(u => 
      new Date(u.createdAt || 0).getTime() > thirtyDaysAgo
    ).length;
    
    this.updateElement('newCustomers', newCustomers);
    
    // Taxa de conversão (simulada)
    const conversionRate = orders.length > 0 ? 
      ((orders.length / (orders.length * 15)) * 100).toFixed(1) : 
      '0.0';
    this.updateElement('conversionRate', conversionRate + '%');
  }

  // ==========================================
  // GRÁFICO DE VENDAS
  // ==========================================
  
  renderSalesChart() {
    const chartEl = document.getElementById('salesChart');
    if (!chartEl) return;
    
    const orders = storage.getOrders();
    
    // Vendas dos últimos 7 dias
    const salesByDay = this.getSalesByDay(orders, 7);
    const maxValue = Math.max(...Object.values(salesByDay), 1);
    
    chartEl.innerHTML = Object.entries(salesByDay).map(([day, value]) => {
      const height = (value / maxValue) * 100;
      return `
        <div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:8px;">
          <div style="font-size:12px;color:#14d0d6;font-weight:700;">
            R$ ${this.formatMoney(value)}
          </div>
          <div style="width:100%;height:200px;display:flex;align-items:flex-end;">
            <div style="width:100%;background:linear-gradient(180deg,#14d0d6,#0ea5e9);
                        height:${height}%;border-radius:4px 4px 0 0;transition:all .3s;
                        cursor:pointer;position:relative;" 
                 title="${day}: R$ ${this.formatMoney(value)}"
                 onmouseover="this.style.opacity='0.8'" 
                 onmouseout="this.style.opacity='1'">
            </div>
          </div>
          <div style="font-size:11px;color:#888;">${day}</div>
        </div>
      `;
    }).join('');
  }

  getSalesByDay(orders, days) {
    const salesByDay = {};
    const today = new Date();
    
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = date.toLocaleDateString('pt-BR', { 
        day: '2-digit', 
        month: '2-digit' 
      });
      salesByDay[dateStr] = 0;
    }
    
    orders.forEach(order => {
      const orderDate = new Date(order.date).toLocaleDateString('pt-BR', { 
        day: '2-digit', 
        month: '2-digit' 
      });
      if (salesByDay.hasOwnProperty(orderDate)) {
        salesByDay[orderDate] += order.total || 0;
      }
    });
    
    return salesByDay;
  }

  // ==========================================
  // PEDIDOS RECENTES
  // ==========================================
  
  loadRecentOrders() {
    const tbody = document.querySelector('#ordersTable tbody');
    if (!tbody) return;
    
    const orders = storage.getOrders().slice(0, 10);
    
    if (orders.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;color:#888;padding:40px;">Nenhum pedido ainda</td></tr>';
      return;
    }
    
    tbody.innerHTML = orders.map(order => {
      const date = new Date(order.date).toLocaleDateString('pt-BR');
      const itemCount = order.items.reduce((sum, item) => sum + (item.qty || 1), 0);
      const statusInfo = this.getStatusInfo(order.status);
      
      return `
        <tr>
          <td><strong>${order.number}</strong></td>
          <td>${this.escapeHtml(order.customer.fullName)}</td>
          <td>${itemCount} ${itemCount === 1 ? 'item' : 'itens'}</td>
          <td><strong>R$ ${this.formatMoney(order.total)}</strong></td>
          <td><span class="status status-${order.status}">${statusInfo.label}</span></td>
          <td>${date}</td>
          <td>
            <button class="btn" style="padding:6px 12px;font-size:12px;" 
                    onclick="adminPanel.viewOrder('${order.number}')">
              Ver
            </button>
            <button class="btn" style="padding:6px 12px;font-size:12px;background:#222;margin-left:4px;" 
                    onclick="adminPanel.changeOrderStatus('${order.number}')">
              Alterar Status
            </button>
          </td>
        </tr>
      `;
    }).join('');
  }

  getStatusInfo(status) {
    const statuses = {
      pending: { label: 'Pendente', color: '#fbbf24' },
      processing: { label: 'Processando', color: '#3b82f6' },
      shipped: { label: 'Enviado', color: '#8b5cf6' },
      delivered: { label: 'Entregue', color: '#4ade80' },
      cancelled: { label: 'Cancelado', color: '#ff3b30' }
    };
    return statuses[status] || statuses.pending;
  }

  // ==========================================
  // AÇÕES RÁPIDAS
  // ==========================================
  
  viewOrder(orderNumber) {
    const orders = storage.getOrders();
    const order = orders.find(o => o.number === orderNumber);
    
    if (!order) {
      storage.showToast('Pedido não encontrado', 'error');
      return;
    }

    const itemsList = order.items.map(item => 
      `- ${item.qty}x ${item.name} (R$ ${this.formatMoney(item.price * item.qty)})`
    ).join('\n');

    alert(
      `📦 PEDIDO ${order.number}\n\n` +
      `Cliente: ${order.customer.fullName}\n` +
      `Email: ${order.customer.email}\n` +
      `Telefone: ${order.customer.phone}\n\n` +
      `Endereço:\n${order.address.address}, ${order.address.number}\n` +
      `${order.address.city} - ${order.address.state}\n` +
      `CEP: ${order.address.cep}\n\n` +
      `Itens:\n${itemsList}\n\n` +
      `Total: R$ ${this.formatMoney(order.total)}\n` +
      `Pagamento: ${this.getPaymentLabel(order.payment)}\n` +
      `Status: ${this.getStatusInfo(order.status).label}\n` +
      `Data: ${new Date(order.date).toLocaleString('pt-BR')}`
    );
  }

  changeOrderStatus(orderNumber) {
    const orders = storage.getOrders();
    const orderIndex = orders.findIndex(o => o.number === orderNumber);
    
    if (orderIndex === -1) {
      storage.showToast('Pedido não encontrado', 'error');
      return;
    }

    const newStatus = prompt(
      'Novo status:\n' +
      '1 - Pendente\n' +
      '2 - Processando\n' +
      '3 - Enviado\n' +
      '4 - Entregue\n' +
      '5 - Cancelado'
    );

    const statusMap = {
      '1': 'pending',
      '2': 'processing',
      '3': 'shipped',
      '4': 'delivered',
      '5': 'cancelled'
    };

    if (statusMap[newStatus]) {
      orders[orderIndex].status = statusMap[newStatus];
      localStorage.setItem('novamoda_orders', JSON.stringify(orders));
      storage.showToast('✓ Status atualizado!', 'success');
      this.loadRecentOrders();
    }
  }

  getPaymentLabel(method) {
    const labels = {
      pix: 'PIX',
      credit: 'Cartão de Crédito',
      boleto: 'Boleto Bancário'
    };
    return labels[method] || method;
  }

  exportReport() {
    const orders = storage.getOrders();
    
    if (orders.length === 0) {
      storage.showToast('Não há pedidos para exportar', 'error');
      return;
    }
    
    let csv = 'Pedido,Cliente,Email,Data,Total,Status,Pagamento\n';
    
    orders.forEach(o => {
      const date = new Date(o.date).toLocaleDateString('pt-BR');
      const status = this.getStatusInfo(o.status).label;
      csv += `"${o.number}","${o.customer.fullName}","${o.customer.email}","${date}","${o.total.toFixed(2)}","${status}","${this.getPaymentLabel(o.payment)}"\n`;
    });
    
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `pedidos-novamoda-${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    
    storage.showToast('✓ Relatório exportado!', 'success');
  }

  createCoupon() {
    const code = prompt('Digite o código do cupom (ex: NOVA10):');
    if (!code) return;
    
    const discount = parseFloat(prompt('Digite o desconto (%):', '10'));
    if (!discount || discount <= 0 || discount > 100) {
      storage.showToast('Desconto inválido', 'error');
      return;
    }
    
    const coupons = storage.getCoupons();
    coupons[code.toUpperCase()] = {
      code: code.toUpperCase(),
      discount: discount / 100,
      type: 'percentual',
      created: new Date().toISOString()
    };
    
    localStorage.setItem('novamoda_coupons', JSON.stringify(coupons));
    storage.showToast(`✓ Cupom ${code.toUpperCase()} criado com ${discount}% de desconto!`, 'success');
  }

  // ==========================================
  // SIMULAÇÃO DE DADOS EM TEMPO REAL
  // ==========================================
  
  simulateRealTimeData() {
    setInterval(() => {
      const vendasEl = document.getElementById('vendasHoje');
      if (!vendasEl) return;
      
      const current = parseFloat(vendasEl.textContent.replace(/[^\d,]/g, '').replace(',', '.'));
      const increase = Math.floor(Math.random() * 50) + 10;
      const newValue = current + increase;
      
      vendasEl.textContent = `R$ ${this.formatMoney(newValue)}`;
    }, 8000);
  }

  // ==========================================
  // HELPERS
  // ==========================================
  
  formatMoney(value) {
    return value.toFixed(2).replace('.', ',');
  }

  updateElement(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
  }

  escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  // ==========================================
  // INICIALIZAÇÃO
  // ==========================================
  
  init() {
    if (window.location.pathname.includes('admin.html')) {
      this.updateDashboardStats();
      this.renderSalesChart();
      this.loadRecentOrders();
      this.simulateRealTimeData();
    }
  }
}

// Instância global
const adminPanel = new AdminPanel();

// Expor funções globalmente para botões HTML
window.adminPanel = adminPanel;
window.exportReport = () => adminPanel.exportReport();
window.createCoupon = () => adminPanel.createCoupon();