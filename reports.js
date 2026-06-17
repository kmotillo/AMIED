const bootstrap = window.bootstrap;
import { supabase, requireAuth } from './supabase.js';

let reportData = [];
let institutions = new Set();

document.addEventListener('DOMContentLoaded', async () => {
  await requireAuth();

  // Setup Logout
  document.getElementById('logout-btn').addEventListener('click', async () => {
    await supabase.auth.signOut();
    window.location.href = '/index.html';
  });

  // Setup Filters
  document.getElementById('filterUser').addEventListener('input', renderReport);
  document.getElementById('filterInstitution').addEventListener('change', renderReport);
  document.getElementById('filterStatus').addEventListener('change', renderReport);
  document.getElementById('btnResetFilters').addEventListener('click', () => {
    document.getElementById('filterForm').reset();
    renderReport();
  });

  // Set print date
  document.getElementById('printDate').textContent = `Generado el: ${new Date().toLocaleString()}`;

  await fetchAndRenderData();
});

async function fetchAndRenderData() {
  try {
    // 1. Get all users
    const { data: usersData, error: usersError } = await supabase.rpc('get_all_users_progress');
    if (usersError) throw usersError;

    // 2. Get all courses and their lessons and quizzes to count total items per course
    const { data: coursesData, error: coursesError } = await supabase
      .from('courses')
      .select('id, title, modules(id, lessons(id), quizzes(id))');
    if (coursesError) throw coursesError;

    const courseItemsCount = {};
    const courseLessonsMap = {}; // courseId -> Set of lessonIds
    const courseQuizzesMap = {}; // courseId -> Set of moduleIds that have quizzes
    
    coursesData.forEach(course => {
      let total = 0;
      let lessonSet = new Set();
      let quizSet = new Set();
      if (course.modules) {
        course.modules.forEach(m => {
          if (m.lessons) {
            total += m.lessons.length;
            m.lessons.forEach(l => lessonSet.add(l.id));
          }
          if (m.quizzes && m.quizzes.length > 0) {
            total += 1;
            quizSet.add(m.id);
          }
        });
      }
      courseItemsCount[course.id] = total;
      courseLessonsMap[course.id] = lessonSet;
      courseQuizzesMap[course.id] = quizSet;
    });

    // 3. Get all user_progress
    const { data: progressData, error: progressError } = await supabase
      .from('user_progress')
      .select('user_id, course_id, enrolled_at');
    if (progressError) throw progressError;

    // 4. Get all lesson completions
    const { data: completionsData, error: completionsError } = await supabase
      .from('lesson_completion')
      .select('user_id, lesson_id');
    if (completionsError) throw completionsError;

    // Map completions by user_id
    const userCompletions = {};
    completionsData.forEach(c => {
      if (!userCompletions[c.user_id]) userCompletions[c.user_id] = new Set();
      userCompletions[c.user_id].add(c.lesson_id);
    });

    // 5. Get all passed quizzes
    const { data: quizAttemptsData, error: quizAttemptsError } = await supabase
      .from('quiz_attempts')
      .select('user_id, quizzes!inner(module_id)')
      .eq('passed', true);
    if (quizAttemptsError) throw quizAttemptsError;

    const userQuizCompletions = {};
    (quizAttemptsData || []).forEach(q => {
      if (!userQuizCompletions[q.user_id]) userQuizCompletions[q.user_id] = new Set();
      if (q.quizzes && q.quizzes.module_id) {
        userQuizCompletions[q.user_id].add(q.quizzes.module_id);
      }
    });

    // Build the report data
    reportData = [];
    institutions.clear();

    // Map users by id for quick lookup
    const usersMap = {};
    (usersData || []).forEach(u => {
      usersMap[u.user_id] = u;
      if (u.institution && u.institution.trim() !== '') {
        institutions.add(u.institution.trim());
      }
    });

    progressData.forEach(prog => {
      const user = usersMap[prog.user_id];
      if (!user) return; // Si hay un progreso de un usuario que no vino en la consulta de admin

      const courseTitle = coursesData.find(c => c.id === prog.course_id)?.title || 'Curso Desconocido';
      const totalItems = courseItemsCount[prog.course_id] || 0;
      
      let completedItems = 0;
      const userLessonSet = userCompletions[prog.user_id] || new Set();
      const courseLessonSet = courseLessonsMap[prog.course_id] || new Set();
      
      courseLessonSet.forEach(lId => {
        if (userLessonSet.has(lId)) completedItems++;
      });

      const userQuizSet = userQuizCompletions[prog.user_id] || new Set();
      const courseQuizSet = courseQuizzesMap[prog.course_id] || new Set();

      courseQuizSet.forEach(mId => {
        if (userQuizSet.has(mId)) completedItems++;
      });

      let progressPercentage = 0;
      if (totalItems > 0) {
        progressPercentage = Math.floor((completedItems / totalItems) * 100);
      } else {
        // If course has no items, consider it 0%
        progressPercentage = 0;
      }

      const status = progressPercentage >= 100 ? 'completed' : 'in_progress';

      reportData.push({
        userId: user.user_id,
        userName: user.full_name || 'Sin Nombre',
        userEmail: user.email || '',
        institution: user.institution || 'N/A',
        courseId: prog.course_id,
        courseTitle: courseTitle,
        progressPercentage: progressPercentage,
        status: status
      });
    });

    // Populate institution filter
    const filterInst = document.getElementById('filterInstitution');
    filterInst.innerHTML = '<option value="">Todas</option>';
    Array.from(institutions).sort().forEach(inst => {
      const option = document.createElement('option');
      option.value = inst;
      option.textContent = inst;
      filterInst.appendChild(option);
    });

    renderReport();

  } catch (err) {
    console.error(err);
    document.getElementById('reportsTableBody').innerHTML = `
      <tr>
        <td colspan="5" class="text-danger text-center">Error cargando datos: ${err.message}</td>
      </tr>
    `;
  }
}

function renderReport() {
  const filterUser = document.getElementById('filterUser').value.toLowerCase();
  const filterInst = document.getElementById('filterInstitution').value;
  const filterStatus = document.getElementById('filterStatus').value;

  let filtered = reportData.filter(row => {
    const matchUser = row.userName.toLowerCase().includes(filterUser) || row.userEmail.toLowerCase().includes(filterUser);
    const matchInst = filterInst === '' || row.institution === filterInst;
    const matchStatus = filterStatus === '' || row.status === filterStatus;
    
    return matchUser && matchInst && matchStatus;
  });

  // Sort by user name, then course
  filtered.sort((a, b) => a.userName.localeCompare(b.userName) || a.courseTitle.localeCompare(b.courseTitle));

  const tbody = document.getElementById('reportsTableBody');
  tbody.innerHTML = '';

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="5" class="text-center">No se encontraron resultados.</td></tr>`;
  } else {
    filtered.forEach(row => {
      const tr = document.createElement('tr');
      
      const badgeClass = row.status === 'completed' ? 'bg-success' : 'bg-warning text-dark';
      const statusText = row.status === 'completed' ? 'Finalizado' : 'En curso';

      tr.innerHTML = `
        <td>
          <div class="fw-bold">${row.userName}</div>
          <div class="text-muted small">${row.userEmail}</div>
        </td>
        <td>${row.institution}</td>
        <td>${row.courseTitle}</td>
        <td>
          <div class="d-flex align-items-center">
            <div class="progress flex-grow-1 me-2" style="height: 10px;">
              <div class="progress-bar ${row.progressPercentage >= 100 ? 'bg-success' : ''}" role="progressbar" style="width: ${row.progressPercentage}%;" aria-valuenow="${row.progressPercentage}" aria-valuemin="0" aria-valuemax="100"></div>
            </div>
            <span class="small fw-bold">${row.progressPercentage}%</span>
          </div>
        </td>
        <td><span class="badge ${badgeClass}">${statusText}</span></td>
      `;
      tbody.appendChild(tr);
    });
  }

  // Update Summary Widgets
  const uniqueUsers = new Set(filtered.map(r => r.userId)).size;
  const completed = filtered.filter(r => r.status === 'completed').length;
  const inProgress = filtered.filter(r => r.status === 'in_progress').length;

  document.getElementById('summaryTotalUsers').textContent = uniqueUsers;
  document.getElementById('summaryCompletedCourses').textContent = completed;
  document.getElementById('summaryInProgressCourses').textContent = inProgress;
}
