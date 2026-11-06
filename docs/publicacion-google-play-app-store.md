# Publicación de SafeRisk Inspecciones

Guía operativa · 4 de noviembre de 2026 · America/Guayaquil

Esta guía cubre la publicación inicial de la misma app en Google Play y App Store. No se ha firmado, compilado, subido ni publicado una versión al preparar este documento.

## 1. Antes de crear las fichas

- [ ] Definir quién será el titular de las cuentas. Para una app de empresa, conviene que las cuentas pertenezcan a la organizalisción y que el equipo tenga acceso mediante roles. Preparar D‑U‑N‑S y documentación de verificación si se registra como organización. [Tipos de cuenta de Google](https://support.google.com/googleplay/android-developer/answer/13634885) · [Inscripción de Apple](https://developer.apple.com/programs/enroll/).
- [ ] Decidir la distribución: pública si debe encontrarse en las tiendas; privada mediante Managed Google Play y Apple Business si se distribuirá a organizaciones administradas. En iOS, también se puede solicitar [distribución no listada](https://developer.apple.com/support/unlisted-app-distribution) para un público limitado. El enlace no restringe el acceso por sí solo: se conserva el login de inspector.
- [ ] Confirmar los identificadores antes de la primera carga: Android `ec.saferisk.saferisk_inspecciones`; iOS `ec.saferisk.saferiskInspecciones`. Si ya existe una ficha, verificar que coincidan con ella antes de compilar.
- [ ] Confirmar versión: el proyecto tiene `1.0.0+1`. Puede usarse si ese número de compilación aún no se ha subido. Incrementar el número después de cada carga que lo consuma.
- [ ] Preparar correo de soporte, URL de soporte, política pública de privacidad y cuenta de inspector para revisión. La política debe estar disponible desde la ficha y dentro de la app. No sustituirla por Términos y condiciones. [Contenido de la app en Google Play](https://support.google.com/googleplay/android-developer/answer/9859455) · [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).
- [ ] Usar una cuenta de revisión con casos de prueba y datos ficticios. Mantenerla activa durante la revisión. Proporcionar las credenciales únicamente en la sección privada de acceso para revisores, no en la descripción ni en GitHub. Explicar cómo seleccionar la aseguradora y cómo desbloquear con usuario y contraseña si el equipo no tiene biometría.
- [ ] Preparar las claves operativas de FlowConnect y Maps con la configuración local descrita en el README. En Android, comprobar Maps con la huella del **certificado de firma de Play**, además de la firma local que corresponda a las pruebas; en iOS, con el Bundle ID definitivo. Los valores incluidos en la app instalada son recuperables: no introducir secretos de servidor en el bundle.

### Pendientes específicos de este proyecto

| Punto | Qué revisar antes de publicar |
| --- | --- |
| Firma Android | `android/app/build.gradle.kts` todavía usa la firma `debug` en `release`. Configurar firma de subida antes de generar el AAB. |
| Nivel de API | `compileSdk = 37`; `targetSdk` se toma de Flutter. El SDK local revisado usa 36. Verificar el valor efectivo del AAB de publicación. |
| Aseguradora «Todas» | Desde el 5 de noviembre de 2026 Consulta incluye aseguradora por caso y la app la conserva al abrirlo. Validar con el nuevo build la apertura desde Todas, el envío de pasos y la persistencia. El AAB anterior no incorpora esta corrección. |
| Permisos | Revisar el manifest combinado de Android y `Info.plist` de iOS. Hay declaraciones de cámara y, en iOS, galería y ubicación permanente; retirar las que el build final no utilice. Verificar los textos de ubicación y Face ID. |
| Privacidad de SDK | Revisar los manifiestos de privacidad incluidos por los plugins iOS y si Runner necesita `PrivacyInfo.xcprivacy` propio según las APIs utilizadas. |
| Actualizaciones | `APP_UPDATES_ENABLED` está desactivado por defecto. Si se habilita para lanzamiento, comprobar el enlace real y que el build mínimo no bloquee una versión que todavía no esté disponible. |

## 2. Google Play, desde Windows

1. **Crear y verificar la cuenta** en [Play Console](https://play.google.com/console/). La cuota de registro es de **USD 25 por única vez**. Completar verificaciones de identidad, organización y dispositivo si la consola las solicita. [Registro oficial](https://support.google.com/googleplay/android-developer/answer/6112435).
2. **Crear la ficha**: aplicación, nombre comercial, idioma español, gratuita si esa es la modalidad aprobada, países y datos de contacto. Mantener la ficha en borrador mientras se completa el build.
3. **Crear la clave de subida** desde PowerShell con el `keytool` del JDK. Si ya existe una clave de subida registrada para esta app, reutilizarla. El comando de ejemplo pide la contraseña de forma interactiva:

   ```powershell
   keytool -genkeypair -v -keystore "$env:USERPROFILE\saferisk-upload.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias saferisk-upload
   ```

   Guardar copia segura del JKS, alias y contraseñas bajo control de la organización. No guardarlos en el repositorio. Crear `android/key.properties` con `storeFile`, `storePassword`, `keyAlias` y `keyPassword`; usar la ruta absoluta del JKS, con `/` en Windows. En `android/app/build.gradle.kts`, cargar esas propiedades, configurar `signingConfigs.release` y enlazarla a `buildTypes.release` en lugar de `debug`. El repositorio ya ignora `key.properties` y `*.jks`. [Configuración Kotlin DSL y firma en Flutter](https://docs.flutter.dev/deployment/android).

4. **Generar el AAB firmado** desde la raíz, con `config/local.json` y Maps preparados para el build de distribución:

   ```powershell
   flutter pub get
   flutter analyze
   flutter build appbundle --release
   ```

   Archivo esperado: `build/app/outputs/bundle/release/app-release.aab`. Desde el 31 de agosto de 2026, una app móvil nueva debe apuntar como mínimo a **Android 16 / API 36**. Validar también la compatibilidad de las bibliotecas nativas con páginas de memoria de **16 KB** en la consola y en un equipo o emulador compatible. [Nivel de API](https://support.google.com/googleplay/android-developer/answer/11926878) · [Verificación de 16 KB](https://developer.android.com/guide/practices/page-sizes).

5. **Subir primero a Pruebas internas** y configurar [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756). El JKS local firma la subida; Google firma lo que reciben los usuarios con la clave de firma de la app. Instalar desde el enlace de prueba, verificar Maps con esa firma y revisar el informe previo al lanzamiento. No basta validar solo `flutter run`.
6. **Completar la ficha**: ícono de 512 × 512 px, gráfico de funciones de 1024 × 500 px, capturas reales sin datos personales, descripción corta y larga, categoría y correo de soporte. Mostrar Inicio, Inspecciones, Actividad y el detalle del caso. [Recursos gráficos](https://support.google.com/googleplay/android-developer/answer/9866151).
7. **Completar Contenido de la app**: acceso para revisión, seguridad de datos, política de privacidad, clasificación, público objetivo, publicidad y declaraciones aplicables. Si la consola pregunta por funciones financieras, responder según lo que ofrece el producto: verificar con la empresa si la app solo gestiona inspecciones o si también comercializa productos de seguros. No seleccionar declaraciones por el nombre de la app. [Contenido de la app](https://support.google.com/googleplay/android-developer/answer/9859455) · [Seguridad de datos](https://support.google.com/googleplay/android-developer/answer/10787469).
8. **Solicitar acceso a producción si corresponde**. Para cuentas personales creadas después del 13 de noviembre de 2023, Google exige prueba **cerrada** con al menos **12 testers inscritos continuamente durante 14 días** antes de solicitar acceso a producción. La pista interna no reemplaza esa prueba. En cuenta de organización, seguir las tareas que indique la consola. [Requisito de prueba cerrada](https://support.google.com/googleplay/android-developer/answer/14151465).
9. **Enviar el lanzamiento a revisión**: crear la versión de producción con el AAB validado, notas de versión, países y ficha completos. Usar publicación gestionada si está disponible y se necesita elegir el momento de salida. Tras aprobación, publicar y comprobar la ficha e instalación desde una cuenta sin permisos de desarrollador.

## 3. App Store, desde macOS

1. **Inscribir la organización** en [Apple Developer Program](https://developer.apple.com/programs/). La membresía estándar cuesta **USD 99 por año**, o su equivalente local. Obtener un Mac propio o de compilación autorizado. Desde el 28 de abril de 2026, los envíos deben compilarse con **Xcode 26 o posterior y SDK de iOS 26 o posterior**, según los requisitos vigentes de Apple. Eso no convierte automáticamente iOS 26 en la versión mínima de instalación; revisar el destino mínimo de Runner y sus dependencias. [Requisitos de envío](https://developer.apple.com/news/upcoming-requirements/).
2. **Registrar el App ID** `ec.saferisk.saferiskInspecciones` en la cuenta de Apple y crear la ficha en [App Store Connect](https://appstoreconnect.apple.com/). Elegir iOS, nombre, idioma, Bundle ID y un SKU interno estable. Confirmar disponibilidad pública o privada antes de la revisión.
3. **Configurar firma** en Xcode, destino Runner → Signing & Capabilities: equipo de la organización, Bundle ID correcto y firma automática si se usa ese modo. Abrir el workspace del proyecto si está disponible, o el proyecto Runner según la configuración de dependencias de Flutter. Preparar `ios/Flutter/Local.xcconfig` desde su plantilla con la clave de Maps de iOS y configurar FlowConnect en el Mac.
4. **Generar archivo e IPA** desde la raíz del proyecto:

   ```bash
   flutter pub get
   flutter analyze
   flutter build ipa --release
   ```

   Salidas esperadas: `build/ios/archive/` y `build/ios/ipa/`. Validar el archivo desde Xcode Organizer y subirlo a App Store Connect, o subir la IPA con Transporter. [Publicación iOS con Flutter](https://docs.flutter.dev/deployment/ios).

5. **Probar por TestFlight**. Seleccionar el build procesado, contestar el cuestionario de cifrado según el uso real de la app y habilitar testers internos. Si se incluyen externos, seguir el flujo de revisión beta cuando corresponda. Validar Face ID/Touch ID, bloqueo del teléfono, ubicación y finalización en iPhone real. Si Runner admite iPad, probarlo también. [TestFlight](https://developer.apple.com/testflight/).
6. **Completar la ficha y revisión**: descripción, palabras clave, capturas de los tamaños solicitados para los dispositivos compatibles, URL de soporte, política de privacidad, clasificación por edades, contacto y cuenta de revisión. Revisar `PrivacyInfo.xcprivacy` y los SDK incluidos mediante el informe de privacidad de Xcode. Completar App Privacy según los datos propios y los SDK. [Privacidad de la ficha](https://developer.apple.com/app-store/app-privacy-details/) · [Manifiestos de privacidad](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files).
7. **Enviar a App Review**. Elegir el build probado, adjuntar instrucciones de revisión, completar disponibilidad y elegir lanzamiento manual si quieres decidir el momento de publicación. Tras la aprobación, liberar la versión y comprobar la instalación desde App Store.

## 4. Datos y prueba de aceptación

Antes de completar los formularios, confirmar con el responsable del backend qué recibe, guarda, comparte y durante cuánto tiempo. La app gestiona identidad de inspector y datos de casos, y envía ubicación para los pasos que la requieren. Revisar el uso efectivo de Maps y sus SDK. La biometría local y el código del dispositivo se verifican en el sistema operativo; la app no recibe huellas ni el PIN. No declarar «sin datos» basándose solo en que no hay un formulario de registro.

Si existe creación de cuentas dentro de la app o mediante un flujo vinculado, revisar los requisitos de eliminación aplicables. Si las cuentas son aprovisionadas por la empresa, describir el modelo real y el canal de soporte; cerrar sesión no elimina una cuenta. [Eliminación en Google Play](https://support.google.com/googleplay/android-developer/answer/13327111) · [Eliminación en App Store](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/).

- [ ] Instalar el build distribuido por Play interno o TestFlight.
- [ ] Entrar con un inspector de prueba y validar búsqueda, filtro por aseguradora y datos del caso.
- [ ] Probar ubicación autorizada/denegada, mapa y los cuatro pasos hasta finalizar; comprobar que se vuelve al listado.
- [ ] Cerrar y volver a abrir la app a mitad del flujo; validar persistencia y la opción Continuar desde Actividad.
- [ ] Probar biometría, código del teléfono y revalidación con contraseña; cancelar y volver del segundo plano sin revelar contenido antes del desbloqueo.
- [ ] Probar sin conexión, expiración de sesión, cierre de sesión y acceso con otra cuenta.
- [ ] Revisar enlaces, textos, capturas y notas de revisión. Confirmar que el caso de prueba se pueda recorrer sin afectar datos reales.
- [ ] Confirmar versión, firma, privacidad, países y aprobación interna antes de pulsar **Enviar a revisión**.

Orden recomendado: **firma Android → AAB en pruebas internas → validación del flujo → revisión de Google Play**. En paralelo, preparar cuenta Apple y Mac para **firma iOS → TestFlight → App Review**.
