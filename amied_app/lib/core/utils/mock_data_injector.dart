import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/learning/domain/modulo.dart';
import '../../features/simulator/domain/caso_simulado.dart';

Future<void> injectMockData() async {
  await _injectModulos();
  await _injectCasos();
}

Future<void> _injectModulos() async {
  final supabase = Supabase.instance.client;

  final List<Modulo> modulosPrueba = [
    Modulo(
      id: 'mod_1',
      titulo: 'Fundamentos de Educación Inclusiva',
      descripcion: 'Conceptos básicos, marco legal y principios de la inclusión educativa.',
      contenido:
          'La educación inclusiva es un modelo que busca atender las necesidades de aprendizaje de todos los niños, jóvenes y adultos, con especial énfasis en aquellos vulnerables a la marginalidad y la exclusión.\n\n'
          '📌 Principios clave:\n'
          '• Igualdad de oportunidades\n'
          '• Participación activa\n'
          '• Respeto a la diversidad\n'
          '• Colaboración entre familia, docentes e institución\n\n'
          '📋 Marco legal en Ecuador:\n'
          'La Ley Orgánica de Educación Intercultural (LOEI) reconoce el derecho a una educación inclusiva y de calidad.',
      categoria: 'Teoría',
      dificultad: 'Básica',
    ),
    Modulo(
      id: 'mod_2',
      titulo: 'Estrategias para estudiantes con TEA',
      descripcion: 'Metodologías y adaptaciones para atender a estudiantes con Trastorno del Espectro Autista.',
      contenido:
          'El TEA (Trastorno del Espectro Autista) es una condición del neurodesarrollo que afecta la comunicación y la conducta. Como docente, puedes aplicar:\n\n'
          '🗓️ 1. Anticipación:\nUtiliza agendas visuales y anticipa los cambios de rutina para reducir la ansiedad.\n\n'
          '🧩 2. Estructuración del espacio:\nMantén un ambiente organizado, predecible y con zonas de calma accesibles.\n\n'
          '🗣️ 3. Comunicación aumentativa:\nApóyate en pictogramas, tableros de comunicación o aplicaciones de CAA.\n\n'
          '🎯 4. Refuerzo positivo:\nPremia los logros con estrategias individualizadas (no siempre verbal).',
      categoria: 'Estrategias',
      dificultad: 'Intermedia',
    ),
    Modulo(
      id: 'mod_3',
      titulo: 'Diseño Universal para el Aprendizaje (DUA)',
      descripcion: 'Aplicación de múltiples formas de representación, expresión y compromiso.',
      contenido:
          'El Diseño Universal para el Aprendizaje es un marco pedagógico que propone diseñar currículos flexibles que reduzcan las barreras al aprendizaje y ofrezcan oportunidades para todos los estudiantes.\n\n'
          '🔵 Principio 1 – Múltiples medios de representación:\nOfrece la información en texto, audio, video e imágenes.\n\n'
          '🟢 Principio 2 – Múltiples medios de acción y expresión:\nPermite que los estudiantes demuestren lo aprendido de diversas formas (oral, escrita, visual).\n\n'
          '🟡 Principio 3 – Múltiples medios de participación:\nConecta el aprendizaje con los intereses del estudiante para mantener la motivación.',
      categoria: 'Metodología',
      dificultad: 'Avanzada',
    ),
  ];

  for (var modulo in modulosPrueba) {
    await supabase.from('modulos').upsert({
      'id': modulo.id,
      'titulo': modulo.titulo,
      'descripcion': modulo.descripcion,
      'contenido': modulo.contenido,
      'categoria': modulo.categoria,
      'dificultad': modulo.dificultad,
    });
  }
}

Future<void> _injectCasos() async {
  final supabase = Supabase.instance.client;

  final List<CasoSimulado> casosPrueba = [
    CasoSimulado(
      id: 'caso_1',
      idModuloVinculado: 'mod_2',
      titulo: 'Sensibilidad Sensorial en Actividad Grupal',
      situacion:
          'Durante una actividad grupal con música de fondo, un estudiante con TEA comienza a taparse los oídos, se balancea en su silla y empieza a mostrar signos de angustia. '
          'Sus compañeros no se dan cuenta y continúan trabajando con normalidad.',
      necesidadEducativa: 'TEA – Hipersensibilidad Sensorial',
      nivelDificultad: 'Básico',
      opciones: [
        OpcionRespuesta(id: 'a', texto: 'A) Continúo la actividad normalmente, espero que se adapte solo.'),
        OpcionRespuesta(id: 'b', texto: 'B) Bajo el volumen de la música, le ofrezco auriculares y le propongo una zona tranquila de trabajo.'),
        OpcionRespuesta(id: 'c', texto: 'C) Le pido que se retire del salón hasta que termine la actividad.'),
        OpcionRespuesta(id: 'd', texto: 'D) Llamo a los padres inmediatamente para que lo retiren de la clase.'),
      ],
      idRespuestaCorrecta: 'b',
      explicacionPedagogica:
          'La respuesta correcta es B. Los estudiantes con TEA pueden tener hipersensibilidad sensorial, lo que significa que estímulos como el ruido pueden ser genuinamente dolorosos o abrumadores para ellos. '
          'La estrategia más adecuada es reducir el estímulo (bajar el volumen), proporcionar herramientas de autorregulación (auriculares, tapones) y habilitar un espacio de calma sin excluir al estudiante. '
          'Ignorar la situación o aislar al estudiante del grupo son respuestas que pueden incrementar la ansiedad y vulnerar su derecho a la inclusión.',
    ),
    CasoSimulado(
      id: 'caso_2',
      idModuloVinculado: 'mod_1',
      titulo: 'Estudiante con dificultades de comunicación',
      situacion:
          'Al hacer una pregunta abierta al grupo, un estudiante con dificultades en el lenguaje oral levanta la mano con entusiasmo pero al intentar responder se bloquea y no puede articular las palabras. '
          'Algunos compañeros empiezan a reírse.',
      necesidadEducativa: 'Dificultades de comunicación',
      nivelDificultad: 'Básico',
      opciones: [
        OpcionRespuesta(id: 'a', texto: 'A) Le pido que lo escriba en el pizarrón y dirijo la atención del grupo hacia él con respeto.'),
        OpcionRespuesta(id: 'b', texto: 'B) Le digo que intente de nuevo más tarde y paso a otro estudiante.'),
        OpcionRespuesta(id: 'c', texto: 'C) Le ofrezco terminar la frase yo mismo para ahorrar tiempo.'),
        OpcionRespuesta(id: 'd', texto: 'D) Le señalo que debe practicar más en casa.'),
      ],
      idRespuestaCorrecta: 'a',
      explicacionPedagogica:
          'La respuesta correcta es A. Ofrecer medios alternativos de expresión (como la escritura en el pizarrón) respeta la dignidad del estudiante, aplica el principio DUA de múltiples formas de expresión y además gestiona el clima del aula redirectando positivamente la atención del grupo. '
          'Completar su respuesta o ignorarle perpetúa la exclusión y afecta negativamente su autoestima y participación futura.',
    ),
  ];

  for (var caso in casosPrueba) {
    await supabase.from('casos_simulados').upsert({
      'id': caso.id,
      'id_modulo_vinculado': caso.idModuloVinculado,
      'titulo': caso.titulo,
      'situacion': caso.situacion,
      'necesidad_educativa': caso.necesidadEducativa,
      'nivel_dificultad': caso.nivelDificultad,
      'opciones': caso.opciones.map((e) => e.toMap()).toList(),
      'id_respuesta_correcta': caso.idRespuestaCorrecta,
      'explicacion_pedagogica': caso.explicacionPedagogica,
    });
  }
}
