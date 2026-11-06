import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Published text currently displayed by the app. Legal drafts stay separate.
abstract final class TermsDocument {
  static const id = 'saferisk_inspecciones_terms';
  static const version = '1.0';
  static const updatedLabel = 'agosto de 2026';
  static const title = 'Términos y condiciones';
  static const sections = <({String title, String content})>[
    (
      title: 'Objeto',
      content:
          'SafeRisk Inspecciones es una herramienta de trabajo destinada a apoyar la gestión operativa de los procesos de inspección asignados a los usuarios autorizados.',
    ),
    (
      title: 'Uso autorizado',
      content:
          'El acceso y uso de la aplicación está destinado exclusivamente a usuarios autorizados por SafeRisk. El usuario se compromete a utilizar la aplicación únicamente para actividades relacionadas con sus funciones y responsabilidades asignadas.',
    ),
    (
      title: 'Responsabilidad del usuario',
      content:
          'El usuario es responsable de la información registrada durante el proceso de inspección y deberá procurar que los datos ingresados sean correctos, completos y correspondan al caso gestionado.',
    ),
    (
      title: 'Credenciales y seguridad',
      content:
          'Las credenciales de acceso son personales. El usuario deberá mantenerlas bajo su responsabilidad y evitar compartirlas con terceros. SafeRisk podrá restringir el acceso cuando detecte un uso no autorizado o contrario a las políticas establecidas.',
    ),
    (
      title: 'Ubicación y datos operativos',
      content:
          'Durante determinados procesos la aplicación podrá solicitar acceso a la ubicación del dispositivo para registrar información relacionada con la ejecución de una inspección. El uso de esta información estará vinculado a las funciones operativas de SafeRisk.',
    ),
    (
      title: 'Fotografías y documentos',
      content:
          'Las fotografías, documentos e información recopilados durante una inspección podrán ser procesados y almacenados con el propósito de gestionar y respaldar el servicio correspondiente.',
    ),
    (
      title: 'Disponibilidad del servicio',
      content:
          'SafeRisk realizará esfuerzos razonables para mantener la aplicación disponible y operativa. Sin embargo, podrán existir interrupciones temporales relacionadas con mantenimiento, conectividad, infraestructura o actualizaciones del sistema.',
    ),
    (
      title: 'Actualizaciones',
      content:
          'SafeRisk podrá publicar nuevas versiones de la aplicación para incorporar mejoras, correcciones, cambios de seguridad o nuevas funcionalidades. Determinadas versiones podrán requerir actualización para continuar utilizando el servicio.',
    ),
    (
      title: 'Uso adecuado de la aplicación',
      content:
          'No está permitido manipular, alterar, intentar vulnerar o utilizar la aplicación para fines distintos a los autorizados por SafeRisk.',
    ),
    (
      title: 'Modificaciones',
      content:
          'SafeRisk podrá actualizar estos términos y condiciones cuando resulte necesario. Cuando existan modificaciones relevantes, podrán ser comunicadas dentro de la aplicación.',
    ),
  ];

  static final fingerprint = sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'id': id,
            'version': version,
            'title': title,
            'updatedLabel': updatedLabel,
            'sections': [
              for (final section in sections)
                {'title': section.title, 'content': section.content},
            ],
          }),
        ),
      )
      .toString();
}
