import { supabase, requireAuth } from './supabase.js';

let coursesData = [];
let currentLessonVideos = [];

window.renderVideoInputs = () => {
  const container = document.getElementById('lessonVideosContainer');
  if (!container) return;
  container.innerHTML = '';
  if (currentLessonVideos.length === 0) {
    container.innerHTML = '<p class="text-muted small">Sin videos.</p>';
    return;
  }
  currentLessonVideos.forEach((v, idx) => {
    container.innerHTML += `
      <div class="input-group mb-2">
        <input type="url" class="form-control" placeholder="https://..." value="${v}" onchange="updateVideo(${idx}, this.value)">
        <button class="btn btn-outline-danger" type="button" onclick="removeVideo(${idx})">X</button>
      </div>
    `;
  });
};

window.addVideoInput = () => { currentLessonVideos.push(''); window.renderVideoInputs(); };
window.updateVideo = (idx, val) => { currentLessonVideos[idx] = val; };
window.removeVideo = (idx) => { currentLessonVideos.splice(idx, 1); window.renderVideoInputs(); };

document.addEventListener('DOMContentLoaded', async () => {
  await requireAuth();

  document.getElementById('logout-btn').addEventListener('click', async () => {
    await supabase.auth.signOut();
    window.location.href = '/index.html';
  });

  await loadCourses();

  // Setup form submissions
  document.getElementById('courseForm').addEventListener('submit', handleCourseSubmit);
  document.getElementById('moduleForm').addEventListener('submit', handleModuleSubmit);
  document.getElementById('lessonForm').addEventListener('submit', handleLessonSubmit);

  // Setup import course listener
  document.getElementById('importCourseInput').addEventListener('change', handleCourseImport);

  // Setup paste handler for markdown
  const turndownService = new TurndownService({ headingStyle: 'atx', codeBlockStyle: 'fenced' });
  document.getElementById('lessonContentInput').addEventListener('paste', (e) => {
    const html = e.clipboardData.getData('text/html');
    if (html) {
      e.preventDefault();
      const markdown = turndownService.turndown(html);
      
      const input = e.target;
      const start = input.selectionStart;
      const end = input.selectionEnd;
      
      input.value = input.value.substring(0, start) + markdown + input.value.substring(end);
      input.selectionStart = input.selectionEnd = start + markdown.length;
    }
  });
});

// --- LOAD DATA ---
async function loadCourses() {
  const previousScrollY = window.scrollY;
  document.getElementById('loadingIndicator').style.display = 'block';

  // Fetch courses with nested modules and lessons
  const { data, error } = await supabase
    .from('courses')
    .select('*, modules(*, lessons(*))')
    .order('created_at', { ascending: true });

  if (error) {
    alert('Error cargando cursos: ' + error.message);
    document.getElementById('loadingIndicator').style.display = 'none';
    return;
  }

  coursesData = data || [];
  
  // Sort modules and lessons by order_index
  coursesData.forEach(c => {
    if (c.modules) {
      c.modules.sort((a, b) => a.order_index - b.order_index);
      c.modules.forEach(m => {
        if (m.lessons) {
          m.lessons.sort((a, b) => a.order_index - b.order_index);
        }
      });
    }
  });

  renderCoursesAccordion();

  document.getElementById('loadingIndicator').style.display = 'none';
  document.getElementById('coursesAccordion').style.display = 'block';
  window.scrollTo(0, previousScrollY);
}

window.expandedCourseId = null;

function renderCoursesAccordion() {
  const container = document.getElementById('coursesAccordion');
  container.innerHTML = '';

  if (coursesData.length === 0) {
    container.innerHTML = '<div class="alert alert-info">No hay cursos creados. Haz clic en "Nuevo Curso" para empezar.</div>';
    return;
  }

  coursesData.forEach((course, cIndex) => {
    let isExpanded = false;
    if (window.expandedCourseId === course.id) {
      isExpanded = true;
    }
    // Generar html para modulos
    let modulesHtml = '';
    if (course.modules && course.modules.length > 0) {
      modulesHtml = '<ul class="list-group list-group-flush mb-3">';
      course.modules.forEach((module, mIndex) => {
        
        let lessonsHtml = '';
        if (module.lessons && module.lessons.length > 0) {
          lessonsHtml = '<div class="mt-2"><strong class="small text-muted">Lecciones:</strong><ul class="list-group list-group-flush mt-1">';
          module.lessons.forEach((lesson) => {
            lessonsHtml += `
              <li class="list-group-item d-flex justify-content-between align-items-center bg-light">
                <span>${lesson.order_index}. ${lesson.title}</span>
                <div class="btn-group btn-group-sm">
                  <button class="btn btn-outline-primary" onclick="openLessonModal('${course.id}', '${module.id}', '${lesson.id}')"><i class="bi bi-pencil-square"></i> Editar</button>
                  <button class="btn btn-outline-danger" onclick="deleteLesson('${lesson.id}')"><i class="bi bi-trash"></i> Eliminar</button>
                </div>
              </li>
            `;
          });
          lessonsHtml += '</ul></div>';
        } else {
          lessonsHtml = '<div class="mt-2 small text-muted">No hay lecciones.</div>';
        }

        modulesHtml += `
          <li class="list-group-item border shadow-sm mb-3 rounded">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <h6 class="mb-1">${module.title}</h6>
              </div>
              <div class="btn-group btn-group-sm">
                <button class="btn btn-outline-secondary" onclick="openLessonModal('${course.id}', '${module.id}')"><i class="bi bi-file-earmark-plus"></i> + Lección</button>
                <a href="quiz_editor.html?moduleId=${module.id}" class="btn btn-outline-success"><i class="bi bi-check2-square"></i> Evaluación</a>
                <button class="btn btn-outline-primary" onclick="openModuleModal('${course.id}', '${module.id}')"><i class="bi bi-pencil-square"></i> Editar</button>
                <button class="btn btn-outline-danger" onclick="deleteModule('${module.id}')"><i class="bi bi-trash"></i> Eliminar</button>
              </div>
            </div>
            ${lessonsHtml}
          </li>
        `;
      });
      modulesHtml += '</ul>';
    } else {
      modulesHtml = '<p class="text-muted small">No hay módulos en este curso.</p>';
    }

    const item = document.createElement('div');
    item.className = 'accordion-item';
    item.innerHTML = `
      <h2 class="accordion-header" id="heading${cIndex}">
        <button class="accordion-button ${isExpanded ? '' : 'collapsed'}" type="button" data-bs-toggle="collapse" data-bs-target="#collapse${cIndex}" aria-expanded="${isExpanded}" aria-controls="collapse${cIndex}" onclick="window.expandedCourseId = '${course.id}'">
          <strong class="me-2">${course.title}</strong> <span class="badge bg-secondary rounded-pill">${course.modules ? course.modules.length : 0} Módulos</span>
        </button>
      </h2>
      <div id="collapse${cIndex}" class="accordion-collapse collapse ${isExpanded ? 'show' : ''}" aria-labelledby="heading${cIndex}" data-bs-parent="#coursesAccordion">
        <div class="accordion-body">
          <div class="d-flex justify-content-between mb-3 border-bottom pb-2">
            <div class="mb-0 text-muted markdown-body" style="font-size: 0.95rem;">${course.description ? marked.parse(course.description) : 'Sin descripción'}</div>
            <div class="btn-group btn-group-sm">
              <button class="btn btn-outline-${course.is_published ? 'warning' : 'success'}" onclick="togglePublishCourse('${course.id}', ${!course.is_published})"><i class="bi bi-${course.is_published ? 'eye-slash' : 'eye'}"></i> ${course.is_published ? 'Ocultar' : 'Publicar'} Curso</button>
              <button class="btn btn-outline-info" onclick="exportCourse('${course.id}')"><i class="bi bi-download"></i> Exportar Curso</button>
              <button class="btn btn-outline-primary" onclick="openCourseModal('${course.id}')"><i class="bi bi-pencil-square"></i> Editar Curso</button>
              <button class="btn btn-outline-danger" onclick="deleteCourse('${course.id}')"><i class="bi bi-trash"></i> Eliminar Curso</button>
            </div>
          </div>
          ${modulesHtml}
          <div class="mt-3 border-top pt-3 d-grid">
            <button class="btn btn-primary border-dashed" style="border-style: dashed; border-width: 2px;" onclick="openModuleModal('${course.id}')">
              <i class="bi bi-folder-plus"></i> + Añadir Nuevo Módulo
            </button>
          </div>
        </div>
      </div>
    `;
    container.appendChild(item);
  });
}

// --- GLOBALS FOR MODALS ---
window.openCourseModal = (courseId = null) => {
  const form = document.getElementById('courseForm');
  form.reset();
  document.getElementById('courseIdInput').value = '';
  document.getElementById('courseModalTitle').innerText = 'Nuevo Curso';

  if (courseId) {
    const course = coursesData.find(c => c.id === courseId);
    if (course) {
      document.getElementById('courseIdInput').value = course.id;
      document.getElementById('courseTitleInput').value = course.title;
      document.getElementById('courseDescInput').value = course.description || '';
      document.getElementById('courseHoursInput').value = course.estimated_hours || 0;
      document.getElementById('courseModalTitle').innerText = 'Editar Curso';
    }
  }

  const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('courseModal'));
  modal.show();
};

window.openModuleModal = (courseId, moduleId = null) => {
  const form = document.getElementById('moduleForm');
  form.reset();
  document.getElementById('moduleCourseIdInput').value = courseId;
  document.getElementById('moduleIdInput').value = '';
  
  // Predict next order
  const course = coursesData.find(c => c.id === courseId);
  if (course && course.modules) {
    document.getElementById('moduleOrderInput').value = course.modules.length + 1;
  }

  if (moduleId) {
    const module = course.modules.find(m => m.id === moduleId);
    if (module) {
      document.getElementById('moduleIdInput').value = module.id;
      document.getElementById('moduleTitleInput').value = module.title;
      document.getElementById('moduleOrderInput').value = module.order_index;
    }
  }

  const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('moduleModal'));
  modal.show();
};

window.openLessonModal = (courseId, moduleId, lessonId = null) => {
  const form = document.getElementById('lessonForm');
  form.reset();
  document.getElementById('lessonModuleIdInput').value = moduleId;
  document.getElementById('lessonIdInput').value = '';

  const course = coursesData.find(c => c.id === courseId);
  const module = course.modules.find(m => m.id === moduleId);

  if (module && module.lessons) {
    document.getElementById('lessonOrderInput').value = module.lessons.length + 1;
  }

  currentLessonVideos = [];

  if (lessonId) {
    const lesson = module.lessons.find(l => l.id === lessonId);
    if (lesson) {
      document.getElementById('lessonIdInput').value = lesson.id;
      document.getElementById('lessonTitleInput').value = lesson.title;
      document.getElementById('lessonOrderInput').value = lesson.order_index;
      document.getElementById('lessonContentInput').value = lesson.content_markdown || '';
      
      if (lesson.video_url) {
        try {
          const parsed = JSON.parse(lesson.video_url);
          if (Array.isArray(parsed)) currentLessonVideos = parsed;
          else currentLessonVideos = [lesson.video_url];
        } catch (e) {
          currentLessonVideos = [lesson.video_url];
        }
      }
    }
  }

  window.renderVideoInputs();

  const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('lessonModal'));
  modal.show();
};

// --- SUBMIT HANDLERS ---
async function handleCourseSubmit(e) {
  e.preventDefault();
  const id = document.getElementById('courseIdInput').value;
  const title = document.getElementById('courseTitleInput').value;
  const description = document.getElementById('courseDescInput').value;
  const estimated_hours = parseInt(document.getElementById('courseHoursInput').value) || 0;

  document.getElementById('courseSubmitBtn').disabled = true;

  if (id) {
    await supabase.from('courses').update({ title, description, estimated_hours }).eq('id', id);
  } else {
    await supabase.from('courses').insert({ title, description, estimated_hours, is_published: false });
  }

  bootstrap.Modal.getInstance(document.getElementById('courseModal')).hide();
  document.getElementById('courseSubmitBtn').disabled = false;
  await loadCourses();
}

async function handleModuleSubmit(e) {
  e.preventDefault();
  const courseId = document.getElementById('moduleCourseIdInput').value;
  const id = document.getElementById('moduleIdInput').value;
  const title = document.getElementById('moduleTitleInput').value;
  const order_index = parseInt(document.getElementById('moduleOrderInput').value);

  document.getElementById('moduleSubmitBtn').disabled = true;

  if (id) {
    await supabase.from('modules').update({ title, order_index }).eq('id', id);
  } else {
    await supabase.from('modules').insert({ course_id: courseId, title, order_index });
  }

  bootstrap.Modal.getInstance(document.getElementById('moduleModal')).hide();
  document.getElementById('moduleSubmitBtn').disabled = false;
  await loadCourses();
}

async function handleLessonSubmit(e) {
  e.preventDefault();
  const moduleId = document.getElementById('lessonModuleIdInput').value;
  const id = document.getElementById('lessonIdInput').value;
  const title = document.getElementById('lessonTitleInput').value;
  const order_index = parseInt(document.getElementById('lessonOrderInput').value);
  const content_markdown = document.getElementById('lessonContentInput').value;

  const validVideos = currentLessonVideos.filter(v => v.trim() !== '');
  const finalVideoUrl = validVideos.length > 0 ? JSON.stringify(validVideos) : null;

  const data = {
    title,
    order_index,
    content_markdown,
    video_url: finalVideoUrl
  };

  document.getElementById('lessonSubmitBtn').disabled = true;

  if (id) {
    await supabase.from('lessons').update(data).eq('id', id);
  } else {
    data.module_id = moduleId;
    await supabase.from('lessons').insert(data);
  }

  bootstrap.Modal.getInstance(document.getElementById('lessonModal')).hide();
  document.getElementById('lessonSubmitBtn').disabled = false;
  await loadCourses();
}

// --- PUBLISH HANDLER ---
window.togglePublishCourse = async (id, publish) => {
  if (confirm(`¿Estás seguro de ${publish ? 'publicar' : 'ocultar'} este curso? ${publish ? 'Aparecerá en la aplicación para todos los usuarios.' : 'Ya no estará disponible en la aplicación.'}`)) {
    document.getElementById('loadingIndicator').style.display = 'block';
    await supabase.from('courses').update({ is_published: publish }).eq('id', id);
    await loadCourses();
  }
};

// --- DELETE HANDLERS ---
window.deleteCourse = async (id) => {
  if (confirm('¿Estás seguro de eliminar este curso? Se borrarán todos los módulos y lecciones asociados.')) {
    const course = coursesData.find(c => c.id === id);
    if (course) {
      for (const m of course.modules || []) {
        await window.deleteModuleCascades(m);
      }
    }
    await supabase.from('user_progress').delete().eq('course_id', id);
    await supabase.from('certificates').delete().eq('course_id', id);
    await supabase.from('courses').delete().eq('id', id);
    await loadCourses();
  }
};

window.deleteModuleCascades = async (module) => {
  if (module.lessons) {
    const lessonIds = module.lessons.map(l => l.id);
    if (lessonIds.length > 0) {
      await supabase.from('lesson_completion').delete().in('lesson_id', lessonIds);
    }
  }
  // Quiz cascade
  const { data: quizzes } = await supabase.from('quizzes').select('id').eq('module_id', module.id);
  if (quizzes && quizzes.length > 0) {
    const quizIds = quizzes.map(q => q.id);
    await supabase.from('quiz_attempts').delete().in('quiz_id', quizIds);
  }
};

window.deleteModule = async (id) => {
  if (confirm('¿Eliminar módulo? Se borrarán sus lecciones y evaluaciones.')) {
    let module = null;
    for (const c of coursesData) {
      const found = c.modules?.find(m => m.id === id);
      if (found) module = found;
    }
    if (module) {
      await window.deleteModuleCascades(module);
    } else {
      // Fallback if not found in memory
      await window.deleteModuleCascades({id, lessons: []});
    }
    await supabase.from('modules').delete().eq('id', id);
    await loadCourses();
  }
};

window.deleteLesson = async (id) => {
  if (confirm('¿Eliminar lección?')) {
    await supabase.from('lesson_completion').delete().eq('lesson_id', id);
    await supabase.from('lessons').delete().eq('id', id);
    await loadCourses();
  }
};

// --- EXPORT COURSE ---
window.exportCourse = async (courseId) => {
  document.getElementById('loadingIndicator').style.display = 'block';
  try {
    const course = coursesData.find(c => c.id === courseId);
    if (!course) throw new Error("Curso no encontrado.");

    let exportData = {
      course: {
        title: course.title,
        description: course.description,
        estimated_hours: course.estimated_hours,
      },
      modules: []
    };

    if (course.modules) {
      for (let m of course.modules) {
        let moduleData = {
          title: m.title,
          order_index: m.order_index,
          lessons: [],
          quiz: null
        };

        if (m.lessons) {
          moduleData.lessons = m.lessons.map(l => ({
            title: l.title,
            order_index: l.order_index,
            content_markdown: l.content_markdown,
            video_url: l.video_url
          }));
        }

        const { data: quizData } = await supabase.from('quizzes').select('*, questions(*, answers(*))').eq('module_id', m.id).maybeSingle();
        if (quizData) {
          moduleData.quiz = {
            title: quizData.title,
            passing_score: quizData.passing_score,
            max_attempts: quizData.max_attempts,
            questions: (quizData.questions || []).map(q => ({
              question_text: q.question_text,
              question_type: q.question_type,
              order_index: q.order_index,
              answers: (q.answers || []).map(a => ({
                answer_text: a.answer_text,
                is_correct: a.is_correct,
                feedback_text: a.feedback_text
              }))
            }))
          };
        }

        exportData.modules.push(moduleData);
      }
    }

    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(exportData, null, 2));
    const downloadAnchorNode = document.createElement('a');
    downloadAnchorNode.setAttribute("href", dataStr);
    downloadAnchorNode.setAttribute("download", `curso_backup_${course.title.replace(/\s+/g, '_')}.json`);
    document.body.appendChild(downloadAnchorNode);
    downloadAnchorNode.click();
    downloadAnchorNode.remove();

  } catch (error) {
    alert("Error al exportar curso: " + error.message);
  } finally {
    document.getElementById('loadingIndicator').style.display = 'none';
  }
};

// --- IMPORT COURSE ---
async function handleCourseImport(e) {
  const file = e.target.files[0];
  if (!file) return;

  document.getElementById('loadingIndicator').style.display = 'block';

  try {
    const text = await file.text();
    const data = JSON.parse(text);

    if (!data.course || !data.course.title) throw new Error("Archivo JSON no válido.");

    // Insert Course
    const { data: newCourse, error: errCourse } = await supabase.from('courses').insert({
      title: data.course.title,
      description: data.course.description,
      estimated_hours: data.course.estimated_hours,
      is_published: false
    }).select().single();
    if (errCourse) throw errCourse;

    const newCourseId = newCourse.id;

    if (data.modules && data.modules.length > 0) {
      for (let m of data.modules) {
        // Insert Module
        const { data: newModule, error: errMod } = await supabase.from('modules').insert({
          course_id: newCourseId,
          title: m.title,
          order_index: m.order_index
        }).select().single();
        if (errMod) throw errMod;
        
        const newModuleId = newModule.id;

        // Insert Lessons
        if (m.lessons && m.lessons.length > 0) {
          const lessonsToInsert = m.lessons.map(l => ({
            module_id: newModuleId,
            title: l.title,
            order_index: l.order_index,
            content_markdown: l.content_markdown,
            video_url: l.video_url
          }));
          const { error: errLess } = await supabase.from('lessons').insert(lessonsToInsert);
          if (errLess) throw errLess;
        }

        // Insert Quiz
        if (m.quiz) {
          const { data: newQuiz, error: errQuiz } = await supabase.from('quizzes').insert({
            module_id: newModuleId,
            title: m.quiz.title,
            passing_score: m.quiz.passing_score,
            max_attempts: m.quiz.max_attempts
          }).select().single();
          if (errQuiz) throw errQuiz;

          const newQuizId = newQuiz.id;

          if (m.quiz.questions && m.quiz.questions.length > 0) {
            for (let q of m.quiz.questions) {
              const { data: newQuestion, error: errQ } = await supabase.from('questions').insert({
                quiz_id: newQuizId,
                question_text: q.question_text,
                question_type: q.question_type,
                order_index: q.order_index
              }).select().single();
              if (errQ) throw errQ;

              if (q.answers && q.answers.length > 0) {
                const answersToInsert = q.answers.map(a => ({
                  question_id: newQuestion.id,
                  answer_text: a.answer_text,
                  is_correct: a.is_correct,
                  feedback_text: a.feedback_text
                }));
                const { error: errA } = await supabase.from('answers').insert(answersToInsert);
                if (errA) throw errA;
              }
            }
          }
        }
      }
    }

    alert("¡Curso importado exitosamente!");
    await loadCourses();
  } catch (error) {
    alert("Error importando curso: " + error.message);
  } finally {
    e.target.value = ''; // Reset input
    document.getElementById('loadingIndicator').style.display = 'none';
  }
}
