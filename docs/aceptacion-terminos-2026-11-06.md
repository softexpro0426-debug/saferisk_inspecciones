# Aceptación de términos por usuario y versión

Implementación del 6 de noviembre de 2026.

## Flujo

1. El usuario se autentica con sus credenciales o desbloquea una sesión guardada con uno de los métodos existentes.
2. Antes de habilitar funciones operativas se verifica la aceptación del documento vigente para ese usuario.
3. Si falta, se muestra el texto completo, versión y fecha, junto con una casilla sin marcar y Aceptar y continuar. La casilla debe marcarse para habilitar la acción.
4. Se habilita el acceso solo después de guardar y verificar el registro local. Un error de lectura o escritura no concede acceso automáticamente.
5. No aceptar y salir cierra la sesión sin registrar aceptación ni borrar el avance de las inspecciones.
6. En las siguientes aperturas se conserva el desbloqueo de seguridad habitual; los términos no se repiten si coinciden usuario, documento, versión y contenido aceptados.

## Registro local

FlutterSecureStorage guarda por usuario y versión: usuario, identificador de documento, versión, SHA-256 del contenido, aceptación afirmativa y fecha/hora UTC informada por el dispositivo. El contenido se toma de TermsDocument y se comparte entre la pantalla obligatoria y la consulta de Perfil.

La huella incluye identificador, versión, título, fecha de revisión y secciones. Si se modifica el texto sin cambiar la versión, la nueva huella también exige otra aceptación. Aun así, al publicar cambios legales se debe actualizar expresamente la versión y la fecha del documento.

No hay endpoint nuevo ni envío de aceptación al backend. No se recogen IP, ubicación ni datos biométricos para este registro. No es una certificación de tiempo ni una prueba centralizada o sincronizada entre dispositivos. Si se elimina el registro o se utiliza otra instalación, puede requerirse aceptar de nuevo.

## Texto vigente y propuesta jurídica

La integración utiliza el texto de condiciones que la app ya mostraba en Perfil, centralizado en lib/src/core/legal/terms_document.dart, con versión 1.0 y fecha agosto de 2026. No se publicó automáticamente el borrador jurídico del Word ni sus campos pendientes. Los párrafos existentes deberán ser sustituidos por la versión aprobada y se deberá incrementar la versión antes del lanzamiento correspondiente.

La copia del Word con comentarios contiene ahora redacciones completas para las cláusulas revisadas. Los corchetes identifican datos que la empresa debe completar: identidad, contactos, roles, bases jurídicas, destinatarios, proveedores, conservación y enlaces. La aceptación implementada se refiere únicamente a las condiciones de uso; no afirma que exista una Política de Privacidad aprobada ni un consentimiento general para tratar datos de terceros.

## Integración con seguridad y continuidad

SessionAccess añade termsRequired. isUnlocked solo es verdadero cuando se han satisfecho la autenticación y la aceptación. El SessionGate cubre la navegación mientras falta alguno de esos requisitos, y los clientes HTTP existentes continúan rechazando solicitudes operativas sin acceso habilitado.

Cambiar de sesión o pasar a segundo plano durante una operación pendiente de verificación no concede acceso por un resultado atrasado. La aceptación que haya sido guardada sigue asociada a su usuario y documento. Volver del segundo plano conserva el bloqueo de seguridad y vuelve a comprobar el registro tras autenticarse.

No se modifican los contratos de API ni las claves o el contenido de las instantáneas de inspección. Los registros de aceptación no se borran al cerrar sesión.

## Validación

Se realizaron formateo y análisis estático; las pruebas funcionales se reservan al usuario. Comprobar en dispositivo:

- Primer login y sesión guardada de un usuario sin aceptación.
- Botón deshabilitado sin marcar la casilla y acceso tras guardar correctamente.
- Salida sin aceptar y ausencia de acceso a casos mediante navegación hacia atrás.
- Segundo ingreso del mismo usuario sin repetir el documento aceptado.
- Otro usuario sin heredar la aceptación de la cuenta anterior.
- Cambio de versión o contenido y nueva solicitud de aceptación.
- Fallos de almacenamiento, cancelación y retorno del segundo plano.
- Continuidad de una inspección y finalización confirmada después de desbloquear.

El siguiente paso de backend, cuando se defina, deberá acordar un contrato para registrar y consultar aceptación, control de versiones y evidencia centralizada. No se inventó ese contrato en esta implementación.
