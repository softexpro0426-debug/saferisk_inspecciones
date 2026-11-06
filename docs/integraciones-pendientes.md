# Actividad, continuación y actualizaciones

Actualización: 27 de octubre de 2026.

## Contratos recibidos

La app usa FlowConnect para api/movil/version, api/movil/dashboard, api/movil/actividad-reciente y api/movil/seguimiento. Consulta usa nuevamente https://sistema.saferisk.ec/flowconnect/api/movil/consulta desde el 6 de octubre de 2026 con el contrato corregido. No se usa un fallback automático entre servidores. Conservan sus contratos salvo actividad reciente, que devuelve aseguradora, caso, titulo, estadoActual, estadoSeguimiento y fecha. Llegada, inicio y finalización conservan sus endpoints de SW_APP.

Se conserva el historial completo recibido: un mismo caso puede aparecer varias veces. La identidad es el par aseguradora/caso; no se identifica una fila solo por el número de caso.

La API de versiones es GET https://sistema.saferisk.ec/flowconnect/api/movil/version?plataforma=android, con X-Api-Key de la configuración local.

La respuesta es una lista de objetos con los nombres exactos:

    [
      {
        "plataforma": "android",
        "ultima_Version": "1.2.0",
        "ultimo_Build": 12,
        "build_Minimo_Permitido": 10,
        "url_Actualizacion": "https://play.google.com/store/apps/details?id=ec.saferisk.saferisk_inspecciones",
        "notas": "Mejoras de estabilidad y seguimiento de inspecciones."
      }
    ]

Se requiere una sola política válida para la plataforma solicitada. Una lista vacía, duplicados para la misma plataforma o campos inválidos se tratan como fallo de consulta y no eliminan una restricción válida previamente guardada.

## Actualizaciones desactivadas durante las pruebas

APP_UPDATES_ENABLED es false por defecto durante las pruebas. Con flutter run no se consulta la API de versiones ni se aplica la política guardada; la versión y el build del proyecto se mantienen. Las reglas siguientes se aplican al reactivar la integración.

- Se compara el build instalado, no la cadena de versión.
- Menor al mínimo: actualización obligatoria.
- Entre el mínimo y el último build: actualización opcional.
- Igual o superior al último: continuar normalmente.
- Se conserva la última política válida por aplicación y plataforma para fallos de conexión.
- Sin política válida conocida, un fallo permite continuar.
- El enlace se abre externamente. No hay descarga ni instalación silenciosa.
- Si falla abrir la tienda, una actualización obligatoria conserva el bloqueo.
- Al regresar de la tienda se vuelve a comprobar.

El proyecto sigue en 1.0.0+1. Con la política de ejemplo (mínimo 10), ese build queda bloqueado. Publicar una versión descargable antes de establecer un mínimo obligatorio.

Para reactivar la comprobación cuando termine la etapa de pruebas:

    flutter run --dart-define=APP_UPDATES_ENABLED=true

La URL base y ruta son configurables mediante APP_VERSION_BASE_URL y APP_VERSION_PATH. Los nombres de campos se centralizan en pending_api_config.dart. La caché usa una versión nueva para no mezclar el contrato anterior con el recibido.

## Continuación activa

El flujo operativo es la única implementación de inspecciones. El usuario confirmó que actividad devuelve los últimos movimientos por caso y que el flujo del inspector termina solo con INSPECCIÓN FINALIZADA. El selector REMOTE_WORKFLOW_ENABLED y el flujo anterior se retiraron el 27 de octubre de 2026.

La identidad es aseguradora + caso. La app consulta otra vez actividad y el detalle antes de cada acción. No toma el estado de la fila tocada como estado actual.

Estados operativos y acciones:

| Movimiento confirmado | Siguiente acción |
| --- | --- |
| ASIGNADO | En camino |
| INSPECTOR EN CAMINO | Confirmar llegada |
| INSPECTOR EN SITIO DE INSPECCIÓN | Iniciar inspección |
| INSPECCIÓN INICIADA | Finalizar inspección |
| INSPECCIÓN FINALIZADA | Solo consulta |

Se prioriza estadoActual del registro más reciente del caso cuando corresponde a un paso operativo. estadoSeguimiento describe el movimiento histórico mostrado en cada fila. Si el estado actual es de negocio, se conserva el mayor avance operativo del historial recibido: ASEGURABLE, COORDINADO y FALLIDO no se convierten en pasos del inspector. La caché impide retroceder respecto de un paso confirmado en el dispositivo. No se implementa reapertura de una inspección finalizada.

Ejemplos con la respuesta suministrada:

- 32819 / aseguradora 3: finalizada, aunque se toque la fila antigua de inicio.
- 16828 / aseguradora 6: tiene llegada confirmada; ASEGURABLE no equivale a finalizar el flujo del inspector.
- 51265 y 51293 / aseguradora 2: asignadas, sin salida visible en el historial.

Consulta conserva sus campos de caso; la respuesta recibida en la app usa casos en minúscula y el ejemplo de Postman usa Casos. El lector compartido acepta ambas variantes y rechaza respuestas sin una lista válida. Los registros móviles recibidos usan nroCaso, fechaInicio, fechaFin, celularAsegurado, personaContacto, telefonoContacto, colorCasosBroker y colorCasosInspector; también se aceptan sus equivalentes originales en snake_case. Los valores null se conservan como información ausente y no se inventan datos. Se reutilizan la fuente de datos y el lector de respuestas de Inspecciones, enviando el usuario, la aseguradora obtenida de actividad y el número de caso. Se busca primero en C y, únicamente si no hay coincidencia, en P. La categoría de consulta no determina el avance operativo: este se obtiene de actividad. No se solicita tipo vacío ni se esperan campos nuevos en su respuesta. Los errores de red o de formato se propagan sin intentar otra categoría.

La instantánea cifrada combina el detalle y el progreso obtenido de actividad. estado_operativo es un campo interno de caché, no un requisito del backend. La caché está separada por usuario, aseguradora y caso; un historial que retroceda respecto de un avance guardado bloquea nuevas acciones.

### Límites del historial

Si el caso no figura en actividad, o ni estadoActual ni los movimientos recibidos permiten identificar un paso operativo, la app bloquea su continuación. Si estadoActual es de negocio y el servidor omite una finalización antigua, un dispositivo sin caché no puede demostrar ese cierre. El backend debe conservar el último avance operativo por caso y validar que no se vuelva a mutar un caso finalizado.

No hay reintentos automáticos de mutaciones. Una respuesta perdida requiere reconciliación. La prevención en el cliente no sustituye la idempotencia ni las validaciones del servidor.

Se debe detener y volver a ejecutar para aplicar cambios de controles o recursos. La integración de versiones permanece desactivada durante pruebas; no se retiró.
## Archivos principales

- lib/src/core/config/pending_api_config.dart: controles, ruta y campos de versión.
- lib/src/core/app_update/: análisis de política, consulta, caché y aviso.
- lib/src/features/activity/data/datasource/recent_activity_remote_data_source.dart: contrato nuevo.
- lib/src/features/inspections/domain/entities/activity_workflow_resolver.dart: selección temporal y etiquetas permitidas.
- lib/src/features/inspections/data/repositories/operational_inspection_repository.dart: actividad + Consulta y caché.
- lib/src/features/inspections/presentation/controllers/operational_workflow_controller.dart: transiciones.
- lib/src/features/inspections/data/datasources/start_inspection_remote_data_source.dart: inicio con contrato confirmado.

La validación realizada es estática. Las pruebas funcionales, de dispositivo y con las APIs quedan a cargo del usuario.

## Acceso desde actividad reciente

Solo estadoActual INSPECTOR EN CAMINO, INSPECTOR EN SITIO DE INSPECCIÓN o INSPECCIÓN INICIADA habilita continuar desde actividad reciente. estadoSeguimiento se muestra como historial y no habilita acceso por sí solo. Los demás estados, incluida INSPECCIÓN FINALIZADA, no permiten abrir el caso desde ese panel, tampoco para consulta.

## Apertura de asignados

El detalle consulta primero FlowConnect api/movil/consulta (C). Si el caso está ASIGNADO, abre el paso En camino sin consultar actividad. Desde el 5 de noviembre de 2026 la respuesta incluye aseguradora y se usa la del caso, también cuando el filtro de búsqueda es Todas (0). Si un registro antiguo no incluye el campo, se conserva el filtro concreto como respaldo. Si el caso tiene otro estado, se conserva la reconciliación con actividad reciente. Un avance guardado o confirmado impide reiniciar un caso como asignado.

## Contrato de Consulta vigente: 6 de octubre de 2026

POST api/movil/consulta envía Aseguradora (entero), Usuario, Tipo_Consulta, Cedula, Placa, Nombre y Nro_Caso (texto, incluido 0). Este contrato sustituye el cuerpo anterior en minúsculas. El resumen usa el mismo DTO que búsqueda y detalle.

La lista Casos contiene nro_caso, asegurado, placa, descripcion_estado, fecha_ini, fecha_fin, cedula, celular_asegurado, persona_contacto, telefono_contacto, marca, modelo, observaciones_casos, color_broker y color_inspector. El lector los convierte al modelo interno; las variantes anteriores se conservan para leer instantáneas locales existentes. nombre no figura en el ejemplo nuevo y no se inventa. El avance operativo y los contratos de mutación se conservan.

## Cierre y mapa: 26 de octubre de 2026

ConcluirServicio confirmado guarda el cierre y devuelve a la pantalla de origen, sin depender de otra lectura de actividad o detalle. Las listas se invalidan para su actualización. No se navega como éxito ante una respuesta negativa o un error anterior a la confirmación.

El flujo operativo muestra el mapa con la ubicación del inspector. currentPositionProvider comparte la posición entre mapa y envío del paso; cada paso con coordenadas solicita una captura actual. LocationService agrupa lecturas simultáneas. La revisión de redundancias está en revision-limpieza-2026-10-26.md. No se ejecutaron pruebas funcionales.

## Actividad clara: 27 de octubre de 2026

Actividad separa En curso de Últimos movimientos. En curso agrupa por aseguradora/caso, toma estadoActual del registro con fecha más reciente y permite abrir únicamente en camino, en sitio o inspección iniciada. Muestra un solo estado con texto breve y la próxima acción. Tocar la tarjeta abre el detalle para revisión y confirmación; nunca muta el caso directamente.

El historial conserva todos los eventos ordenados por fecha descendente, muestra estadoSeguimiento como un hecho y fecha/hora. No muestra estadoActual en la misma fila, no repite botones y no navega al caso. Los estados de negocio mantienen su significado.

Se retiraron el resumen C/P de Actividad, sus modelos, controlador y fuente de datos exclusivos. Inicio conserva sus indicadores e Inspecciones su búsqueda. No se cambiaron los contratos de API, el flujo de estados ni la persistencia.

## Aseguradora por caso: 5 de noviembre de 2026

Consulta devuelve aseguradora como entero positivo en cada registro. InspectionCaseDto e InspectionCase conservan ese dato. Al abrir desde Inspecciones se usa primero la aseguradora del caso, no el filtro Todas=0. Los pasos de seguimiento, llegada, inicio y finalización siguen recibiendo el identificador resuelto del detalle operativo. Se rechazan identidades inconsistentes antes de guardar el detalle.

Las instantáneas mantienen el formato y las claves existentes. Para recuperar datos antiguos abiertos desde Todas, se permite leer la antigua clave con aseguradora 0 únicamente si el usuario, número de caso y aseguradora interna coinciden. No se cambió la API de mutaciones ni se ejecutaron pruebas funcionales.
