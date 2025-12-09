/**
 * auth.js - 100% BANCO DE DADOS (ZERO localStorage)
 * Apenas cookies para sessão
 * @version 7.0.0 FINAL
 */

class AuthSystem {
  constructor() {
    this.API_BASE = window.API_BASE || (window.location.origin + '/Novamoda/api');
    this.ADMIN_EMAILS = ['admin@novamoda.com', 'nicollastheodoro97@gmail.com'];
    this.init();
  }

  // COOKIES (ÚNICA FORMA DE ARMAZENAMENTO)
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

  // VALIDAÇÕES
  validateEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }

  validatePassword(password) {
    if (password.length < 6) {
      return { valid: false, message: 'Senha deve ter no mínimo 6 caracteres' };
    }
    return { valid: true };
  }

  isAdmin(email) {
    return this.ADMIN_EMAILS.includes(email?.toLowerCase());
  }

  // CADASTRO
  async signup(name, email, password, passwordConfirm) {
    name = name.trim();
    email = email.trim().toLowerCase();

    if (!name || name.length < 3) {
      return { success: false, message: 'Nome deve ter no mínimo 3 caracteres' };
    }

    if (!this.validateEmail(email)) {
      return { success: false, message: 'Email inválido' };
    }

    const passValidation = this.validatePassword(password);
    if (!passValidation.valid) {
      return { success: false, message: passValidation.message };
    }

    if (password !== passwordConfirm) {
      return { success: false, message: 'As senhas não conferem' };
    }

    try {
      const response = await fetch(`${this.API_BASE}/auth/register.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nome: name, email: email, password: password })
      });

      const data = await response.json();

      if (data.success) {
        this.setSession(data.user, data.token);
        
        if (window.storage) {
          window.storage.user = data.user;
          await window.storage.loadCartFromServer();
        }
        
        return { success: true, user: data.user };
      } else {
        return { success: false, message: data.message || 'Erro ao criar conta' };
      }
    } catch (error) {
      console.error('Erro no signup:', error);
      return { success: false, message: 'Erro de conexão com o servidor' };
    }
  }

  // LOGIN
  async login(email, password) {
    email = email.trim().toLowerCase();

    if (!this.validateEmail(email) || !password) {
      return { success: false, message: 'Email ou senha inválidos' };
    }

    try {
      const response = await fetch(`${this.API_BASE}/auth/login.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });

      const data = await response.json();

      if (data.success) {
        this.setSession(data.user, data.token);
        
        if (window.storage) {
          window.storage.user = data.user;
          await window.storage.loadCartFromServer();
        }
        
        return { success: true, user: data.user };
      } else {
        return { success: false, message: data.message || 'Credenciais incorretas' };
      }
    } catch (error) {
      console.error('Erro no login:', error);
      return { success: false, message: 'Erro de conexão' };
    }
  }

  // SESSÃO (APENAS COOKIES)
  getSession() {
    try {
      const userCookie = this.getCookie('novamoda_user');
      return userCookie ? JSON.parse(userCookie) : null;
    } catch {
      return null;
    }
  }

  setSession(user, token) {
    const sessionData = {
      id: user.id,
      name: user.nome || user.name,
      email: user.email,
      isAdmin: user.isAdmin || this.isAdmin(user.email),
      loginAt: new Date().toISOString()
    };
    
    this.setCookie('novamoda_user', JSON.stringify(sessionData));
    if (token) this.setCookie('novamoda_token', token);
    this.updateUI();
  }

  clearSession() {
    this.deleteCookie('novamoda_user');
    this.deleteCookie('novamoda_token');
    this.updateUI();
  }

  isLoggedIn() {
    return this.getSession() !== null;
  }

  // LOGOUT
  logout() {
    if (window.storage) {
      window.storage.logout();
    } else {
      this.clearSession();
      window.location.href = 'index.html';
    }
  }

  // PROTEÇÃO
  requireAuth(redirectToLogin = true) {
    if (!this.isLoggedIn()) {
      if (redirectToLogin) {
        this.showToast('⚠️ Faça login para continuar', 'info');
        setTimeout(() => {
          const currentPage = window.location.pathname.split('/').pop();
          window.location.href = `login.html?next=${currentPage}`;
        }, 1500);
      }
      return false;
    }
    return true;
  }

  requireAdmin(redirectToHome = true) {
    const session = this.getSession();
    if (!session || !session.isAdmin) {
      if (redirectToHome) {
        this.showToast('❌ Acesso negado', 'error');
        setTimeout(() => window.location.href = 'index.html', 1500);
      }
      return false;
    }
    return true;
  }

  updateUI() {
    console.log('📌 UI gerenciada por storage.js');
  }

  // FORMULÁRIOS
  handleSignupForm(formElement) {
    if (!formElement) return;

    formElement.addEventListener('submit', async (e) => {
      e.preventDefault();

      const name = formElement.querySelector('[name="name"]')?.value || '';
      const email = formElement.querySelector('[name="email"]')?.value || '';
      const password = formElement.querySelector('[name="password"]')?.value || '';
      const passwordConfirm = formElement.querySelector('[name="passwordConfirm"]')?.value || '';

      const result = await this.signup(name, email, password, passwordConfirm);

      if (result.success) {
        this.showToast('✓ Conta criada com sucesso!', 'success');
        setTimeout(() => window.location.href = 'index.html', 1000);
      } else {
        this.showToast(result.message, 'error');
      }
    });
  }

  handleLoginForm(formElement) {
    if (!formElement) return;

    formElement.addEventListener('submit', async (e) => {
      e.preventDefault();

      const email = formElement.querySelector('[name="email"]')?.value || '';
      const password = formElement.querySelector('[name="password"]')?.value || '';

      const result = await this.login(email, password);

      if (result.success) {
        this.showToast('✓ Login realizado!', 'success');
        setTimeout(() => {
          if (result.user && this.isAdmin(result.user.email)) {
            window.location.href = 'admin.html';
          } else {
            const urlParams = new URLSearchParams(window.location.search);
            const next = urlParams.get('next') || 'index.html';
            window.location.href = next;
          }
        }, 1000);
      } else {
        this.showToast(result.message, 'error');
      }
    });
  }

  // TOAST
  showToast(message, type = 'info') {
    const colors = { success: '#14d0d6', error: '#ff3b30', info: '#0ea5e9' };
    const toast = document.createElement('div');
    toast.textContent = message;
    toast.style.cssText = `position:fixed;bottom:30px;right:30px;background:${colors[type]};color:${type === 'error' ? '#fff' : '#000'};padding:16px 24px;border-radius:8px;font-weight:600;box-shadow:0 8px 20px rgba(0,0,0,0.3);z-index:9999;animation:authSlideIn 0.3s ease;`;
    document.body.appendChild(toast);
    setTimeout(() => {
      toast.style.animation = 'authSlideOut 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, 3000);
  }

  // INIT
  init() {
    const signupForm = document.querySelector('#signupForm, form[name="signup"]');
    const loginForm = document.querySelector('#loginForm, form[name="login"]');

    if (signupForm) this.handleSignupForm(signupForm);
    if (loginForm) this.handleLoginForm(loginForm);

    this.updateUI();

    window.NovamodaAuth = {
      requireAuth: (redirect) => this.requireAuth(redirect),
      requireAdmin: (redirect) => this.requireAdmin(redirect),
      getSession: () => this.getSession(),
      isLoggedIn: () => this.isLoggedIn(),
      logout: () => this.logout(),
      isAdmin: (email) => this.isAdmin(email)
    };

    console.log('✅ Auth v7.0 - 100% Banco (ZERO localStorage)');
  }
}

// CSS
if (!document.getElementById('auth-animations')) {
  const styleEl = document.createElement('style');
  styleEl.id = 'auth-animations';
  styleEl.textContent = `@keyframes authSlideIn{from{transform:translateX(400px);opacity:0}to{transform:translateX(0);opacity:1}}@keyframes authSlideOut{from{transform:translateX(0);opacity:1}to{transform:translateX(400px);opacity:0}}`;
  document.head.appendChild(styleEl);
}

const auth = new AuthSystem();
window.auth = auth;