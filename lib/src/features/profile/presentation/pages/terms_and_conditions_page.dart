import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

final class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Términos y condiciones')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed(const [
                  _TermsHeader(),

                  SizedBox(height: 18),

                  _TermsSection(
                    number: '1',
                    title: 'Objeto',
                    content:
                        'SafeRisk Inspecciones es una herramienta de trabajo '
                        'destinada a apoyar la gestión operativa de los procesos '
                        'de inspección asignados a los usuarios autorizados.',
                  ),

                  SizedBox(height: 14),

                  _TermsSection(
                    number: '2',
                    title: 'Uso autorizado',
                    content:
                        'El acceso y uso de la aplicación está destinado '
                        'exclusivamente a usuarios autorizados por SafeRisk. '
                        'El usuario se compromete a utilizar la aplicación '
                        'únicamente para actividades relacionadas con sus '
                        'funciones y responsabilidades asignadas.',
                  ),

                  SizedBox(height: 14),

                  _TermsSection(
                    number: '3',
                    title: 'Responsabilidad del usuario',
                    content:
                        'El usuario es responsable de la información registrada '
                        'durante el proceso de inspección y deberá procurar que '
                        'los datos ingresados sean correctos, completos y '
                        'correspondan al caso gestionado.',
                  ),

                  SizedBox(height: 14),

                  _TermsSection(
                    number: '4',
                    title: 'Credenciales y seguridad',
                    content:
                        'Las credenciales de acceso son personales. El usuario '
                        'deberá mantenerlas bajo su responsabilidad y evitar '
                        'compartirlas con terceros. SafeRisk podrá restringir '
                        'el acceso cuando detecte un uso no autorizado o '
                        'contrario a las políticas establecidas.',
                  ),

                  SizedBox(height: 14),

                  _TermsSection(
                    number: '5',
                    title: 'Ubicación y datos operativos',
                    content:
                        'Durante determinados procesos la aplicación podrá '
                        'solicitar acceso a la ubicación del dispositivo para '
                        'registrar información relacionada con la ejecución '
                        'de una inspección. El uso de esta información estará '
                        'vinculado a las funciones operativas de SafeRisk.',
                  ),

                  SizedBox(height: 14),

                  _TermsSection(
                    number: '6',
                    title: 'Fotografías y documentos',
                    content:
                        'Las fotografías, documentos e información recopilados '
                        'durante una inspección podrán ser procesados y '
                        'almacenados con el propósito de gestionar y respaldar '
                        'el servicio correspondiente.',
                  ),

                  SizedBox(height: 14),

                  _TermsSection(
                    number: '7',
                    title: 'Disponibilidad del servicio',
                    content:
                        'SafeRisk realizará esfuerzos razonables para mantener '
                        'la aplicación disponible y operativa. Sin embargo, '
                        'podrán existir interrupciones temporales relacionadas '
                        'con mantenimiento, conectividad, infraestructura o '
                        'actualizaciones del sistema.',
                  ),

                  SizedBox(height: 14),

                  _TermsSection(
                    number: '8',
                    title: 'Actualizaciones',
                    content:
                        'SafeRisk podrá publicar nuevas versiones de la '
                        'aplicación para incorporar mejoras, correcciones, '
                        'cambios de seguridad o nuevas funcionalidades. '
                        'Determinadas versiones podrán requerir actualización '
                        'para continuar utilizando el servicio.',
                  ),

                  SizedBox(height: 14),

                  _TermsSection(
                    number: '9',
                    title: 'Uso adecuado de la aplicación',
                    content:
                        'No está permitido manipular, alterar, intentar '
                        'vulnerar o utilizar la aplicación para fines distintos '
                        'a los autorizados por SafeRisk.',
                  ),

                  SizedBox(height: 14),

                  _TermsSection(
                    number: '10',
                    title: 'Modificaciones',
                    content:
                        'SafeRisk podrá actualizar estos términos y condiciones '
                        'cuando resulte necesario. Cuando existan modificaciones '
                        'relevantes, podrán ser comunicadas dentro de la '
                        'aplicación.',
                  ),

                  SizedBox(height: 20),

                  _TermsFooter(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TermsHeader extends StatelessWidget {
  const _TermsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_rounded, color: Colors.white, size: 30),
          const SizedBox(height: 14),
          const Text(
            'Términos y condiciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'SafeRisk · TÉCNICAMENTE SEGUROS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Versión 1.0',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.number,
    required this.title,
    required this.content,
  });

  final String number;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.neutralDark,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

final class _TermsFooter extends StatelessWidget {
  const _TermsFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 21),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Última actualización: agosto de 2026.\n\n'
              'Este apartado podrá actualizarse conforme evolucionen '
              'las políticas y funcionalidades de SafeRisk.',
              style: TextStyle(
                color: AppColors.neutralDark,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
