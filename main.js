import { supabase, checkSession } from './supabase.js';

import 'bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap/dist/js/bootstrap.bundle.min.js';

document.addEventListener('DOMContentLoaded', async () => {
  // If already logged in, redirect to dashboard
  const session = await checkSession();
  if (session) {
    window.location.href = '/dashboard.html';
  }

  const loginForm = document.getElementById('login-form');
  const errorMsg = document.getElementById('error-msg');
  const submitBtn = document.getElementById('submit-btn');

  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    errorMsg.classList.add('d-none');
    
    const email = document.getElementById('floatingInput').value;
    const password = document.getElementById('floatingPassword').value;

    submitBtn.disabled = true;
    submitBtn.innerText = 'Cargando...';

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      errorMsg.innerText = 'Credenciales inválidas o error de red: ' + error.message;
      errorMsg.classList.remove('d-none');
      submitBtn.disabled = false;
      submitBtn.innerText = 'Ingresar al Sistema';
    } else {
      // In a real app you might want to check the user's role here
      window.location.href = '/dashboard.html';
    }
  });
});
