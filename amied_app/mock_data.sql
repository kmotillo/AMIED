-- MOCK DATA PARA EDUCACIÓN INCLUSIVA

-- 1. Crear el Curso
INSERT INTO courses (id, title, description, estimated_hours, is_published)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'Fundamentos de la Educación Inclusiva',
  'Este curso proporciona las bases teóricas y prácticas para comprender e implementar la educación inclusiva en el entorno universitario. Diseñado especialmente para docentes de educación superior.',
  10,
  true
);

-- 2. Crear los Módulos
INSERT INTO modules (id, course_id, title, description, order_index)
VALUES 
  ('22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111111', 'Módulo 1: Conceptos Básicos', 'Introducción a la educación inclusiva y modelos de discapacidad.', 1),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Módulo 2: Marco Normativo', 'Leyes y normativas que amparan la educación inclusiva en Ecuador.', 2);

-- 3. Crear las Lecciones
INSERT INTO lessons (id, module_id, title, content_markdown, order_index)
VALUES 
  ('33333333-3333-3333-3333-333333333331', '22222222-2222-2222-2222-222222222221', '¿Qué es la Educación Inclusiva?', '# La Educación Inclusiva\n\nEs un modelo que busca atender las necesidades de **todos** los estudiantes, reconociendo y valorando sus diferencias.\n\nEn la universidad, esto implica...', 1),
-- 4. Crear un Quiz para el Módulo 1
INSERT INTO quizzes (id, module_id, title, passing_score, max_attempts)
VALUES (
  '44444444-4444-4444-4444-444444444441', '22222222-2222-2222-2222-222222222221', 'Evaluación: Conceptos Básicos', 70, 3
);

-- 5. Crear Preguntas
INSERT INTO questions (id, quiz_id, question_text, question_type, order_index)
VALUES 
  ('55555555-5555-5555-5555-555555555551', '44444444-4444-4444-4444-444444444441', '¿Cuál es la principal diferencia entre Integración e Inclusión?', 'multiple_choice', 1),
  ('55555555-5555-5555-5555-555555555552', '44444444-4444-4444-4444-444444444441', 'La educación inclusiva se enfoca únicamente en estudiantes con discapacidad.', 'multiple_choice', 2);

-- 6. Crear Respuestas
INSERT INTO answers (id, question_id, answer_text, is_correct, feedback_text)
VALUES
  -- Pregunta 1
  ('66666666-6666-6666-6666-666666666661', '55555555-5555-5555-5555-555555555551', 'En la integración el alumno se adapta, en la inclusión el sistema se adapta.', true, '¡Correcto! La inclusión transforma el entorno para acoger a todos.'),
  ('66666666-6666-6666-6666-666666666662', '55555555-5555-5555-5555-555555555551', 'Son exactamente lo mismo.', false, 'Incorrecto. La integración obliga al estudiante a asimilarse a un entorno no preparado.'),
  -- Pregunta 2
  ('66666666-6666-6666-6666-666666666663', '55555555-5555-5555-5555-555555555552', 'Verdadero', false, 'Falso. Se enfoca en TODOS los estudiantes, valorando la diversidad en general.'),
  ('66666666-6666-6666-6666-666666666664', '55555555-5555-5555-5555-555555555552', 'Falso', true, '¡Correcto! La inclusión beneficia a toda la comunidad educativa.');

-- 7. Crear Medallas (Gamificación)
INSERT INTO badges (id, name, description, points_required)
VALUES
  ('77777777-7777-7777-7777-777777777771', 'Iniciador Inclusivo', 'Completaste tu primera evaluación.', 50),
  ('77777777-7777-7777-7777-777777777772', 'Promotor de Derechos', 'Alcanzaste el Nivel 2.', 100),
  ('77777777-7777-7777-7777-777777777773', 'Experto Universal', 'Completaste múltiples evaluaciones.', 500);
