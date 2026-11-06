# Protección de sesión — 30 de octubre de 2026

## Política aplicada

- Una sesión guardada requiere verificación local al abrir la app.
- Una sesión abierta se bloquea cuando la app pasa a segundo plano; al volver requiere verificación.
- Mientras la app está inactiva se cubre el contenido. Una interrupción transitoria, como un permiso del sistema, no se considera por sí sola una salida a segundo plano.
- El primer acceso continúa validando usuario y contraseña con api/Ingreso.

## Tres formas de desbloqueo

1. **Biometría:** autenticación nativa con biometricOnly=true, sin aceptar un código como resultado de ese botón. Requiere biometría configurada en el dispositivo.
2. **Bloqueo del teléfono:** autenticación nativa que admite el PIN, patrón o contraseña del dispositivo. El sistema operativo decide qué opciones presenta; puede mostrar primero biometría y ofrecer el código como alternativa. Este botón no fuerza un teclado numérico y no es un código SMS ni un PIN propio de SafeRisk.
3. **Usuario y contraseña:** verifica nuevamente con la API existente la cuenta que tiene abierta la sesión. El usuario es fijo; la contraseña se vacía al terminar el intento y no se guarda. Una cuenta distinta no sustituye silenciosamente la sesión bloqueada.

La app no captura huellas, imágenes faciales ni el código de bloqueo del dispositivo. Estos mecanismos usan local_auth y la interfaz nativa del sistema. Una cancelación o un fallo mantiene el bloqueo y permite elegir otro método.

## Integración

- SessionGate cubre el router completo, incluidos detalles y diálogos abiertos. Conserva las pantallas montadas y excluye el contenido protegido de visualización, foco y semántica mientras está bloqueado.
- El permiso de acceso solo existe en memoria; no se guarda un indicador persistente de sesión desbloqueada.
- SessionStorage restaura una sesión como bloqueada. readSession exige desbloqueo; el acceso privilegiado de restauración solo se usa durante el arranque.
- Los clientes HTTP principal y FlowConnect impiden nuevas solicitudes de negocio mientras la sesión está bloqueada. api/Ingreso permanece disponible para la revalidación con contraseña. La consulta de versión utiliza su cliente independiente de arranque.
- No se cancelan ni repiten automáticamente mutaciones ya enviadas antes del bloqueo. Si una finalización confirmada termina durante una interrupción, su salida de la pantalla se difiere hasta desbloquear.
- No se borran ni cambian las claves o el formato de las instantáneas de inspección. El progreso persistente se conserva.
- Al cerrar sesión o cambiar de cuenta se invalidan los datos en memoria de casos, actividad, indicadores, aseguradoras y perfil. Los resultados de verificación anteriores no otorgan acceso a otra generación de sesión.
- Perfil delega la salida y limpieza de datos al control global de sesión.
- Se mantiene la lógica actual de expiración ante 401 y los contratos de API existentes.

## Android e iOS

- local_auth 3.0.2, local_auth_android 2.0.8 y local_auth_darwin 2.0.5 quedaron resueltos en pubspec.lock para el SDK actual. intl vuelve como dependencia transitiva del plugin; no es una dependencia directa de la app.
- Android utiliza FlutterFragmentActivity, USE_BIOMETRIC y temas AppCompat en las variantes de recursos existentes.
- iOS declara NSFaceIDUsageDescription; el proyecto tiene destino mínimo iOS 13.
- Al ser una incorporación de plugins y configuración nativa, detener la ejecución y volver a compilar/instalar. Hot reload no incorpora esos cambios.

Documentación primaria consultada: [local_auth](https://pub.dev/packages/local_auth), [Android](https://pub.dev/packages/local_auth_android) e [iOS](https://pub.dev/packages/local_auth_darwin).

## Validación pendiente en dispositivo a cargo del usuario

La revisión realizada es estática. No se ejecutaron la app, pruebas funcionales ni llamadas a las APIs.

- Primer login válido e inválido; sesión guardada al cerrar y volver a abrir.
- Huella/Face ID: éxito, cancelación, falta de configuración y bloqueo por intentos fallidos.
- Bloqueo del teléfono: PIN/patrón/contraseña y cancelación según las opciones nativas del dispositivo.
- Contraseña de la sesión: correcta, incorrecta y sin conexión; comprobar que no se puede editar el usuario para cambiar de cuenta.
- Salir a otra app y volver desde Inicio, Actividad, Perfil y un detalle de inspección; comprobar que el contenido permanece cubierto hasta verificar la identidad.
- Interrupciones durante un diálogo biométrico, un permiso de ubicación y una operación de inspección. No debe haber prompts superpuestos ni repetición de envíos.
- Finalización confirmada durante segundo plano: desbloquear y comprobar el regreso al listado con el caso cerrado.
- Cerrar sesión y entrar con otra cuenta; no deben quedar datos visibles de la anterior.
- Repetir las comprobaciones en Android y en iOS con biometría real.
