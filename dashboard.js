import { supabase, requireAuth } from './supabase.js';

let allUsers = [];
let barChartInstance = null;
let pieChartInstance = null;

document.addEventListener('DOMContentLoaded', async () => {
  await requireAuth();

  // Setup Logout
  document.getElementById('logout-btn').addEventListener('click', async () => {
    await supabase.auth.signOut();
    window.location.href = '/index.html';
  });

  // Setup Search
  document.getElementById('searchInput').addEventListener('input', (e) => {
    renderTable(e.target.value);
  });

  window.openEditUserModal = (userId) => {
    const user = allUsers.find(u => u.user_id === userId);
    if (!user) return;
    
    document.getElementById('editUserId').value = user.user_id;
    document.getElementById('editUserFullName').value = user.full_name || user.name || user.nombre || '';
    document.getElementById('editUserInstitution').value = user.institution || '';
    document.getElementById('editUserRole').value = user.role || 'student';
    
    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('userEditModal'));
    modal.show();
  };

  window.openUserDetailModal = async (userId, userName) => {
    document.getElementById('userDetailTitle').textContent = `Progreso Detallado: ${userName || 'Usuario'}`;
    const body = document.getElementById('userDetailBody');
    body.innerHTML = '<div class="text-center py-4"><div class="spinner-border text-primary" role="status"></div></div>';
    
    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('userDetailModal'));
    modal.show();

    try {
      // 1. Cursos
      const { data: courses } = await supabase.from('user_progress').select('enrolled_at, courses(title)').eq('user_id', userId);
      // 2. Evaluaciones
      const { data: quizzes } = await supabase.from('quiz_attempts').select('score, passed, attempt_date, quizzes(title)').eq('user_id', userId).order('attempt_date', { ascending: false });
      // 3. Medallas
      const { data: badges } = await supabase.from('user_badges').select('awarded_at, badges(name, description)').eq('user_id', userId);

      let html = `<h6 class="text-primary fw-bold mt-2"><i class="bi bi-book"></i> Cursos Matriculados</h6>`;
      if (!courses || courses.length === 0) html += `<p class="text-muted small">No está matriculado en ningún curso.</p>`;
      else {
        html += `<ul class="list-group list-group-flush mb-3 border rounded">`;
        courses.forEach(c => {
          const date = c.enrolled_at ? new Date(c.enrolled_at).toLocaleDateString() : 'N/A';
          html += `<li class="list-group-item d-flex justify-content-between align-items-center">
                    <span>${c.courses?.title || 'Curso Desconocido'}</span>
                    <span class="badge bg-light text-dark border">Matriculado: ${date}</span>
                   </li>`;
        });
        html += `</ul>`;
      }

      html += `<h6 class="text-primary fw-bold mt-3"><i class="bi bi-ui-checks"></i> Evaluaciones (Quizzes)</h6>`;
      if (!quizzes || quizzes.length === 0) html += `<p class="text-muted small">No ha intentado ninguna evaluación.</p>`;
      else {
        html += `<ul class="list-group list-group-flush mb-3 border rounded">`;
        quizzes.forEach(q => {
          const badgeClass = q.passed ? 'bg-success' : 'bg-danger';
          const icon = q.passed ? 'check-circle-fill' : 'x-circle-fill';
          html += `<li class="list-group-item d-flex justify-content-between align-items-center">
                    <span><i class="bi bi-${icon} text-${q.passed ? 'success' : 'danger'} me-2"></i>${q.quizzes?.title || 'Quiz Desconocido'}</span>
                    <span class="badge ${badgeClass} rounded-pill">${q.score}%</span>
                   </li>`;
        });
        html += `</ul>`;
      }

      html += `<h6 class="text-primary fw-bold mt-3"><i class="bi bi-award"></i> Medallas Obtenidas</h6>`;
      if (!badges || badges.length === 0) html += `<p class="text-muted small">Aún no tiene medallas.</p>`;
      else {
        html += `<div class="d-flex flex-wrap gap-2">`;
        badges.forEach(b => {
          html += `<span class="badge bg-warning text-dark border border-warning px-3 py-2 rounded-pill">
                     <i class="bi bi-trophy-fill me-1 text-danger"></i> ${b.badges?.name || 'Medalla'}
                   </span>`;
        });
        html += `</div>`;
      }

      body.innerHTML = html;
    } catch (err) {
      body.innerHTML = `<div class="alert alert-danger">Error cargando detalles: ${err.message}</div>`;
    }
  };

  document.getElementById('userEditForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('userEditSubmitBtn');
    btn.disabled = true;
    
    const target_user_id = document.getElementById('editUserId').value;
    const new_full_name = document.getElementById('editUserFullName').value;
    const new_institution = document.getElementById('editUserInstitution').value;
    const new_role = document.getElementById('editUserRole').value;

    const { error } = await supabase.rpc('admin_update_user', {
      target_user_id,
      new_full_name,
      new_institution,
      new_role
    });

    if (error) {
      alert('Error al actualizar el usuario. Recuerda que debes crear primero la función SQL admin_update_user en la base de datos.\nDetalles: ' + error.message);
    } else {
      bootstrap.Modal.getInstance(document.getElementById('userEditModal')).hide();
      await fetchAndRenderData();
    }
    
    btn.disabled = false;
  });

  window.openDeleteUserModal = (userId, userName) => {
    document.getElementById('deleteUserId').value = userId;
    document.getElementById('deleteUserName').textContent = userName || 'este usuario';
    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('userDeleteModal'));
    modal.show();
  };

  document.getElementById('userDeleteBtn').addEventListener('click', async (e) => {
    const btn = e.target;
    btn.disabled = true;
    
    const target_user_id = document.getElementById('deleteUserId').value;

    const { error } = await supabase.rpc('admin_delete_user', { target_user_id });

    if (error) {
      alert('Error al eliminar el usuario. Recuerda que debes crear primero la función SQL admin_delete_user en la base de datos.\\nDetalles: ' + error.message);
    } else {
      bootstrap.Modal.getInstance(document.getElementById('userDeleteModal')).hide();
      await fetchAndRenderData();
    }
    
    btn.disabled = false;
  });

  // Settings Logic
  document.getElementById('settingsBtn').addEventListener('click', async () => {
    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('settingsModal'));
    
    // Fetch current key
    const { data, error } = await supabase
      .from('app_settings')
      .select('setting_value')
      .eq('setting_key', 'gemini_api_key')
      .single();
      
    if (!error && data) {
      document.getElementById('geminiApiKey').value = data.setting_value;
    }
    
    modal.show();
  });

  document.getElementById('saveSettingsBtn').addEventListener('click', async (e) => {
    const btn = e.target;
    btn.disabled = true;
    
    const newKey = document.getElementById('geminiApiKey').value.trim();
    
    const { error } = await supabase
      .from('app_settings')
      .update({ setting_value: newKey })
      .eq('setting_key', 'gemini_api_key');
      
    if (error) {
      alert('Error al guardar la clave. Asegúrate de ejecutar el script SQL en Supabase.\\n' + error.message);
    } else {
      alert('¡Ajustes guardados correctamente!');
      bootstrap.Modal.getInstance(document.getElementById('settingsModal')).hide();
    }
    
    btn.disabled = false;
  });

  // Fetch users
  await fetchAndRenderData();
});

async function fetchAndRenderData() {
  const { data, error } = await supabase.rpc('get_all_users_progress');
  
  if (error) {
    console.error('Error fetching users:', error);
    document.getElementById('usersTableBody').innerHTML = `<tr><td colspan="8" class="text-danger text-center">Error cargando datos: ${error.message}</td></tr>`;
    return;
  }

  allUsers = data || [];
  
  // Render full table initially
  renderTable('');
  renderCharts();
}

function renderTable(searchQuery) {
  const tbody = document.getElementById('usersTableBody');
  tbody.innerHTML = '';

  const q = searchQuery.toLowerCase();
  
  let filtered = allUsers.filter(u => {
    const email = (u.email || '').toLowerCase();
    const name = (u.full_name || '').toLowerCase();
    const inst = (u.institution || '').toLowerCase();
    return email.includes(q) || name.includes(q) || inst.includes(q);
  });

  // Sort by XP descending
  filtered.sort((a, b) => (b.total_xp || 0) - (a.total_xp || 0));

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-center">No se encontraron usuarios.</td></tr>`;
    return;
  }

  filtered.forEach((user, index) => {
    const isStudent = user.role === 'student' || !user.role;
    
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${index + 1}</td>
      <td class="fw-bold">${user.full_name || 'N/A'}</td>
      <td>${user.email || 'N/A'}</td>
      <td>${user.institution || '<span class="text-muted">N/A</span>'}</td>
      <td><span class="badge ${isStudent ? 'bg-primary' : 'bg-warning'}">${user.role || 'student'}</span></td>
      <td class="fw-bold text-success">Lvl ${user.current_level || 1}</td>
      <td>${user.total_xp || 0} XP</td>
      <td class="d-print-none">
        <button class="btn btn-sm btn-outline-info me-1" onclick="openUserDetailModal('${user.user_id}', '${user.full_name || user.email || ''}')"><i class="bi bi-eye"></i> Detalle</button>
        <button class="btn btn-sm btn-outline-primary me-1" onclick="openEditUserModal('${user.user_id}')"><i class="bi bi-pencil"></i> Editar</button>
        <button class="btn btn-sm btn-outline-danger" onclick="openDeleteUserModal('${user.user_id}', '${user.full_name || user.email || ''}')"><i class="bi bi-trash"></i> Eliminar</button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

function renderCharts() {
  const students = allUsers.filter(u => u.role === 'student' || !u.role);
  
  // BAR CHART: Top 5 XP
  const top5 = [...students].sort((a, b) => (b.total_xp || 0) - (a.total_xp || 0)).slice(0, 5);
  const barCtx = document.getElementById('barChart').getContext('2d');
  
  if (barChartInstance) barChartInstance.destroy();
  
  barChartInstance = new Chart(barCtx, {
    type: 'bar',
    data: {
      labels: top5.map(u => (u.full_name || u.email || '').split('@')[0].split(' ')[0].substring(0, 8)),
      datasets: [{
        label: 'XP Total',
        data: top5.map(u => u.total_xp || 0),
        backgroundColor: '#0d6efd',
        borderRadius: 4
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: { beginAtZero: true }
      }
    }
  });

  // PIE CHART: Level Distribution
  const levelCounts = {};
  students.forEach(u => {
    const lvl = u.current_level || 1;
    levelCounts[lvl] = (levelCounts[lvl] || 0) + 1;
  });

  const pieCtx = document.getElementById('pieChart').getContext('2d');
  
  if (pieChartInstance) pieChartInstance.destroy();

  pieChartInstance = new Chart(pieCtx, {
    type: 'doughnut',
    data: {
      labels: Object.keys(levelCounts).map(l => `Nivel ${l}`),
      datasets: [{
        data: Object.values(levelCounts),
        backgroundColor: ['#0d6efd', '#198754', '#ffc107', '#dc3545', '#6f42c1', '#20c997']
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
    }
  });
}
