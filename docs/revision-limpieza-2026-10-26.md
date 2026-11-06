# Revisión de redundancias — 26 de octubre de 2026

Revisión estática del código y de sus referencias. No se ejecutaron la aplicación, pruebas funcionales ni solicitudes a las APIs. La revisión original es del 26 de octubre; la limpieza listada se aplicó el 27 de octubre de 2026 con autorización del usuario. Las tablas conservan la evidencia anterior a la limpieza.

## Limpieza aplicada el 27 de octubre de 2026

- Retirados DashboardStatCard, las tres pantallas del flujo anterior, sus tres controladores y InspectionWorkflowStorage. No se borraron datos del dispositivo ni se cambió la clave o el formato de la instantánea operativa cifrada.
- Retirado el selector REMOTE_WORKFLOW_ENABLED. Inspecciones y actividad usan únicamente el flujo operativo actual, con mapa y salida automática tras una finalización confirmada.
- Retirado el diagnóstico temporal detallado de Consulta. El transporte y los errores conservan su tratamiento.
- Actividad delega en InspectionsRemoteDataSource.search y transforma propiedades tipadas directamente a ActivityCase. Se retiraron el POST duplicado y los lectores repetidos de números, texto y fechas.
- El detalle reutiliza la primera respuesta C cuando la aseguradora coincide con la resuelta. Si primero se consultó sin aseguradora, se conserva la consulta específica. Se mantienen errores por identidades ambiguas y las protecciones del avance.
- Para hoy, Esta semana y Asignadas mantienen sus cifras y dejan de navegar a listados sin el filtro anunciado. Pendientes y Finalizadas conservan sus accesos C/P.
- El progreso visual utiliza OperationalStatus directamente, sin un segundo enum ni un modo de cuatro pasos.
- Corregida la ruta de generación del splash a assets/splash/saferisk_logo.png; retirada la declaración vacía assets/images/.
- Retirada intl como dependencia directa porque no quedan importaciones tras eliminar el flujo anterior. Google Maps, shared_preferences, connectivity_plus y la integración de versiones se conservan porque siguen teniendo uso.

## Finalización corregida

El flujo operativo esperaba una consulta de detalle posterior a ConcluirServicio y permanecía en la misma pantalla. Si esa consulta fallaba o actividad todavía mostraba el paso anterior, presentaba una finalización confirmada como un problema pendiente de actualización.

Ahora la respuesta exitosa de ConcluirServicio guarda el cierre local, actualiza las listas y devuelve un resultado terminal al detalle. La pantalla libera el bloqueo de navegación y regresa a la pantalla desde donde se abrió, con una confirmación breve. No necesita una nueva consulta de detalle para reconocer el cierre. Las respuestas negativas y los errores anteriores a la confirmación no provocan navegación de éxito.

## Elementos retirables o simplificables

| Elemento | Evidencia y propuesta | Condición para conservar el funcionamiento |
| --- | --- | --- |
| DashboardStatCard sin uso | `lib/src/features/dashboard/presentation/widgets/dashboard_stat_card.dart`: no tiene importaciones ni instancias en lib. El dashboard construye otras tarjetas. | Se puede eliminar este archivo sin sustituir una función visible. |
| Diagnóstico temporal de Consulta | `inspections_remote_data_source.dart` imprime estructura, tipos de campos e identidad en cada respuesta debug. Fue añadido durante el diagnóstico del contrato. | Retirar el detalle repetitivo o agruparlo en una sola línea debug; conservar el manejo de errores y la lectura del contrato. No afecta al funcionamiento de producción. |
| Conversión DTO → JSON → entidad de actividad | `activity_remote_data_source.dart` convierte InspectionCaseDto a JSON y vuelve a leer números, textos y fechas en _mapCase. | Mapear directamente las propiedades tipadas a ActivityCase y retirar _readInt, _readString y _readDate cuando no queden referencias. Conservar todos los campos usados por actividad. |
| Construcción HTTP duplicada de Consulta | Actividad e Inspecciones publican en la misma ruta y usan los mismos DTO de solicitud y respuesta, pero mantienen dos implementaciones de la llamada. | Delegar el resumen en InspectionsRemoteDataSource.search y mantener su filtro C/P. No cambiar contratos ni el resultado de actividad. |
| Consulta C repetida al abrir algunos casos | `operational_inspection_repository.dart` consulta C antes de resolver actividad; si no obtiene un detalle reutilizable, el bucle C/P puede repetir C con la misma aseguradora y caso. | Reutilizar el resultado ya recibido solo cuando usuario, aseguradora, número y tipo coincidan. Mantener la consulta con aseguradora resuelta cuando la primera búsqueda usó 0. |

## Redundancias que requieren retirar una alternativa completa

| Elemento | Situación actual | Condición |
| --- | --- | --- |
| Segundo flujo de inspección | InspectionDetailPage → ArrivalMapPage → InspectionReviewPage sigue disponible con REMOTE_WORKFLOW_ENABLED=false. Duplica parte del flujo operativo nuevo. | No son pantallas huérfanas mientras exista esa opción. Se puede retirar el conjunto si se adopta únicamente el flujo nuevo. No retirar llegada/conclusión de la capa de datos: el flujo nuevo las usa. |
| Persistencia y controladores del flujo anterior | InspectionWorkflowStorage y los controladores en_route, confirm_arrival e inspection_form mantienen estados paralelos a la instantánea cifrada y al controlador operativo. | Retirarlos junto con sus pantallas y el selector del flujo anterior, tras decidir que no se requiere ese modo. No borrar credenciales ni la instantánea operativa. |
| Accesos del dashboard con el mismo filtro | pending, pendingToday y assigned aplican C; completed y completedWeek aplican P. No hay un filtro de fecha ni de asignación adicional en InspectionFilter. | Los indicadores pueden seguir siendo útiles. Para evitar prometer listados distintos, retirar o unificar los accesos redundantes conservando las cifras. No inventar filtros de backend. |

## Elementos que conviene conservar

- La integración de versiones está desactivada durante pruebas por decisión del usuario; no se considera código muerto.
- La compatibilidad de campos antiguos en el DTO también permite leer instantáneas locales existentes. Retirarla sin migración puede afectar la persistencia.
- connectivity_plus se usa en Perfil; no es una dependencia huérfana.
- Las protecciones contra doble toque y contra retroceso de un avance confirmado siguen siendo necesarias.

## Observación adicional de configuración

pubspec.yaml referencia `assets/splash/splash_logo.png`, que no existe en el directorio local revisado. El archivo presente es `assets/splash/saferisk_logo.png`. Esto requiere corregir o restaurar la ruta al preparar recursos; no debe confundirse con una imagen prescindible ni solucionarse borrando los recursos nativos generados. `assets/images/` existe, pero su subcarpeta empty_states no aporta archivos al inventario; puede retirarse su declaración si permanece vacía.

## Mapa en el flujo operativo

La pantalla de inspección incorpora una tarjeta de ubicación con mapa, marcador del inspector, actualización y centrado. Reutiliza Google Maps y LocationService existentes. La lectura de posición se comparte con el paso que envía coordenadas y las capturas simultáneas se agrupan en una sola solicitud. Cada paso que requiere coordenadas vuelve a solicitar una posición actual; el mapa no sustituye esa validación ni permite seleccionar coordenadas arbitrarias. Finalizar sigue sin pedir una ubicación adicional.
