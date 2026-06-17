import { supabase, requireAuth } from './supabase.js';

let moduleId = null;
let currentQuizId = null;
let questions = [];

document.addEventListener('DOMContentLoaded', async () => {
  await requireAuth();

  const urlParams = new URLSearchParams(window.location.search);
  moduleId = urlParams.get('moduleId');

  if (!moduleId) {
    alert('Módulo no especificado');
    window.location.href = '/courses.html';
    return;
  }

  document.getElementById('logout-btn').addEventListener('click', async () => {
    await supabase.auth.signOut();
    window.location.href = '/index.html';
  });

  const addQuestionLogic = () => {
    questions.push({
      id: 'temp_' + Date.now(),
      question_text: '',
      question_type: 'multiple_choice',
      answers: [
        { answer_text: '', is_correct: true, feedback_text: '' },
        { answer_text: '', is_correct: false, feedback_text: '' }
      ]
    });
    renderQuestions();
    setTimeout(() => {
      window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
    }, 100);
  };

  document.getElementById('addQuestionBtn').addEventListener('click', addQuestionLogic);
  
  const bottomBtn = document.getElementById('addQuestionBtnBottom');
  if (bottomBtn) bottomBtn.addEventListener('click', addQuestionLogic);

  document.getElementById('saveQuizBtn').addEventListener('click', saveQuiz);
  
  const saveBtnBottom = document.getElementById('saveQuizBtnBottom');
  if (saveBtnBottom) saveBtnBottom.addEventListener('click', saveQuiz);

  document.getElementById('importMarkdownBtn').addEventListener('click', () => {
    document.getElementById('markdownInputText').value = '';
    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('markdownModal'));
    modal.show();
  });

  document.getElementById('processMarkdownBtn').addEventListener('click', processMarkdownQuiz);

  await loadQuizData();
});

function processMarkdownQuiz() {
  const text = document.getElementById('markdownInputText').value;
  if (!text.trim()) return;

  const parts = text.split(/##\s*Pregunta/i);
  let addedCount = 0;

  for (let i = 1; i < parts.length; i++) {
    let part = parts[i].trim();
    const lines = part.split('\n').map(l => l.trim()).filter(l => l.length > 0);
    if (lines.length === 0) continue;

    const headerMatch = lines[0].match(/.*?\(?(Selecci.n m.ltiple|Verdadero o falso)\)?/i);
    if (!headerMatch) continue;

    const typeStr = headerMatch[1].toLowerCase();
    let qType = typeStr.includes('verdadero') ? 'true_false' : 'multiple_choice';
    
    let questionText = '';
    let j = 1;
    while (j < lines.length && !lines[j].match(/^[A-Z]\)/) && !lines[j].toLowerCase().startsWith('**respuesta')) {
      questionText += (questionText ? '\n' : '') + lines[j];
      j++;
    }

    let newQ = {
      id: 'temp_md_' + Date.now() + '_' + i,
      question_text: questionText.trim(),
      question_type: qType,
      answers: []
    };

    let correctAnswerLetter = null;
    let correctAnswerTF = null;
    
    if (qType === 'multiple_choice') {
      const optionsMap = {};
      while (j < lines.length && lines[j].match(/^[A-Z]\)/)) {
        const match = lines[j].match(/^([A-Z])\)\s*(.*)/);
        if (match) {
          optionsMap[match[1]] = match[2];
        }
        j++;
      }
      
      while (j < lines.length) {
        if (lines[j].toLowerCase().includes('respuesta')) {
          const directMatch = lines[j].match(/:\s*\*?\*?\s*([A-Z])/i);
          if (directMatch) correctAnswerLetter = directMatch[1].toUpperCase();
        }
        j++;
      }

      for (const [letter, text] of Object.entries(optionsMap)) {
        newQ.answers.push({
          answer_text: text,
          is_correct: letter === correctAnswerLetter,
          feedback_text: ''
        });
      }
    } else {
      while (j < lines.length) {
        if (lines[j].toLowerCase().includes('respuesta:')) {
          if (lines[j].toLowerCase().includes('verdadero')) correctAnswerTF = true;
          else if (lines[j].toLowerCase().includes('falso')) correctAnswerTF = false;
        }
        j++;
      }
      
      newQ.answers.push({
        answer_text: 'Verdadero',
        is_correct: correctAnswerTF === true,
        feedback_text: ''
      });
      newQ.answers.push({
        answer_text: 'Falso',
        is_correct: correctAnswerTF === false,
        feedback_text: ''
      });
    }
    
    questions.push(newQ);
    addedCount++;
  }

  renderQuestions();
  bootstrap.Modal.getInstance(document.getElementById('markdownModal')).hide();
  alert(`Se procesaron y agregaron ${addedCount} preguntas exitosamente.`);
}

async function loadQuizData() {
  document.getElementById('loadingIndicator').style.display = 'block';
  document.getElementById('quizFormContainer').style.display = 'none';

  const { data: quiz, error } = await supabase
    .from('quizzes')
    .select('*, questions(*, answers(*))')
    .eq('module_id', moduleId)
    .maybeSingle();

  if (error) {
    console.error(error);
  }

  if (quiz) {
    currentQuizId = quiz.id;
    document.getElementById('quizTitle').value = quiz.title;
    document.getElementById('quizPassingScore').value = quiz.passing_score;
    document.getElementById('quizMaxAttempts').value = quiz.max_attempts;

    if (quiz.questions) {
      quiz.questions.sort((a, b) => a.order_index - b.order_index);
      questions = quiz.questions.map(q => ({
        id: q.id,
        question_text: q.question_text,
        question_type: q.question_type,
        answers: q.answers || []
      }));
    }
  } else {
    // defaults
    questions = [];
  }

  renderQuestions();

  document.getElementById('loadingIndicator').style.display = 'none';
  document.getElementById('quizFormContainer').style.display = 'block';
}

function renderQuestions() {
  const container = document.getElementById('questionsContainer');
  container.innerHTML = '';

  if (questions.length === 0) {
    container.innerHTML = '<div class="alert alert-secondary">No hay preguntas en esta evaluación. Haz clic en "Añadir Pregunta".</div>';
    return;
  }

  questions.forEach((q, qIndex) => {
    const qDiv = document.createElement('div');
    qDiv.className = 'card mb-4 shadow-sm border-primary';
    
    let answersHtml = '';
    q.answers.forEach((a, aIndex) => {
      answersHtml += `
        <div class="input-group mb-2">
          ${q.question_type === 'match_pairs' || q.question_type === 'fill_in_the_blank' ? '' : `
          <div class="input-group-text">
            <input class="form-check-input mt-0" type="checkbox" ${a.is_correct ? 'checked' : ''} onchange="updateAnswer(${qIndex}, ${aIndex}, 'is_correct', this.checked)">
          </div>
          `}
          ${q.question_type === 'match_pairs' 
            ? `<input type="text" class="form-control" placeholder="Concepto" value="${(a.answer_text || '|').split('|')[0] || ''}" onchange="updateMatchAnswer(${qIndex}, ${aIndex}, 'concept', this.value)">
               <input type="text" class="form-control" placeholder="Definición" value="${(a.answer_text || '|').split('|').length > 1 ? a.answer_text.split('|').slice(1).join('|') : ''}" onchange="updateMatchAnswer(${qIndex}, ${aIndex}, 'definition', this.value)">`
            : `<input type="text" class="form-control" placeholder="${q.question_type === 'fill_in_the_blank' ? 'Palabra válida (sinónimo)' : 'Respuesta'}" value="${a.answer_text}" ${q.question_type === 'true_false' ? 'readonly' : ''} onchange="updateAnswer(${qIndex}, ${aIndex}, 'answer_text', this.value)">`
          }
          ${q.question_type === 'match_pairs' ? '' : `<input type="text" class="form-control" placeholder="Feedback (opcional)" value="${a.feedback_text || ''}" onchange="updateAnswer(${qIndex}, ${aIndex}, 'feedback_text', this.value)">`}
          ${q.question_type !== 'true_false' ? `<button class="btn btn-outline-danger" type="button" onclick="removeAnswer(${qIndex}, ${aIndex})">X</button>` : ''}
        </div>
      `;
    });

    qDiv.innerHTML = `
      <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
        <span>Pregunta ${qIndex + 1}</span>
        <button class="btn btn-sm btn-danger" onclick="removeQuestion(${qIndex})">Eliminar Pregunta</button>
      </div>
      <div class="card-body">
        <div class="row mb-3">
          <div class="col-md-9">
            <textarea class="form-control" rows="2" placeholder="${q.question_type === 'fill_in_the_blank' ? 'Ej: La capital de Francia es ___ (usa ___ para el espacio en blanco)' : 'Escribe la pregunta aquí...'}" onchange="updateQuestion(${qIndex}, 'question_text', this.value)">${q.question_text}</textarea>
          </div>
          <div class="col-md-3">
            <select class="form-select" onchange="changeQuestionType(${qIndex}, this.value)">
              <option value="multiple_choice" ${q.question_type === 'multiple_choice' ? 'selected' : ''}>Opción Múltiple</option>
              <option value="true_false" ${q.question_type === 'true_false' ? 'selected' : ''}>Verdadero / Falso</option>
              <option value="match_pairs" ${q.question_type === 'match_pairs' ? 'selected' : ''}>Relacionar Conceptos</option>
              <option value="fill_in_the_blank" ${q.question_type === 'fill_in_the_blank' ? 'selected' : ''}>Completar Espacios</option>
            </select>
          </div>
        </div>
        <h6>${q.question_type === 'match_pairs' ? 'Pares Concepto - Definición:' : q.question_type === 'fill_in_the_blank' ? 'Palabras correctas aceptadas (sinónimos):' : 'Opciones de Respuesta: (Marca las correctas)'}</h6>
        ${answersHtml}
        ${q.question_type !== 'true_false' ? `<button class="btn btn-sm btn-outline-secondary mt-2" onclick="addAnswer(${qIndex})">${q.question_type === 'match_pairs' ? '+ Añadir Par' : q.question_type === 'fill_in_the_blank' ? '+ Añadir Palabra Válida' : '+ Añadir Opción'}</button>` : ''}
      </div>
    `;
    container.appendChild(qDiv);
  });
}

// --- DOM Updaters ---
window.updateQuestion = (qIndex, field, value) => { questions[qIndex][field] = value; };
window.changeQuestionType = (qIndex, newType) => {
  questions[qIndex].question_type = newType;
  if (newType === 'true_false') {
    questions[qIndex].answers = [
      { answer_text: 'Verdadero', is_correct: true, feedback_text: '' },
      { answer_text: 'Falso', is_correct: false, feedback_text: '' }
    ];
  } else if (newType === 'match_pairs') {
    questions[qIndex].answers = [
      { answer_text: 'Concepto 1|Definición 1', is_correct: true, feedback_text: '' },
      { answer_text: 'Concepto 2|Definición 2', is_correct: true, feedback_text: '' }
    ];
  } else if (newType === 'fill_in_the_blank') {
    questions[qIndex].answers = [
      { answer_text: '', is_correct: true, feedback_text: '' }
    ];
  }
  renderQuestions();
};
window.updateAnswer = (qIndex, aIndex, field, value) => { questions[qIndex].answers[aIndex][field] = value; };
window.updateMatchAnswer = (qIndex, aIndex, part, value) => {
  let parts = (questions[qIndex].answers[aIndex].answer_text || '|').split('|');
  if (parts.length < 2) parts = [parts[0] || '', ''];
  if (part === 'concept') parts[0] = value;
  if (part === 'definition') parts[1] = value;
  questions[qIndex].answers[aIndex].answer_text = parts.join('|');
  questions[qIndex].answers[aIndex].is_correct = true;
};
window.addAnswer = (qIndex) => { 
  if (questions[qIndex].question_type === 'match_pairs') {
    questions[qIndex].answers.push({ answer_text: 'Nuevo Concepto|Nueva Definición', is_correct: true, feedback_text: '' });
  } else if (questions[qIndex].question_type === 'fill_in_the_blank') {
    questions[qIndex].answers.push({ answer_text: '', is_correct: true, feedback_text: '' });
  } else {
    questions[qIndex].answers.push({ answer_text: '', is_correct: false, feedback_text: '' }); 
  }
  renderQuestions(); 
};
window.removeAnswer = (qIndex, aIndex) => { questions[qIndex].answers.splice(aIndex, 1); renderQuestions(); };
window.removeQuestion = (qIndex) => { if(confirm('¿Eliminar pregunta?')) { questions.splice(qIndex, 1); renderQuestions(); } };

// --- SAVE TO DB ---
async function saveQuiz() {
  const btn = document.getElementById('saveQuizBtn');
  btn.disabled = true;
  btn.innerText = 'Guardando...';

  const title = document.getElementById('quizTitle').value;
  const passing_score = parseInt(document.getElementById('quizPassingScore').value);
  const max_attempts = parseInt(document.getElementById('quizMaxAttempts').value);

  try {
    let quizId = currentQuizId;

    if (quizId) {
      // Update Quiz
      await supabase.from('quizzes').update({ title, passing_score, max_attempts }).eq('id', quizId);

      // We wipe old questions and re-insert to simplify logic for this admin panel
      const { data: oldQs } = await supabase.from('questions').select('id').eq('quiz_id', quizId);
      if (oldQs) {
        for (const oq of oldQs) {
          await supabase.from('answers').delete().eq('question_id', oq.id);
        }
        await supabase.from('questions').delete().eq('quiz_id', quizId);
      }
    } else {
      // Create Quiz
      const { data: newQ, error } = await supabase.from('quizzes').insert({ module_id: moduleId, title, passing_score, max_attempts }).select().single();
      if (error) throw error;
      quizId = newQ.id;
      currentQuizId = quizId;
    }

    // Insert Questions
    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      const { data: newQuestion, error: errQ } = await supabase.from('questions').insert({
        quiz_id: quizId,
        question_text: q.question_text,
        question_type: q.question_type,
        order_index: i
      }).select().single();

      if (errQ) throw errQ;

      // Insert Answers
      for (let a of q.answers) {
        await supabase.from('answers').insert({
          question_id: newQuestion.id,
          answer_text: a.answer_text,
          is_correct: a.is_correct,
          feedback_text: a.feedback_text
        });
      }
    }

    alert('¡Evaluación guardada exitosamente!');
    window.location.href = '/courses.html';
  } catch (error) {
    alert('Error al guardar: ' + error.message);
  } finally {
    btn.disabled = false;
    btn.innerText = 'Guardar Evaluación';
  }
}
